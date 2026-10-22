using Zdybanka.Application.Services;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.UserTests;

public abstract class UserTest : ZdybankaTest
{
    protected readonly UserService _service;
    protected readonly IPasswordHasher _passwordHasher;

    public UserTest() : base()
    {
        _passwordHasher = new BcryptPasswordHasher();
        _service = new UserService(new UserRepository(_context), _passwordHasher);
    }
}