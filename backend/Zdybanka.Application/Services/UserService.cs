using Zdybanka.Application.DTO.User;
using Zdybanka.Core;
using Zdybanka.Data.Repositories;
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

    public async Task<UserResponse> CreateUser(CreateUserDto dto)
    {
        if (await _repository.FindUser(u => u.Username == dto.Username) != null)
        {
            throw new ArgumentException($"User with username {dto.Username} already exists");
        }
        
        User user = new User()
        {
            Username = dto.Username,
            PasswordHash = _hasher.HashPassword(dto.Password),
        };

        User dbUser = await _repository.AddUserAsync(user);

        await _repository.SaveChangesAsync();
        
        return new UserResponse()
        {
            Id = dbUser.Id,
            Username = dbUser.Username,
        };
    }

    public async Task RemoveUser(Guid id)
    {
        User? user = await _repository.GetUserByIdAsync(id);
        if (user == null)
        {
            throw new ArgumentException("User not found");
        }

        _repository.RemoveUser(user);

        await _repository.SaveChangesAsync();
    }

    public async Task<UserResponse> UpdateUser(UpdateUserDto dto)
    {
        User? user = await _repository.GetUserByIdAsync(dto.Id);
        if (user == null)
        {
            throw new KeyNotFoundException();
        }

        if (await _repository.FindUser(u => u.Username == dto.Username) != null)
        {
            throw new ArgumentException("Username already exists");
        }

        if (!_hasher.VerifyPassword(dto.ConfirmPassword, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Wrong password");
        }

        if (dto.Username != null)
        {
            user.Username = dto.Username;
        }

        if (dto.NewPassword != null)
        {
            user.PasswordHash = _hasher.HashPassword(dto.NewPassword);
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