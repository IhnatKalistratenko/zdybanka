namespace Zdybanka.Application.DTO.User;

public record UpdateUserDto()
{
    public Guid Id { get; set; }
    public string? Username { get; set; }
    public string ConfirmPassword { get; set; } = null!;
    public string? NewPassword { get; set; }
}