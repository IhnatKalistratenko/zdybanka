namespace Zdybanka.Application.DTO.Message;

public record CreateMessageRequest
{
    public Guid ChatId { get; init; }
    public Guid SenderId { get; init; }
    public string Content { get; init; } = string.Empty;
}
