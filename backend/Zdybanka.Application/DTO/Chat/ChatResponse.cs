using Zdybanka.Core;

namespace Zdybanka.Application.DTO.Chat;

public record ChatResponse
{
    public ChatResponse()
    {
    }

    public ChatResponse(Core.Chat domainChat)
    {
        Id = domainChat.Id;
        Name = domainChat.Name;
        Description = domainChat.Description;
        EventId = domainChat.EventId;
        Status = domainChat.Status.ToString();
    }
    
    public Guid Id { get; set; }
    public Guid EventId { get; set; }
    public string Name { get; set; } = null!;
    public string Description { get; set; } = null!;
    public string Status { get; set; } = null!;
}