using Zdybanka.Application.DTO;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Infrastructure.TokenValidation;

namespace Zdybanka.Application.Services;

public class AuthService(IUserRepository userRepository, IPasswordHasher passwordHasher, ITokenController tokenController)
{
    private readonly IUserRepository _userRepository = userRepository;
    private readonly IPasswordHasher _passwordHasher = passwordHasher;
    private readonly ITokenController _tokenController = tokenController;

    public async Task<string> AuthorizeUser(LoginRequest request)
    {
        User? user = await _userRepository.FindUser(user => user.Username == request.Username);
        if (user == null)
        {
            throw new KeyNotFoundException("There is no user with the given username");
        }

        if (!_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Wrong password");
        }

        return _tokenController.CreateToken(user.Id);
    }
}