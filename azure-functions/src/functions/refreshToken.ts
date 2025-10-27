import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { UserService } from '../services/userService';
import { RefreshTokenRequest, JwtPayload } from '../types';
import { validateRequest, refreshTokenSchema } from '../utils/validation';
import { verifyRefreshToken, generateTokens } from '../utils/jwt';
import { successResponse, errorResponse, serverErrorResponse } from '../utils/response';
import { getConnection, sql } from '../config/database';

/**
 * Azure Function: Refresh Token
 * Endpoint: POST /api/auth/refresh
 *
 * Refreshes an expired access token using a valid refresh token.
 * No authentication required (uses refresh token).
 */
async function refreshToken(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  context.log('HTTP trigger function (refreshToken) processing request');

  try {
    // Parse request body
    let body: any;
    try {
      const text = await request.text();
      body = JSON.parse(text);
    } catch (error) {
      return errorResponse('Invalid JSON in request body');
    }

    // Validate request
    const { value, error } = validateRequest<RefreshTokenRequest>(refreshTokenSchema, body);
    if (error) {
      return errorResponse(`Validation error: ${error}`);
    }

    // Verify refresh token
    let tokenPayload: { userId: number; email: string };
    try {
      tokenPayload = verifyRefreshToken(value.refreshToken);
    } catch (error) {
      return errorResponse('Invalid or expired refresh token', 401);
    }

    // Get user with roles
    const pool = await getConnection();
    const userResult = await pool.request()
      .input('UserId', sql.BigInt, tokenPayload.userId)
      .query(`
        SELECT u.*, r.Name as RoleName
        FROM [auth].[Users] u
        LEFT JOIN [auth].[UserRoles] ur ON ur.UserId = u.UserId
        LEFT JOIN [auth].[Roles] r ON r.RoleId = ur.RoleId
        WHERE u.UserId = @UserId AND u.DeletedAtUtc IS NULL
      `);

    if (userResult.recordset.length === 0) {
      return errorResponse('User not found', 404);
    }

    const user = userResult.recordset[0];
    const roles = userResult.recordset.map((r: any) => r.RoleName).filter((r: string) => r);

    // Check if user is still active
    if (!user.IsActive) {
      return errorResponse('User account is inactive', 403);
    }

    if (user.IsLocked) {
      return errorResponse('User account is locked', 403);
    }

    // Generate new tokens
    const jwtPayload: JwtPayload = {
      userId: user.UserId,
      email: user.Email,
      companyId: user.CompanyId,
      roles,
    };

    const tokens = generateTokens(jwtPayload);

    context.log(`Token refreshed successfully for user: ${user.Email}`);

    return successResponse(
      {
        authentication: {
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          expiresIn: tokens.expiresIn,
          tokenType: 'Bearer',
        },
      },
      'Token refreshed successfully'
    );
  } catch (error: any) {
    context.error('Error refreshing token:', error);
    return serverErrorResponse('Failed to refresh token', error.toString());
  }
}

app.http('refreshToken', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'auth/refresh',
  handler: refreshToken,
});

export default refreshToken;
