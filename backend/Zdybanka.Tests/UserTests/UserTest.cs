using Zdybanka.Application.Services;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.UserTests;

public abstract class UserTest : ZdybankaTest
{
    protected readonly UserService Service;
    protected readonly IPasswordHasher PasswordHasher;

    protected UserTest() : base()
    {
        PasswordHasher = new BcryptPasswordHasher();
        Service = new UserService(new UserRepository(_context), PasswordHasher);
    }
}