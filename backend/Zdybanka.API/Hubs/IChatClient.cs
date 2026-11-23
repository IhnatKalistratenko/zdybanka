using Zdybanka.Application.DTO.Message;

namespace Zdybanka.API.Hubs;

public interface IChatClient
{
    Task ReceiveMessage(MessageResponse message);
}