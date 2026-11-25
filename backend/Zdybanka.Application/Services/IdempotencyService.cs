using Microsoft.EntityFrameworkCore;
using Zdybanka.Core.Models;
using Zdybanka.Data;

namespace Zdybanka.Application.Services;

public class IdempotencyService(ZdybankaContext context)
{
    public Task<string?> GetResponseAsync(string key) => context.IdempotencyKeys
        .Where(entry => entry.Key == key)
        .Select(entry => entry.ResponseBody)
        .FirstOrDefaultAsync();

    public async Task SaveResponseAsync(string key, string responseBody)
    {
        context.IdempotencyKeys.Add(new IdempotencyKey
        {
            Key = key,
            ResponseBody = responseBody,
            CreatedAt = DateTime.UtcNow
        });

        await context.SaveChangesAsync();
    }
}
