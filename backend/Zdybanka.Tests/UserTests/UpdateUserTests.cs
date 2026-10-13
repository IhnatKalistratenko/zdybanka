using Microsoft.EntityFrameworkCore;
using Zdybanka.Application.DTO.User;
using Zdybanka.Application.Services;
using Zdybanka.Core;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.UserTests;

public class UpdateUserTests : UserTest
{
    private const string _oldUsername = ZdybankaContextFactory.Username1;
    private const string _newUsername = "newUsername";
    private const string _oldPassword = ZdybankaContextFactory.UserPassword1;
    private const string _newPassword = "newPassword";

    [Fact]
    public async Task UpdateUser_Success()
    {
        // Arrange
        var existingUser = await _context.Users.AsNoTracking().FirstAsync(u => u.Username == _oldUsername);
        
        UpdateUserRequest request = new()
        {
            Id = existingUser.Id,
            Username = _newUsername,
            ConfirmPassword = _oldPassword,
            NewPassword = _newPassword
        };
        // Act
        UserResponse response = await Service.UpdateUserAsync(request);

        // Assert
        Assert.NotNull(response);
        User? updatedUser =  await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == response.Id);
        Assert.NotNull(updatedUser);
        
        // Check ID
        Assert.Equal(existingUser.Id, updatedUser.Id);
        
        // Check username
        Assert.Null(await _context.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Username == _oldUsername));
        Assert.Equal(_newUsername, updatedUser.Username);
        Assert.Equal(_newUsername, response.Username);
        
        // Check password
        Assert.False(PasswordHasher.VerifyPassword(_oldPassword, updatedUser.PasswordHash));
        Assert.True(PasswordHasher.VerifyPassword(_newPassword, updatedUser.PasswordHash));
    }

    [Fact]
    public async Task UpdateUser_FailOnWrongId()
    {
        // Arrange
        var dto = new UpdateUserRequest()
        {
            Id = Guid.NewGuid(),
            Username = "newUsername",
            ConfirmPassword = "newPassword",
            NewPassword = "newPassword",
        };
        
        // Act
       
        // Assert
        await Assert.ThrowsAsync<KeyNotFoundException>(async () => await Service.UpdateUserAsync(dto));
    }

    [Fact]
    public async Task UpdateUser_FailOnWrongPassword()
    {
        // Assert
        var wrongPassword = "wrongPassword";
        var dbUserBefore = await _context.Users.AsNoTracking().FirstAsync(u => u.Username == _oldUsername);
        var userId = dbUserBefore.Id;
        UpdateUserRequest request = new()
        {
            Id =  userId,
            Username = _newUsername,
            ConfirmPassword = wrongPassword,
            NewPassword = _newPassword,
        };
        
        // Act
        
        // Assert
        await Assert.ThrowsAsync<UnauthorizedAccessException>(async () => await Service.UpdateUserAsync(request));
        
        var dbUserAfter = await _context.Users.AsNoTracking().FirstAsync(u => u.Id == userId);
        Assert.Equal(_oldUsername, dbUserAfter.Username);
        Assert.NotEqual(_newPassword, dbUserAfter.PasswordHash);
        Assert.False(PasswordHasher.VerifyPassword(_newPassword, dbUserAfter.PasswordHash));
        Assert.True(PasswordHasher.VerifyPassword(_oldPassword, dbUserAfter.PasswordHash));
    }

    [Fact]
    public async Task UpdateUser_FailOnExistingUsername()
    {
        // Arrange
        var existingUsername = ZdybankaContextFactory.Username2;
        var dbUserBefore = await _context.Users.AsNoTracking().FirstAsync(u => u.Username == _oldUsername);
        var userId = dbUserBefore.Id;
        
        UpdateUserRequest request = new()
        {
            Id = userId,
            Username = existingUsername,
            ConfirmPassword = _oldPassword,
            NewPassword =  _newPassword,
        };

        // Act

        // Assert
        await Assert.ThrowsAsync<ArgumentException>(async () => await Service.UpdateUserAsync(request));
        
        var dbUserAfter = await _context.Users.AsNoTracking().FirstAsync(u => u.Id == userId);
        Assert.Equal(_oldUsername, dbUserAfter.Username);
        Assert.NotEqual(_newPassword, dbUserAfter.PasswordHash);
        Assert.False(PasswordHasher.VerifyPassword(_newPassword, dbUserAfter.PasswordHash));
        Assert.True(PasswordHasher.VerifyPassword(_oldPassword, dbUserAfter.PasswordHash));
    }
}