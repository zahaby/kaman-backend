import * as Joi from 'joi';

export const createCompanySchema = Joi.object({
  companyCode: Joi.string()
    .min(3)
    .max(32)
    .pattern(/^[A-Z0-9_]+$/)
    .required()
    .messages({
      'string.pattern.base': 'Company code must contain only uppercase letters, numbers, and underscores',
    }),
  name: Joi.string().min(2).max(200).required(),
  email: Joi.string().email().required(),
  phone: Joi.string().max(64).optional().allow(null, ''),
  country: Joi.string().max(64).optional().allow(null, ''),
  address: Joi.string().max(512).optional().allow(null, ''),
  defaultCurrency: Joi.string().length(3).uppercase().default('EGP'),
  minimumBalance: Joi.number().min(0).default(0),
});

export const createUserSchema = Joi.object({
  companyId: Joi.number().integer().positive().required(),
  email: Joi.string().email().max(256).required(),
  displayName: Joi.string().min(2).max(128).required(),
  roleId: Joi.number().integer().positive().optional(),
});

export const loginSchema = Joi.object({
  email: Joi.string().email().required(),
  password: Joi.string().required(),
});

export const setPasswordSchema = Joi.object({
  userId: Joi.number().integer().positive().required(),
  newPassword: Joi.string().min(8).max(128).required(),
});

export const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

export function validateRequest<T>(schema: Joi.ObjectSchema, data: any): { value: T; error: string | null } {
  const { error, value } = schema.validate(data, { abortEarly: false });

  if (error) {
    const errorMessage = error.details.map((detail) => detail.message).join(', ');
    return { value: null as any, error: errorMessage };
  }

  return { value: value as T, error: null };
}
