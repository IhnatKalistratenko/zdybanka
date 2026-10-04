using Microsoft.EntityFrameworkCore;
using Shouldly;
using Zdybanka.Application.DTO.User;
using Zdybanka.Application.Services;
using Zdybanka.Core;
using Zdybanka.Data.Repositories;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.UserTests;

public class GetUserTests : UserTest
{
    [Fact]
    public async Task GetAllUsers_Success()
    {
        // Arrange
        
        // Act
        var users = await _service.GetAllUsers();
        
        // Assert
        users.ShouldNotBeEmpty();
        users.ShouldAllBe(u => u.Id != Guid.Empty && !string.IsNullOrWhiteSpace(u.Username));
    }

    [Fact]
    public async Task GetUserById_Success()
    {
        // Arrange
        var username = "username";
        var user = new User()
        {
            Username = username,
            PasswordHash = _passwordHasher.HashPassword("password"),
        };
        var dbUser = _context.Users.Add(user).Entity;
        await _context.SaveChangesAsync();
        
        // Act
        var response = await _service.GetUserById(dbUser.Id);
        
        // Assert
        response.ShouldNotBeNull();
        response.Id.ShouldBe(dbUser.Id);
        response.Username.ShouldBe(username);
    }

    [Fact]
    public async Task GetAllUsers_ReturnsEmptyList_WhenNoUsersExist()
    {
        // Arrange
        var context = ZdybankaContextFactory.Create();
        var service = new UserService(new UserRepository(context), _passwordHasher);
        var users = context.Users.ToList();
        context.Users.RemoveRange(users);
        await context.SaveChangesAsync();
        
        // Act
        var response = await service.GetAllUsers();
        
        // Assert
        response.ShouldNotBeNull();
        response.ShouldBeEmpty();
    }

    [Fact]
    public async Task GetUserById_FailOnNonExistingId()
    {
        // Arrange
        var nonExistingId = Guid.NewGuid();
        // Act
        
        // Assert
        await Assert.ThrowsAsync<KeyNotFoundException>(async () => await _service.GetUserById(nonExistingId));
    }
}