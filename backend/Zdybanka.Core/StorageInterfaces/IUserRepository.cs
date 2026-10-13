using System.Linq.Expressions;

namespace Zdybanka.Core.StorageInterfaces;

public interface IUserRepository
{
    Task<User> AddUserAsync(User user);
    void RemoveUser(User user);
    Task<User?> GetUserByIdAsync(Guid id);
    Task<List<User>> GetUsersAsync();
    User UpdateUser(User user);
    Task<int> SaveChangesAsync();
    Task<User?> FindUser(Expression<Func<User, bool>> predicate);
}
