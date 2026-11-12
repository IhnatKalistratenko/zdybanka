namespace Zdybanka.Application.DTO.Message;

public record MessageResponse
{
    public MessageResponse(Core.Models.Message message, Guid requesterId = default)
    {
        Id = message.Id;
        ChatId = message.ChatId;
        SenderId = message.SenderId;
        SenderName = message.Sender.Username;
        Content = message.Content;
        SentAt = message.SentAt;
        IsOwner = requesterId != Guid.Empty && message.SenderId == requesterId;
    }

    public Guid Id { get; init; }
    public Guid ChatId { get; init; }
    public Guid SenderId { get; init; }
    public string SenderName { get; init; } = string.Empty;
    public string Content { get; init; } = string.Empty;
    public DateTime SentAt { get; init; }
    public bool IsOwner { get; init; }
}
