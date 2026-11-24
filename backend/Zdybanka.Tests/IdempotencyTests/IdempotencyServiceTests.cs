using Microsoft.EntityFrameworkCore;
using Zdybanka.Core;
using Zdybanka.Core.Models;
using Zdybanka.Data;
using Zdybanka.Tests.Common;
using Zdybanka.Application.Services;

namespace Zdybanka.Tests.IdempotencyTests;

public class IdempotencyServiceTests : IDisposable
{
    private readonly ZdybankaContext _context = ZdybankaContextFactory.Create();

    [Fact]
    public async Task NewKeyHasNoSavedResponse()
    {
        var service = new IdempotencyService(_context);

        Assert.Null(await service.GetResponseAsync(Guid.NewGuid().ToString()));
    }

    [Fact]
    public async Task ExistingKeyReturnsStoredResponseRegardlessOfIncomingRequest()
    {
        var service = new IdempotencyService(_context);
        var key = Guid.NewGuid().ToString();
        const string firstResponse = "{\"created\":true}";

        await service.SaveResponseAsync(key, firstResponse);

        // The service accepts only the key, so a repeated request's body is never
        // consulted; callers receive the first operation's saved response.
        Assert.Equal(firstResponse, await service.GetResponseAsync(key));
    }

    [Fact]
    public async Task SequentialReplayDoesNotCreateSecondEntity()
    {
        var service = new IdempotencyService(_context);
        var key = Guid.NewGuid().ToString();
        var previousResponse = await service.GetResponseAsync(key);
        if (previousResponse is null)
        {
            _context.Users.Add(new User { Username = "idempotent-user", PasswordHash = "hash" });
            await _context.SaveChangesAsync();
            await service.SaveResponseAsync(key, "{\"created\":true}");
        }

        previousResponse = await service.GetResponseAsync(key);
        if (previousResponse is null)
        {
            _context.Users.Add(new User { Username = "idempotent-user-2", PasswordHash = "hash" });
            await _context.SaveChangesAsync();
        }

        Assert.Equal(1, await _context.Users.CountAsync(user => user.Username.StartsWith("idempotent-user")));
    }

    public void Dispose() => ZdybankaContextFactory.Delete(_context);
}
