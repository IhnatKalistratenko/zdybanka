using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Caching.Memory;
using Newtonsoft.Json;
using Zdybanka.Application.DTO.Message;
using Zdybanka.Application.Services;

namespace Zdybanka.API.Hubs;

[Authorize]
public class ChatHub(ChatService chatService, MessageService messageService) : Hub<IChatClient>
{
    private readonly ChatService _chatService = chatService;
    private readonly MessageService _messageService = messageService;

    private async Task<Guid> CheckForAuthorize(Guid chatId)
    {
        if (!Guid.TryParse(Context.UserIdentifier, out Guid userId))
        {
            throw new HubException("User is not a valid user identifier.");
        }

        var isMember = await _chatService.IsUserMemberOfChat(chatId, userId);
        if (!isMember)
        {
            throw new HubException("User is not a member of this chat.");
        }

        return userId;
    }
    public async Task JoinChat(Guid chatId)
    {
        await CheckForAuthorize(chatId);
        
        await Groups.AddToGroupAsync(Context.ConnectionId, GetGroupName(chatId));
    }

    public async Task LeaveChat(Guid chatId)
    {
        await CheckForAuthorize(chatId);
        
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, GetGroupName(chatId));
    }

    public async Task SendMessage(Guid chatId, string content)
    {
        var userId = await CheckForAuthorize(chatId);

        var message = new CreateMessageRequest()
        {
            ChatId = chatId,
            SenderId = userId,
            Content = content
        };

        var response = await _messageService.CreateMessageAsync(message);

        await Clients.Group(GetGroupName(chatId)).ReceiveMessage(response);
    }

    private String GetGroupName(Guid chatId) => $"chat:{chatId.ToString()}";
}