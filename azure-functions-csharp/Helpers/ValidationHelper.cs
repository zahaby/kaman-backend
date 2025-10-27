using FluentValidation;
using KamanAzureFunctions.DTOs;

namespace KamanAzureFunctions.Helpers;

public class CreateCompanyRequestValidator : AbstractValidator<CreateCompanyRequest>
{
    public CreateCompanyRequestValidator()
    {
        RuleFor(x => x.CompanyCode)
            .NotEmpty()
            .Length(3, 32)
            .Matches("^[A-Z0-9_]+$")
            .WithMessage("Company code must contain only uppercase letters, numbers, and underscores");

        RuleFor(x => x.Name)
            .NotEmpty()
            .Length(2, 200);

        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress()
            .MaximumLength(256);

        RuleFor(x => x.Phone)
            .MaximumLength(64)
            .When(x => !string.IsNullOrEmpty(x.Phone));

        RuleFor(x => x.Country)
            .MaximumLength(64)
            .When(x => !string.IsNullOrEmpty(x.Country));

        RuleFor(x => x.Address)
            .MaximumLength(512)
            .When(x => !string.IsNullOrEmpty(x.Address));

        RuleFor(x => x.DefaultCurrency)
            .NotEmpty()
            .Length(3)
            .Matches("^[A-Z]{3}$")
            .WithMessage("Currency must be a 3-letter ISO code");

        RuleFor(x => x.MinimumBalance)
            .GreaterThanOrEqualTo(0);
    }
}

public class CreateUserRequestValidator : AbstractValidator<CreateUserRequest>
{
    public CreateUserRequestValidator()
    {
        RuleFor(x => x.CompanyId)
            .GreaterThan(0);

        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress()
            .MaximumLength(256);

        RuleFor(x => x.DisplayName)
            .NotEmpty()
            .Length(2, 128);

        RuleFor(x => x.RoleId)
            .GreaterThan(0)
            .When(x => x.RoleId.HasValue);
    }
}

public class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty()
            .EmailAddress();

        RuleFor(x => x.Password)
            .NotEmpty();
    }
}

public class SetPasswordRequestValidator : AbstractValidator<SetPasswordRequest>
{
    public SetPasswordRequestValidator()
    {
        RuleFor(x => x.UserId)
            .GreaterThan(0);

        RuleFor(x => x.NewPassword)
            .NotEmpty()
            .Length(8, 128);
    }
}

public class RefreshTokenRequestValidator : AbstractValidator<RefreshTokenRequest>
{
    public RefreshTokenRequestValidator()
    {
        RuleFor(x => x.RefreshToken)
            .NotEmpty();
    }
}
