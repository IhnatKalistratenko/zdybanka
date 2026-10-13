namespace Zdybanka.Application.DTO.Chat;

public record UpdateChatDto
{
    public string? Name { get; set; }
    public string? Description { get; set; }
    public string? Status { get; set; }
}