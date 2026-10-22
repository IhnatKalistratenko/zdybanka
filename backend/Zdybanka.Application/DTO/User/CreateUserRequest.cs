namespace Zdybanka.Application.DTO.User;

public record CreateUserRequest
{
    public required string Username { get; set; }
    public required string Password { get; set; }
}