namespace Zdybanka.Application.Services;

public record UserDto
{
    public string? Email { get; set; }
    public string Username { get; set; } = null!;
    public string Password { get; set; } = null!;
}