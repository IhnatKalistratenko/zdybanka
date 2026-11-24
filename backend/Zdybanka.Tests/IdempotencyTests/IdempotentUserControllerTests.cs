using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Zdybanka.API.Controllers;
using Zdybanka.Application.DTO.User;
using Zdybanka.Application.Services;
using Zdybanka.Data;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.IdempotencyTests;

public class IdempotentUserControllerTests : IDisposable
{
    private readonly ZdybankaContext _context = ZdybankaContextFactory.Create();

    [Fact]
    public async Task MissingKeyReturnsBadRequest()
    {
        var controller = CreateController();
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = CreateHttpContext(null)
        };

        var result = await controller.CreateUser(new CreateUserRequest
        {
            Username = "idempotency-missing-key",
            Password = "password"
        });

        var invalidKeyController = CreateController();
        invalidKeyController.ControllerContext = new ControllerContext
        {
            HttpContext = CreateHttpContext("not-a-guid")
        };
        var invalidKeyResult = await invalidKeyController.CreateUser(new CreateUserRequest
        {
            Username = "idempotency-invalid-key",
            Password = "password"
        });

        Assert.IsType<BadRequestObjectResult>(result);
        Assert.IsType<BadRequestObjectResult>(invalidKeyResult);
        Assert.False(await _context.Users.AnyAsync(user => user.Username == "idempotency-missing-key"));
        Assert.False(await _context.Users.AnyAsync(user => user.Username == "idempotency-invalid-key"));
    }

    [Fact]
    public async Task SameKeyReplaysFirstResponseEvenIfBodyChanges_AndNewKeyRunsAgain()
    {
        var key = Guid.NewGuid().ToString();
        var firstController = CreateController();
        firstController.ControllerContext = new ControllerContext
        {
            HttpContext = CreateHttpContext(key)
        };
        var first = await firstController.CreateUser(new CreateUserRequest
        {
            Username = "idempotency-first",
            Password = "password"
        });

        var replayController = CreateController();
        replayController.ControllerContext = new ControllerContext
        {
            HttpContext = CreateHttpContext(key)
        };
        var replay = await replayController.CreateUser(new CreateUserRequest
        {
            Username = "idempotency-different-body",
            Password = "different-password"
        });

        Assert.IsType<CreatedAtActionResult>(first);
        var firstBody = System.Text.Json.JsonSerializer.Serialize(
            ((CreatedAtActionResult)first).Value,
            new System.Text.Json.JsonSerializerOptions(System.Text.Json.JsonSerializerDefaults.Web));
        var replayResult = Assert.IsType<ContentResult>(replay);
        Assert.Equal(StatusCodes.Status201Created, replayResult.StatusCode);
        Assert.Equal(firstBody, replayResult.Content);
        Assert.False(await _context.Users.AnyAsync(user => user.Username == "idempotency-different-body"));

        var newKeyController = CreateController();
        newKeyController.ControllerContext = new ControllerContext
        {
            HttpContext = CreateHttpContext(Guid.NewGuid().ToString())
        };
        await newKeyController.CreateUser(new CreateUserRequest
        {
            Username = "idempotency-new-key",
            Password = "password"
        });
        Assert.True(await _context.Users.AnyAsync(user => user.Username == "idempotency-new-key"));
        Assert.Equal(2, await _context.IdempotencyKeys.CountAsync());
    }

    private UserController CreateController() => new(
        new UserService(new UserRepository(_context), new BcryptPasswordHasher()),
        null!,
        new IdempotencyService(_context));

    private static DefaultHttpContext CreateHttpContext(string? key)
    {
        var context = new DefaultHttpContext();
        if (key is not null) context.Request.Headers["Idempotency-Key"] = key;
        context.TraceIdentifier = Guid.NewGuid().ToString();
        return context;
    }

    public void Dispose() => ZdybankaContextFactory.Delete(_context);
}
