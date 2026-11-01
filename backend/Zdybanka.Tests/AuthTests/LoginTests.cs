using Zdybanka.Application.DTO;
using Zdybanka.Application.Services;
using Zdybanka.Core;
using Zdybanka.Data;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Infrastructure.TokenValidation;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.AuthTests;

public class LoginTests
{

    [Fact]
    public async Task LoginTest_Success()
    {
        // Arrange
        ITokenController tokenController = new JwtTokenController();
        ZdybankaContext context = ZdybankaContextFactory.Create();
        AuthService authService = new AuthService(new UserRepository(context),
            new BcryptPasswordHasher(), tokenController);
        User user = context.Users.First();
        // Act
        string token = await authService.AuthorizeUser(new LoginRequest(user.Username, "user1"));
        // Assert
        Assert.NotEqual(token, String.Empty);
        
    }
}