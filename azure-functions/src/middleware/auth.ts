import { HttpRequest } from '@azure/functions';
import { extractTokenFromHeader, verifyAccessToken } from '../utils/jwt';
import { JwtPayload } from '../types';

export interface AuthenticatedRequest extends HttpRequest {
  user?: JwtPayload;
}

/**
 * Middleware to authenticate requests using JWT
 */
export function authenticate(request: HttpRequest): { authenticated: boolean; user?: JwtPayload; error?: string } {
  const authHeader = request.headers.get('authorization');
  const token = extractTokenFromHeader(authHeader || '');

  if (!token) {
    return {
      authenticated: false,
      error: 'No authentication token provided',
    };
  }

  try {
    const user = verifyAccessToken(token);
    return {
      authenticated: true,
      user,
    };
  } catch (error) {
    return {
      authenticated: false,
      error: 'Invalid or expired token',
    };
  }
}

/**
 * Check if user has required role
 */
export function hasRole(user: JwtPayload, requiredRole: string): boolean {
  return user.roles.includes(requiredRole);
}

/**
 * Check if user is super admin
 */
export function isSuperAdmin(user: JwtPayload): boolean {
  return hasRole(user, 'SUPER_ADMIN');
}

/**
 * Check if user is company admin
 */
export function isCompanyAdmin(user: JwtPayload): boolean {
  return hasRole(user, 'COMPANY_ADMIN');
}

/**
 * Check if user belongs to a specific company
 */
export function belongsToCompany(user: JwtPayload, companyId: number): boolean {
  return user.companyId === companyId;
}
