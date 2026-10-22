using Microsoft.EntityFrameworkCore;
using Zdybanka.Core;
using Zdybanka.Data;
using Zdybanka.Infrastructure.PasswordHasher;

namespace Zdybanka.Tests.Common;

public class ZdybankaContextFactory
{
    public const string Username1 = "user1";
    public const string UserPassword1 = "user1";
    
    public const string Username2 = "user2";
    public const string UserPassword2 = "user2";
    
    public const string Username3 = "user3";
    public const string UserPassword3 = "user3";

    public static ZdybankaContext Create()
    {
        var options = new DbContextOptionsBuilder<ZdybankaContext>().UseInMemoryDatabase(Guid.NewGuid().ToString()).Options;

        var context = new ZdybankaContext(options);
        
        context.Database.EnsureCreated();
        
        FillWithUsers(context);

        return context;
    }

    public static void Delete(ZdybankaContext context)
    {
        context.Database.EnsureDeleted();
        context.Dispose();
    }

    private static void FillWithUsers(ZdybankaContext context)
    {
        var hasher = new BcryptPasswordHasher();
        context.Users.AddRange(
            [
                new User()
                {
                    Username = Username1,
                    PasswordHash = hasher.HashPassword(UserPassword1),
                },
                new User()
                {
                    Username = Username2,
                    PasswordHash = hasher.HashPassword(UserPassword2),
                },
                new User()
                {
                    Username = Username3,
                    PasswordHash = hasher.HashPassword(UserPassword3),
                },
            ]
            );

        context.SaveChanges();
    }
}