import { HttpResponseInit } from '@azure/functions';
import { ApiResponse } from '../types';

export function successResponse<T>(data: T, message: string = 'Success', statusCode: number = 200): HttpResponseInit {
  const response: ApiResponse<T> = {
    success: true,
    message,
    data,
  };

  return {
    status: statusCode,
    jsonBody: response,
    headers: {
      'Content-Type': 'application/json',
    },
  };
}

export function errorResponse(message: string, statusCode: number = 400, error?: string): HttpResponseInit {
  const response: ApiResponse = {
    success: false,
    message,
    error: error || message,
  };

  return {
    status: statusCode,
    jsonBody: response,
    headers: {
      'Content-Type': 'application/json',
    },
  };
}

export function unauthorizedResponse(message: string = 'Unauthorized'): HttpResponseInit {
  return errorResponse(message, 401);
}

export function forbiddenResponse(message: string = 'Forbidden'): HttpResponseInit {
  return errorResponse(message, 403);
}

export function notFoundResponse(message: string = 'Resource not found'): HttpResponseInit {
  return errorResponse(message, 404);
}

export function serverErrorResponse(message: string = 'Internal server error', error?: string): HttpResponseInit {
  return errorResponse(message, 500, error);
}
