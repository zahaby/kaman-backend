import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { UserService } from '../services/userService';
import { CompanyService } from '../services/companyService';
import { CreateUserRequest } from '../types';
import { validateRequest, createUserSchema } from '../utils/validation';
import { successResponse, errorResponse, serverErrorResponse, unauthorizedResponse } from '../utils/response';
import { authenticate, isSuperAdmin, isCompanyAdmin, belongsToCompany } from '../middleware/auth';

/**
 * Azure Function: Create Company User and Login
 * Endpoint: POST /api/user/create
 *
 * Creates a new company user with default password and returns login tokens.
 * Accessible by Super Admins (any company) and Company Admins (own company only).
 */
async function createUserAndLogin(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  context.log('HTTP trigger function (createUserAndLogin) processing request');

  try {
    // Authenticate request
    const authResult = authenticate(request);
    if (!authResult.authenticated || !authResult.user) {
      return unauthorizedResponse(authResult.error);
    }

    // Parse request body
    let body: any;
    try {
      const text = await request.text();
      body = JSON.parse(text);
    } catch (error) {
      return errorResponse('Invalid JSON in request body');
    }

    // Validate request
    const { value, error } = validateRequest<CreateUserRequest>(createUserSchema, body);
    if (error) {
      return errorResponse(`Validation error: ${error}`);
    }

    // Authorization check
    const isSuperAdminUser = isSuperAdmin(authResult.user);
    const isCompanyAdminUser = isCompanyAdmin(authResult.user);

    if (!isSuperAdminUser && !isCompanyAdminUser) {
      return errorResponse('Insufficient permissions', 403);
    }

    // Company admins can only create users for their own company
    if (isCompanyAdminUser && !isSuperAdminUser) {
      if (!belongsToCompany(authResult.user, value.companyId)) {
        return errorResponse('You can only create users for your own company', 403);
      }
    }

    // Verify company exists and is active
    const companyService = new CompanyService();
    const company = await companyService.getCompanyById(value.companyId);
    if (!company) {
      return errorResponse('Company not found', 404);
    }

    if (!company.IsActive) {
      return errorResponse('Company is not active', 400);
    }

    // Create user
    const userService = new UserService();
    const result = await userService.createUserWithDefaultPassword(value);

    context.log(`User created successfully: ${result.user.Email}`);

    return successResponse(
      {
        user: {
          userId: result.user.UserId,
          companyId: result.user.CompanyId,
          email: result.user.Email,
          displayName: result.user.DisplayName,
          isActive: result.user.IsActive,
          createdAt: result.user.CreatedAtUtc,
        },
        authentication: {
          accessToken: result.tokens.accessToken,
          refreshToken: result.tokens.refreshToken,
          expiresIn: result.tokens.expiresIn,
          tokenType: 'Bearer',
        },
        credentials: {
          email: result.user.Email,
          defaultPassword: result.defaultPassword,
          note: 'User should change this password on first login',
        },
      },
      'User created successfully with default password',
      201
    );
  } catch (error: any) {
    context.error('Error creating user:', error);
    return serverErrorResponse(error.message || 'Failed to create user', error.toString());
  }
}

app.http('createUserAndLogin', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'user/create',
  handler: createUserAndLogin,
});

export default createUserAndLogin;
