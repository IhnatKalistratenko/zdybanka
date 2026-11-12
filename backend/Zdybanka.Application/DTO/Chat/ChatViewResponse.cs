using Zdybanka.Application.DTO.Message;
using Zdybanka.Core;

namespace Zdybanka.Application.DTO.Chat;

public record ChatViewResponse
{
    public ChatViewResponse()
    {
    }

    public ChatViewResponse(Core.Chat domainChat)
    {
        Id = domainChat.Id;
        Name = domainChat.Name;
        var lastMessage = domainChat.Messages
            .OrderByDescending(message => message.SentAt)
            .FirstOrDefault();
        LastMessage = lastMessage is null ? null : new MessageResponse(lastMessage);
    }
    
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public MessageResponse? LastMessage { get; set; }
}
