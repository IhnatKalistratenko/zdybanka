using Zdybanka.Core;

namespace Zdybanka.Application.DTO.Chat;

public record CreateChatDto()
{
    public Guid EventId { get; set; }
    public string Name { get; set; } = null!;
    public string Description { get; set; } = null!;
    public ChatStatus Status { get; set; }
    public List<Guid> ParticipantsIds { get; set; } = new List<Guid>();
}