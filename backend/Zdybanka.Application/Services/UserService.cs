using Zdybanka.Application.DTO.User;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;
using Zdybanka.Infrastructure.PasswordHasher;

namespace Zdybanka.Application.Services;

public class UserService(IUserRepository repository, IPasswordHasher hasher)
{
    private readonly IUserRepository _repository = repository;
    private readonly IPasswordHasher _hasher = hasher;

    public async Task<List<UserResponse>> GetAllUsers()
    {
        List<User> domainUsers = await _repository.GetUsersAsync();

        return domainUsers.Select(du => new UserResponse()
        {
            Username = du.Username,
            Id = du.Id
        }).ToList();
    }

    public async Task<UserResponse> GetUserById(Guid id)
    {
        User? user = await _repository.GetUserByIdAsync(id);
        if (user == null)
        {
            throw new KeyNotFoundException("User not found");
        }

        return new UserResponse()
        {
            Id = user.Id,
            Username = user.Username,
        };
    }

    public async Task<UserResponse> CreateUserAsync(CreateUserRequest request)
    {
        if (await _repository.FindUser(u => u.Username == request.Username) != null)
        {
            throw new ArgumentException($"User with username {request.Username} already exists");
        }
        
        User user = new User()
        {
            Username = request.Username,
            PasswordHash = _hasher.HashPassword(request.Password),
        };

        User dbUser = await _repository.AddUserAsync(user);

        await _repository.SaveChangesAsync();
        
        return new UserResponse()
        {
            Id = dbUser.Id,
            Username = dbUser.Username,
        };
    }

    public async Task RemoveUserAsync(Guid id)
    {
        User? user = await _repository.GetUserByIdAsync(id);
        if (user == null)
        {
            throw new KeyNotFoundException("User not found");
        }

        _repository.RemoveUser(user);

        await _repository.SaveChangesAsync();
    }

    public async Task<UserResponse> UpdateUserAsync(UpdateUserRequest request)
    {
        User? user = await _repository.GetUserByIdAsync(request.Id);
        if (user == null)
        {
            throw new KeyNotFoundException();
        }

        if (await _repository.FindUser(u => u.Username == request.Username) != null)
        {
            throw new ArgumentException("Username already exists");
        }

        if (!_hasher.VerifyPassword(request.ConfirmPassword, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Wrong password");
        }

        if (request.Username != null)
        {
            user.Username = request.Username;
        }

        if (request.NewPassword != null)
        {
            user.PasswordHash = _hasher.HashPassword(request.NewPassword);
        }

        User updatedUser = _repository.UpdateUser(user);
        await _repository.SaveChangesAsync();

        return new UserResponse()
        {
            Id = updatedUser.Id,
            Username = updatedUser.Username
        };
    }
}