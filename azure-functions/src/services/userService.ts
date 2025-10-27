import { getConnection, sql } from '../config/database';
import { User, CreateUserRequest, JwtPayload, TokenPair } from '../types';
import { hashPassword, verifyPassword } from '../utils/password';
import { generateTokens } from '../utils/jwt';
import { config } from '../config/env';

export class UserService {
  /**
   * Create a new user with default password
   */
  async createUserWithDefaultPassword(data: CreateUserRequest): Promise<{ user: User; tokens: TokenPair; defaultPassword: string }> {
    const pool = await getConnection();
    const transaction = pool.transaction();

    try {
      await transaction.begin();

      // Check if email already exists
      const emailCheck = await transaction.request()
        .input('Email', sql.NVarChar(256), data.email)
        .query(`
          SELECT UserId FROM [auth].[Users]
          WHERE Email = @Email AND DeletedAtUtc IS NULL
        `);

      if (emailCheck.recordset.length > 0) {
        throw new Error('User with this email already exists');
      }

      // Verify company exists
      const companyCheck = await transaction.request()
        .input('CompanyId', sql.BigInt, data.companyId)
        .query(`
          SELECT CompanyId, IsActive FROM [core].[Companies]
          WHERE CompanyId = @CompanyId AND DeletedAtUtc IS NULL
        `);

      if (companyCheck.recordset.length === 0) {
        throw new Error('Company not found');
      }

      if (!companyCheck.recordset[0].IsActive) {
        throw new Error('Company is not active');
      }

      // Hash default password
      const defaultPassword = config.app.defaultPassword;
      const passwordHash = await hashPassword(defaultPassword);

      // Insert user
      const userResult = await transaction.request()
        .input('CompanyId', sql.BigInt, data.companyId)
        .input('Email', sql.NVarChar(256), data.email)
        .input('DisplayName', sql.NVarChar(128), data.displayName)
        .input('PasswordHash', sql.VarBinary(256), passwordHash)
        .query(`
          INSERT INTO [auth].[Users] (
            CompanyId, Email, DisplayName, PasswordHash, IsActive
          )
          OUTPUT INSERTED.*
          VALUES (
            @CompanyId, @Email, @DisplayName, @PasswordHash, 1
          )
        `);

      const user = userResult.recordset[0] as User;

      // Assign role (default to COMPANY_ADMIN if not specified)
      const roleId = data.roleId || 2; // 2 = COMPANY_ADMIN
      await transaction.request()
        .input('UserId', sql.BigInt, user.UserId)
        .input('RoleId', sql.Int, roleId)
        .query(`
          INSERT INTO [auth].[UserRoles] (UserId, RoleId)
          VALUES (@UserId, @RoleId)
        `);

      // Get user roles
      const rolesResult = await transaction.request()
        .input('UserId', sql.BigInt, user.UserId)
        .query(`
          SELECT r.Name
          FROM [auth].[UserRoles] ur
          JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
          WHERE ur.UserId = @UserId
        `);

      const roles = rolesResult.recordset.map((r: any) => r.Name);

      await transaction.commit();

      // Generate tokens
      const jwtPayload: JwtPayload = {
        userId: user.UserId,
        email: user.Email,
        companyId: user.CompanyId,
        roles,
      };

      const tokens = generateTokens(jwtPayload);

      return { user, tokens, defaultPassword };
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }

  /**
   * Login user
   */
  async login(email: string, password: string, ipAddress?: string, userAgent?: string): Promise<{ user: User; tokens: TokenPair }> {
    const pool = await getConnection();

    try {
      // Get user with roles
      const userResult = await pool.request()
        .input('Email', sql.NVarChar(256), email)
        .query(`
          SELECT u.*, r.Name as RoleName
          FROM [auth].[Users] u
          LEFT JOIN [auth].[UserRoles] ur ON ur.UserId = u.UserId
          LEFT JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
          WHERE u.Email = @Email AND u.DeletedAtUtc IS NULL
        `);

      if (userResult.recordset.length === 0) {
        // Log failed attempt
        await this.logLoginAttempt(email, null, false, 'User not found', ipAddress, userAgent);
        throw new Error('Invalid email or password');
      }

      const user = userResult.recordset[0] as User;
      const roles = userResult.recordset.map((r: any) => r.RoleName).filter((r: string) => r);

      // Check if user is active
      if (!user.IsActive) {
        await this.logLoginAttempt(email, user.UserId, false, 'User is inactive', ipAddress, userAgent);
        throw new Error('User account is inactive');
      }

      // Check if user is locked
      if (user.IsLocked) {
        await this.logLoginAttempt(email, user.UserId, false, 'User is locked', ipAddress, userAgent);
        throw new Error('User account is locked due to too many failed login attempts');
      }

      // Verify password
      const isValidPassword = await verifyPassword(password, user.PasswordHash);

      if (!isValidPassword) {
        // Increment failed login attempts
        await this.incrementFailedLoginAttempts(user.UserId);
        await this.logLoginAttempt(email, user.UserId, false, 'Invalid password', ipAddress, userAgent);
        throw new Error('Invalid email or password');
      }

      // Reset failed login attempts
      await this.resetFailedLoginAttempts(user.UserId);

      // Update last login
      await pool.request()
        .input('UserId', sql.BigInt, user.UserId)
        .query(`
          UPDATE [auth].[Users]
          SET LastLoginUtc = SYSUTCDATETIME()
          WHERE UserId = @UserId
        `);

      // Log successful login
      await this.logLoginAttempt(email, user.UserId, true, null, ipAddress, userAgent);

      // Generate tokens
      const jwtPayload: JwtPayload = {
        userId: user.UserId,
        email: user.Email,
        companyId: user.CompanyId,
        roles,
      };

      const tokens = generateTokens(jwtPayload);

      return { user, tokens };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Set/Reset user password
   */
  async setPassword(userId: number, newPassword: string): Promise<void> {
    const pool = await getConnection();

    try {
      // Get user
      const userResult = await pool.request()
        .input('UserId', sql.BigInt, userId)
        .query(`
          SELECT UserId, IsActive FROM [auth].[Users]
          WHERE UserId = @UserId AND DeletedAtUtc IS NULL
        `);

      if (userResult.recordset.length === 0) {
        throw new Error('User not found');
      }

      const user = userResult.recordset[0];

      if (!user.IsActive) {
        throw new Error('User is not active');
      }

      // Hash new password
      const passwordHash = await hashPassword(newPassword);

      // Update password and reset failed attempts if locked
      await pool.request()
        .input('UserId', sql.BigInt, userId)
        .input('PasswordHash', sql.VarBinary(256), passwordHash)
        .query(`
          UPDATE [auth].[Users]
          SET PasswordHash = @PasswordHash,
              FailedLoginAttempts = 0,
              IsLocked = 0,
              LastFailedLoginUtc = NULL
          WHERE UserId = @UserId
        `);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Get user by ID
   */
  async getUserById(userId: number): Promise<User | null> {
    const pool = await getConnection();
    const result = await pool.request()
      .input('UserId', sql.BigInt, userId)
      .query(`
        SELECT * FROM [auth].[Users]
        WHERE UserId = @UserId AND DeletedAtUtc IS NULL
      `);

    return result.recordset[0] as User || null;
  }

  /**
   * Increment failed login attempts
   */
  private async incrementFailedLoginAttempts(userId: number): Promise<void> {
    const pool = await getConnection();
    await pool.request()
      .input('UserId', sql.BigInt, userId)
      .query(`
        UPDATE [auth].[Users]
        SET FailedLoginAttempts = FailedLoginAttempts + 1,
            LastFailedLoginUtc = SYSUTCDATETIME(),
            IsLocked = CASE WHEN FailedLoginAttempts >= 4 THEN 1 ELSE 0 END
        WHERE UserId = @UserId
      `);
  }

  /**
   * Reset failed login attempts
   */
  private async resetFailedLoginAttempts(userId: number): Promise<void> {
    const pool = await getConnection();
    await pool.request()
      .input('UserId', sql.BigInt, userId)
      .query(`
        UPDATE [auth].[Users]
        SET FailedLoginAttempts = 0,
            LastFailedLoginUtc = NULL,
            IsLocked = 0
        WHERE UserId = @UserId
      `);
  }

  /**
   * Log login attempt
   */
  private async logLoginAttempt(
    email: string,
    userId: number | null,
    success: boolean,
    failureReason: string | null,
    ipAddress?: string,
    userAgent?: string
  ): Promise<void> {
    const pool = await getConnection();
    await pool.request()
      .input('Email', sql.NVarChar(256), email)
      .input('UserId', sql.BigInt, userId)
      .input('IpAddress', sql.VarChar(45), ipAddress || null)
      .input('UserAgent', sql.NVarChar(512), userAgent || null)
      .input('Success', sql.Bit, success)
      .input('FailureReason', sql.NVarChar(256), failureReason)
      .query(`
        INSERT INTO [auth].[LoginAttempts] (Email, UserId, IpAddress, UserAgent, Success, FailureReason)
        VALUES (@Email, @UserId, @IpAddress, @UserAgent, @Success, @FailureReason)
      `);
  }
}
