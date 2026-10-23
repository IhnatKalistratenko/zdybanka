using System.Text.Json.Serialization;

namespace Zdybanka.Application.DTO.User;

public record UpdateUserRequest()
{
    [JsonIgnore]
    public Guid Id { get; set; }
    public string? Username { get; set; }
    public string? ConfirmPassword { get; set; }
    public string? NewPassword { get; set; }
}