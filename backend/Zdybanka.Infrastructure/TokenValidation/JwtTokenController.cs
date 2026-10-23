using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace Zdybanka.Infrastructure.TokenValidation;

public class JwtTokenController : ITokenController
{
    private readonly string _secretKey = "your_super_secret_key_with_at_least_256_bits_for_security"; 
    public string CreateToken(Guid userId)
    {
        var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_secretKey));
        var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);
        
        var claims = new List<Claim> {new Claim(ClaimTypes.NameIdentifier, userId.ToString())};

        var token = new JwtSecurityToken(
            issuer: "zdybanka-api",
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: DateTime.UtcNow.AddHours(1),
            signingCredentials: credentials);
        var handler = new JwtSecurityTokenHandler();
        return handler.WriteToken(token);
    }
}