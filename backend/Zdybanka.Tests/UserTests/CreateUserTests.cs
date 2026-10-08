using Microsoft.EntityFrameworkCore;
using Xunit;
using Zdybanka.Application.DTO.User;
using Zdybanka.Application.Services;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.UserTests;

public class CreateUserTests : UserTest
{
   
    [Fact]
    public async Task CreateUser_Success()
    {
        // Arrange
        var username = "ihnat";
        var password = "password";
        
        // Act
        UserResponse userResponse = await _service.CreateUserAsync(new CreateUserRequest()
        {
            Username = username,
            Password = password,
        });
        
        // Assert
        Assert.NotNull(userResponse);
        Assert.NotEqual(Guid.Empty, userResponse.Id);
        Assert.Equal(username, userResponse.Username);
        var dbUser = await _context.Users.FirstOrDefaultAsync(u => u.Username == username && u.Id == userResponse.Id);
        Assert.NotNull(dbUser);
        Assert.NotEqual(dbUser.PasswordHash, password);
        Assert.True(_passwordHasher.VerifyPassword(password, dbUser.PasswordHash));
    }

    [Fact]
    public async Task CreateUser_FailOnExistingUsername()
    {
        // Arrange
        var existingUsername = ZdybankaContextFactory.Username1;
        var password = "password";
        var dto = new CreateUserRequest()
        {
            Username = existingUsername,
            Password = password,
        };
        
        var userCountBefore = await _context.Users.CountAsync(u => u.Username == existingUsername);
        
        // Act
        // Assert
        await Assert.ThrowsAsync<ArgumentException>(async () => await _service.CreateUserAsync(dto));
        var userCountAfter = await _context.Users.CountAsync(u => u.Username == existingUsername);
        Assert.Equal(userCountBefore, userCountAfter);
    }
}