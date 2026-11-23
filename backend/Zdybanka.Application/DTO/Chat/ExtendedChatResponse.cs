using Zdybanka.Application.DTO.Message;

namespace Zdybanka.Application.DTO.Chat;

public class ExtendedChatResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }
    public List<MessageResponse> Messages { get; set; }

    public ExtendedChatResponse(Core.Chat chat, Guid requesterId)
    {
        Id = chat.Id;
        Name = chat.Name;
        Description = chat.Description;
        Messages = chat.Messages.Select(m => new MessageResponse(m, requesterId)).ToList();
    }
}