export interface User {
  UserId: number;
  CompanyId: number | null;
  Email: string;
  DisplayName: string;
  PasswordHash: Buffer;
  PasswordSalt: Buffer | null;
  IsActive: boolean;
  IsLocked: boolean;
  FailedLoginAttempts: number;
  LastFailedLoginUtc: Date | null;
  CreatedAtUtc: Date;
  LastLoginUtc: Date | null;
  DeletedAtUtc: Date | null;
}

export interface Company {
  CompanyId: number;
  CompanyCode: string;
  Name: string;
  Email: string | null;
  Phone: string | null;
  Country: string | null;
  Address: string | null;
  DefaultCurrency: string;
  MinimumBalance: number;
  IsActive: boolean;
  CreatedAtUtc: Date;
  UpdatedAtUtc: Date | null;
  DeletedAtUtc: Date | null;
}

export interface Wallet {
  WalletId: number;
  CompanyId: number;
  Currency: string;
  CreatedAtUtc: Date;
}

export interface JwtPayload {
  userId: number;
  email: string;
  companyId: number | null;
  roles: string[];
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: string;
}

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  error?: string;
}

export interface CreateCompanyRequest {
  companyCode: string;
  name: string;
  email: string;
  phone?: string;
  country?: string;
  address?: string;
  defaultCurrency?: string;
  minimumBalance?: number;
}

export interface CreateUserRequest {
  companyId: number;
  email: string;
  displayName: string;
  roleId?: number;
}

export interface LoginRequest {
  email: string;
  password: string;
}

export interface SetPasswordRequest {
  userId: number;
  newPassword: string;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}
