namespace Zdybanka.Application.DTO.User;

public record UserResponse
{
    public Guid Id { get; set; }
    public required string Username { get; set; }
}