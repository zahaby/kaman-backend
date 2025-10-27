import { app, HttpRequest, HttpResponseInit, InvocationContext } from '@azure/functions';
import { CompanyService } from '../services/companyService';
import { CreateCompanyRequest } from '../types';
import { validateRequest, createCompanySchema } from '../utils/validation';
import { successResponse, errorResponse, serverErrorResponse, unauthorizedResponse } from '../utils/response';
import { authenticate, isSuperAdmin } from '../middleware/auth';

/**
 * Azure Function: Create Company with Wallet
 * Endpoint: POST /api/company/create
 *
 * Creates a new company and automatically creates a wallet for it.
 * Only accessible by Super Admins.
 */
async function createCompany(request: HttpRequest, context: InvocationContext): Promise<HttpResponseInit> {
  context.log('HTTP trigger function (createCompany) processing request');

  try {
    // Authenticate request
    const authResult = authenticate(request);
    if (!authResult.authenticated || !authResult.user) {
      return unauthorizedResponse(authResult.error);
    }

    // Check if user is super admin
    if (!isSuperAdmin(authResult.user)) {
      return errorResponse('Only super admins can create companies', 403);
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
    const { value, error } = validateRequest<CreateCompanyRequest>(createCompanySchema, body);
    if (error) {
      return errorResponse(`Validation error: ${error}`);
    }

    // Create company
    const companyService = new CompanyService();
    const result = await companyService.createCompanyWithWallet(value);

    context.log(`Company created successfully: ${result.company.CompanyCode}`);

    return successResponse(
      {
        company: {
          companyId: result.company.CompanyId,
          companyCode: result.company.CompanyCode,
          name: result.company.Name,
          email: result.company.Email,
          phone: result.company.Phone,
          country: result.company.Country,
          address: result.company.Address,
          defaultCurrency: result.company.DefaultCurrency,
          minimumBalance: result.company.MinimumBalance,
          isActive: result.company.IsActive,
          createdAt: result.company.CreatedAtUtc,
        },
        wallet: {
          walletId: result.wallet.WalletId,
          companyId: result.wallet.CompanyId,
          currency: result.wallet.Currency,
          createdAt: result.wallet.CreatedAtUtc,
        },
      },
      'Company and wallet created successfully',
      201
    );
  } catch (error: any) {
    context.error('Error creating company:', error);
    return serverErrorResponse(error.message || 'Failed to create company', error.toString());
  }
}

app.http('createCompany', {
  methods: ['POST'],
  authLevel: 'anonymous',
  route: 'company/create',
  handler: createCompany,
});

export default createCompany;
