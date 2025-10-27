import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { UserService } from '../services/userService';
import { LoginRequest } from '../types';
import { validateRequest, loginSchema } from '../utils/validation';
import { successResponse, errorResponse, serverErrorResponse } from '../utils/response';

/**
 * Azure Function: User Login
 * Endpoint: POST /api/auth/login
 *
 * Authenticates a user and returns JWT tokens.
 * No authentication required (public endpoint).
 */
async function login(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  context.log('HTTP trigger function (login) processing request');

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
    const { value, error } = validateRequest<LoginRequest>(loginSchema, body);
    if (error) {
      return errorResponse(`Validation error: ${error}`);
    }

    // Get client info for logging
    const ipAddress = request.headers.get('x-forwarded-for') || request.headers.get('x-real-ip') || 'unknown';
    const userAgent = request.headers.get('user-agent') || 'unknown';

    // Attempt login
    const userService = new UserService();
    const result = await userService.login(value.email, value.password, ipAddress, userAgent);

    context.log(`User logged in successfully: ${result.user.Email}`);

    return successResponse(
      {
        user: {
          userId: result.user.UserId,
          companyId: result.user.CompanyId,
          email: result.user.Email,
          displayName: result.user.DisplayName,
          isActive: result.user.IsActive,
          lastLoginAt: result.user.LastLoginUtc,
        },
        authentication: {
          accessToken: result.tokens.accessToken,
          refreshToken: result.tokens.refreshToken,
          expiresIn: result.tokens.expiresIn,
          tokenType: 'Bearer',
        },
      },
      'Login successful'
    );
  } catch (error: any) {
    context.error('Error during login:', error);

    // Don't expose detailed error messages for security reasons
    if (error.message.includes('Invalid email or password') ||
        error.message.includes('locked') ||
        error.message.includes('inactive')) {
      return errorResponse(error.message, 401);
    }

    return serverErrorResponse('Login failed', error.toString());
  }
}

app.http('login', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'auth/login',
  handler: login,
});

export default login;
