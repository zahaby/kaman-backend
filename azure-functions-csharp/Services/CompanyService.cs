using Dapper;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Models;

namespace KamanAzureFunctions.Services;

public class CompanyService
{
    private readonly DatabaseHelper _dbHelper;

    public CompanyService(DatabaseHelper dbHelper)
    {
        _dbHelper = dbHelper;
    }

    /// <summary>
    /// Create a new company with wallet
    /// </summary>
    public async Task<(Company Company, Wallet Wallet)> CreateCompanyWithWalletAsync(CreateCompanyRequest request)
    {
        using var connection = _dbHelper.GetConnection();
        await connection.OpenAsync();

        using var transaction = connection.BeginTransaction();

        try
        {
            // Check if company code already exists
            var existingCompany = await connection.QueryFirstOrDefaultAsync<Company>(
                @"SELECT CompanyId FROM [core].[Companies]
                  WHERE CompanyCode = @CompanyCode AND DeletedAtUtc IS NULL",
                new { request.CompanyCode },
                transaction
            );

            if (existingCompany != null)
            {
                throw new InvalidOperationException("Company code already exists");
            }

            // Check if email already exists
            var existingEmail = await connection.QueryFirstOrDefaultAsync<Company>(
                @"SELECT CompanyId FROM [core].[Companies]
                  WHERE Email = @Email AND DeletedAtUtc IS NULL",
                new { request.Email },
                transaction
            );

            if (existingEmail != null)
            {
                throw new InvalidOperationException("Company email already exists");
            }

            // Insert company (using SCOPE_IDENTITY to avoid trigger conflict)
            var companyId = await connection.ExecuteScalarAsync<long>(
                @"INSERT INTO [core].[Companies] (
                    CompanyCode, Name, Email, Phone, Country, Address,
                    DefaultCurrency, MinimumBalance, IsActive
                  )
                  VALUES (
                    @CompanyCode, @Name, @Email, @Phone, @Country, @Address,
                    @DefaultCurrency, @MinimumBalance, 1
                  );
                  SELECT CAST(SCOPE_IDENTITY() AS BIGINT);",
                new
                {
                    request.CompanyCode,
                    request.Name,
                    request.Email,
                    request.Phone,
                    request.Country,
                    request.Address,
                    request.DefaultCurrency,
                    request.MinimumBalance
                },
                transaction
            );

            // Retrieve the inserted company
            var company = await connection.QuerySingleAsync<Company>(
                @"SELECT * FROM [core].[Companies] WHERE CompanyId = @CompanyId",
                new { CompanyId = companyId },
                transaction
            );

            // The wallet is automatically created by the trigger, but we'll query it
            var wallet = await connection.QuerySingleAsync<Wallet>(
                @"SELECT * FROM [wallet].[Wallets] WHERE CompanyId = @CompanyId",
                new { company.CompanyId },
                transaction
            );

            transaction.Commit();

            return (company, wallet);
        }
        catch
        {
            transaction.Rollback();
            throw;
        }
    }

    /// <summary>
    /// Get company by ID
    /// </summary>
    public async Task<Company?> GetCompanyByIdAsync(long companyId)
    {
        using var connection = _dbHelper.GetConnection();
        return await connection.QueryFirstOrDefaultAsync<Company>(
            @"SELECT * FROM [core].[Companies]
              WHERE CompanyId = @CompanyId AND DeletedAtUtc IS NULL",
            new { CompanyId = companyId }
        );
    }

    /// <summary>
    /// Check if company is active
    /// </summary>
    public async Task<bool> IsCompanyActiveAsync(long companyId)
    {
        using var connection = _dbHelper.GetConnection();
        var result = await connection.QueryFirstOrDefaultAsync<bool?>(
            @"SELECT IsActive FROM [core].[Companies]
              WHERE CompanyId = @CompanyId AND DeletedAtUtc IS NULL",
            new { CompanyId = companyId }
        );
        return result ?? false;
    }

    /// <summary>
    /// Get all companies (for super admin)
    /// </summary>
    public async Task<IEnumerable<Company>> GetAllCompaniesAsync(bool includeInactive = false)
    {
        using var connection = _dbHelper.GetConnection();

        var query = includeInactive
            ? @"SELECT * FROM [core].[Companies]
                WHERE DeletedAtUtc IS NULL
                ORDER BY CreatedAtUtc DESC"
            : @"SELECT * FROM [core].[Companies]
                WHERE IsActive = 1 AND DeletedAtUtc IS NULL
                ORDER BY CreatedAtUtc DESC";

        return await connection.QueryAsync<Company>(query);
    }
}
