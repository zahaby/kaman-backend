import { getConnection, sql } from '../config/database';
import { Company, CreateCompanyRequest, Wallet } from '../types';

export class CompanyService {
  /**
   * Create a new company with wallet
   */
  async createCompanyWithWallet(data: CreateCompanyRequest): Promise<{ company: Company; wallet: Wallet }> {
    const pool = await getConnection();
    const transaction = pool.transaction();

    try {
      await transaction.begin();

      // Check if company code already exists
      const checkResult = await transaction.request()
        .input('CompanyCode', sql.VarChar(32), data.companyCode)
        .query(`
          SELECT CompanyId FROM [core].[Companies]
          WHERE CompanyCode = @CompanyCode AND DeletedAtUtc IS NULL
        `);

      if (checkResult.recordset.length > 0) {
        throw new Error('Company code already exists');
      }

      // Check if email already exists
      const emailCheck = await transaction.request()
        .input('Email', sql.NVarChar(256), data.email)
        .query(`
          SELECT CompanyId FROM [core].[Companies]
          WHERE Email = @Email AND DeletedAtUtc IS NULL
        `);

      if (emailCheck.recordset.length > 0) {
        throw new Error('Company email already exists');
      }

      // Insert company
      const companyResult = await transaction.request()
        .input('CompanyCode', sql.VarChar(32), data.companyCode)
        .input('Name', sql.NVarChar(200), data.name)
        .input('Email', sql.NVarChar(256), data.email)
        .input('Phone', sql.NVarChar(64), data.phone || null)
        .input('Country', sql.NVarChar(64), data.country || null)
        .input('Address', sql.NVarChar(512), data.address || null)
        .input('DefaultCurrency', sql.Char(3), data.defaultCurrency || 'EGP')
        .input('MinimumBalance', sql.Decimal(18, 2), data.minimumBalance || 0)
        .query(`
          INSERT INTO [core].[Companies] (
            CompanyCode, Name, Email, Phone, Country, Address, DefaultCurrency, MinimumBalance, IsActive
          )
          OUTPUT INSERTED.*
          VALUES (
            @CompanyCode, @Name, @Email, @Phone, @Country, @Address, @DefaultCurrency, @MinimumBalance, 1
          )
        `);

      const company = companyResult.recordset[0] as Company;

      // The wallet is automatically created by the trigger, but we'll query it
      const walletResult = await transaction.request()
        .input('CompanyId', sql.BigInt, company.CompanyId)
        .query(`
          SELECT * FROM [wallet].[Wallets]
          WHERE CompanyId = @CompanyId
        `);

      const wallet = walletResult.recordset[0] as Wallet;

      await transaction.commit();

      return { company, wallet };
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }

  /**
   * Get company by ID
   */
  async getCompanyById(companyId: number): Promise<Company | null> {
    const pool = await getConnection();
    const result = await pool.request()
      .input('CompanyId', sql.BigInt, companyId)
      .query(`
        SELECT * FROM [core].[Companies]
        WHERE CompanyId = @CompanyId AND DeletedAtUtc IS NULL
      `);

    return result.recordset[0] as Company || null;
  }

  /**
   * Get company by code
   */
  async getCompanyByCode(companyCode: string): Promise<Company | null> {
    const pool = await getConnection();
    const result = await pool.request()
      .input('CompanyCode', sql.VarChar(32), companyCode)
      .query(`
        SELECT * FROM [core].[Companies]
        WHERE CompanyCode = @CompanyCode AND DeletedAtUtc IS NULL
      `);

    return result.recordset[0] as Company || null;
  }

  /**
   * Check if company exists and is active
   */
  async isCompanyActive(companyId: number): Promise<boolean> {
    const pool = await getConnection();
    const result = await pool.request()
      .input('CompanyId', sql.BigInt, companyId)
      .query(`
        SELECT IsActive FROM [core].[Companies]
        WHERE CompanyId = @CompanyId AND DeletedAtUtc IS NULL
      `);

    return result.recordset[0]?.IsActive === true;
  }
}
