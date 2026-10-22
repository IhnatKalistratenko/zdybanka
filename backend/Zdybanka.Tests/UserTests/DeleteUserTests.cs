using Microsoft.EntityFrameworkCore;
using Zdybanka.Application.Services;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Tests.Common;
using Xunit;

namespace Zdybanka.Tests.UserTests;

public class DeleteUserTests : UserTest
{
   
    [Fact]
    public async Task DeleteUser_Success()
    {
        // Arrange
        var userTask = _context.Users.FirstAsync(u => u.Username == ZdybankaContextFactory.Username1);
        
        // Act
        var user = await userTask;
        await Service.RemoveUserAsync(user.Id);
        
        // Assert
        var userCountAfter = _context.Users.CountAsync(u => u.Username == ZdybankaContextFactory.Username1);
        Assert.Equal(0, await userCountAfter);
        Assert.Null(await _context.Users.FirstOrDefaultAsync(u => u.Username == ZdybankaContextFactory.Username1 && u.Id == user.Id));
    }

    [Fact]
    public async Task DeleteUser_FailOnWrongId()
    {
        // Assert
        var wrongId = Guid.NewGuid();
        
        // Act
        // Assert
        await Assert.ThrowsAsync<KeyNotFoundException>(async () => await Service.RemoveUserAsync(wrongId));
    }
}