using BCrypt.Net;
namespace Zdybanka.Infrastructure;

public class BcryptPasswordHasher : IPasswordHasher
{
    private readonly BCrypt.Net.HashType _hashType = HashType.SHA256;
    public string HashPassword(string password)
    {
        return BCrypt.Net.BCrypt.EnhancedHashPassword(password, 10, _hashType);
    }

    public bool VerifyPassword(string password, string passwordHash)
    {
        return BCrypt.Net.BCrypt.EnhancedVerify(password, passwordHash, _hashType);
    }
}