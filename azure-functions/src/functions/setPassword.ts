import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { UserService } from '../services/userService';
import { SetPasswordRequest } from '../types';
import { validateRequest, setPasswordSchema } from '../utils/validation';
import { validatePasswordStrength } from '../utils/password';
import { successResponse, errorResponse, serverErrorResponse, unauthorizedResponse } from '../utils/response';
import { authenticate, isSuperAdmin, belongsToCompany } from '../middleware/auth';

/**
 * Azure Function: Set/Reset User Password
 * Endpoint: POST /api/user/set-password
 *
 * Sets or resets a user's password.
 * Super Admins can reset any user's password.
 * Users can reset their own password.
 * Company Admins can reset passwords for users in their company.
 */
async function setPassword(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  context.log('HTTP trigger function (setPassword) processing request');

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
    const { value, error } = validateRequest<SetPasswordRequest>(setPasswordSchema, body);
    if (error) {
      return errorResponse(`Validation error: ${error}`);
    }

    // Validate password strength
    const passwordValidation = validatePasswordStrength(value.newPassword);
    if (!passwordValidation.valid) {
      return errorResponse(`Password validation failed: ${passwordValidation.message}`);
    }

    // Get the user whose password is being changed
    const userService = new UserService();
    const targetUser = await userService.getUserById(value.userId);

    if (!targetUser) {
      return errorResponse('User not found', 404);
    }

    // Authorization check
    const isSuperAdminUser = isSuperAdmin(authResult.user);
    const isSelfReset = authResult.user.userId === value.userId;
    const isSameCompanyUser = targetUser.CompanyId && belongsToCompany(authResult.user, targetUser.CompanyId);

    // Super admins can reset any password
    // Users can reset their own password
    // Company admins can reset passwords for users in their company
    if (!isSuperAdminUser && !isSelfReset && !isSameCompanyUser) {
      return errorResponse('You do not have permission to reset this user\'s password', 403);
    }

    // Set password
    await userService.setPassword(value.userId, value.newPassword);

    context.log(`Password set successfully for user: ${targetUser.Email}`);

    return successResponse(
      {
        userId: targetUser.UserId,
        email: targetUser.Email,
        message: 'Password has been set successfully',
      },
      'Password updated successfully'
    );
  } catch (error: any) {
    context.error('Error setting password:', error);
    return serverErrorResponse(error.message || 'Failed to set password', error.toString());
  }
}

app.http('setPassword', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'user/set-password',
  handler: setPassword,
});

export default setPassword;
