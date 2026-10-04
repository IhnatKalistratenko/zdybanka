using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Zdybanka.Core;

namespace Zdybanka.Data.Repositories;

public class UserRepository : IUserRepository
{
    private ZdybankaContext _context;

    public UserRepository(ZdybankaContext context)
    {
        _context = context;
    }

    public Task<User?> GetUserByIdAsync(Guid id)
    {
        return _context.Users.FirstOrDefaultAsync(u => u.Id == id);
    }

    public Task<List<User>> GetUsersAsync()
    {
        return _context.Users.ToListAsync();
    }

    public async Task<User> AddUserAsync(User user)
    {
        EntityEntry<User> entry = await _context.Users.AddAsync(user);

        return entry.Entity;
    }

    public void RemoveUser(User user)
    {
        _context.Users.Remove(user);
    }

    public User UpdateUser(User user)
    {
        EntityEntry<User> updatedUserEntry = _context.Users.Update(user);

        return updatedUserEntry.Entity;
    }

    public Task<int> SaveChangesAsync()
    {
        return _context.SaveChangesAsync();
    }

    public Task<User?> FindUser(Expression<Func<User, bool>> predicate)
    {
        return _context.Users.FirstOrDefaultAsync(predicate);
    }
}