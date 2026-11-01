using System.Security.Claims;

namespace Zdybanka.Infrastructure.TokenValidation;

public interface ITokenController
{
    string CreateToken(Guid userId);
}