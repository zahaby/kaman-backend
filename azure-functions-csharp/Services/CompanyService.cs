using Dapper;
using KamanAzureFunctions.DTOs;
using KamanAzureFunctions.Helpers;
using KamanAzureFunctions.Models;
using System.Data;

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
                "[core].[sp_CheckCompanyCodeExists]",
                new { CompanyCode = request.CompanyCode },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            if (existingCompany != null)
            {
                throw new InvalidOperationException("Company code already exists");
            }

            // Check if email already exists
            var existingEmail = await connection.QueryFirstOrDefaultAsync<Company>(
                "[core].[sp_CheckCompanyEmailExists]",
                new { Email = request.Email },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            if (existingEmail != null)
            {
                throw new InvalidOperationException("Company email already exists");
            }

            // Insert company
            var companyIdResult = await connection.QuerySingleAsync<dynamic>(
                "[core].[sp_InsertCompany]",
                new
                {
                    CompanyCode = request.CompanyCode,
                    Name = request.Name,
                    Email = request.Email,
                    Phone = request.Phone,
                    Country = request.Country,
                    Address = request.Address,
                    DefaultCurrency = request.DefaultCurrency,
                    MinimumBalance = request.MinimumBalance
                },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            long companyId = companyIdResult.CompanyId;

            // Retrieve the inserted company
            var company = await connection.QuerySingleAsync<Company>(
                "[core].[sp_GetCompanyById]",
                new { CompanyId = companyId },
                transaction,
                commandType: CommandType.StoredProcedure
            );

            // The wallet is automatically created by the trigger, but we'll query it
            var wallet = await connection.QuerySingleAsync<Wallet>(
                "[wallet].[sp_GetWalletByCompanyId]",
                new { CompanyId = companyId },
                transaction,
                commandType: CommandType.StoredProcedure
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
            "[core].[sp_GetCompanyById]",
            new { CompanyId = companyId },
            commandType: CommandType.StoredProcedure
        );
    }

    /// <summary>
    /// Check if company is active
    /// </summary>
    public async Task<bool> IsCompanyActiveAsync(long companyId)
    {
        using var connection = _dbHelper.GetConnection();
        var result = await connection.QueryFirstOrDefaultAsync<bool?>(
            "[core].[sp_IsCompanyActive]",
            new { CompanyId = companyId },
            commandType: CommandType.StoredProcedure
        );
        return result ?? false;
    }

    /// <summary>
    /// Get all companies (for super admin)
    /// </summary>
    public async Task<IEnumerable<Company>> GetAllCompaniesAsync(bool includeInactive = false)
    {
        using var connection = _dbHelper.GetConnection();
        return await connection.QueryAsync<Company>(
            "[core].[sp_GetAllCompanies]",
            new { IncludeInactive = includeInactive },
            commandType: CommandType.StoredProcedure
        );
    }
}
