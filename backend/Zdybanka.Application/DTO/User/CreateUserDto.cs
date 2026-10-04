namespace Zdybanka.Application.DTO.User;

public record CreateUserDto
{
    public string Username { get; set; }
    public string Password { get; set; }
}