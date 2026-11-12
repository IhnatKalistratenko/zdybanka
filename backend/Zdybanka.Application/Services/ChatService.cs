using Zdybanka.Application.DTO.Chat;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Application.Services;

public class ChatService(IChatRepository repository)
{
    private readonly IChatRepository _repository = repository;

    public async Task<ChatViewResponse> CreateChat(CreateChatDto dto)
    {
        Chat newChat = new Chat()
        {
            Name = dto.Name,
            Description = dto.Description,
            Status = dto.Status,
            EventId = dto.EventId
        };
        
        await _repository.AddChatAsync(newChat);

        await _repository.SaveChangesAsync();

        return new ChatViewResponse(newChat);
    }

    public async Task<List<ChatViewResponse>> GetAllChats()
    {
        List<Chat> chats = await _repository.GetChatsAsync();

        return chats.Select(chat => new ChatViewResponse(chat)).ToList();
    }

    public async Task<ExtendedChatResponse> GetChatById(Guid id, Guid requesterId)
    {
        Chat? dbChat = await _repository.GetChatByIdAsync(id);
        if (dbChat == null)
        {
            throw new KeyNotFoundException($"Chat with id {id} not found");
        }
        
        return new ExtendedChatResponse(dbChat, requesterId);
    }

    public Task<bool> IsUserMemberOfChat(Guid chatId, Guid userId)
    {
        return _repository.IsUserMemberOfChat(chatId, userId);
    }

    public async Task<List<ChatViewResponse>> GetUserChatsAsync(Guid userId)
    {
        List<Chat> chats = await _repository.GetUserChatsAsync(userId);
        return chats.Select(chat => new ChatViewResponse(chat)).ToList();
    }

    public async Task<ChatViewResponse> UpdateChat(Guid id, UpdateChatDto dto)
    {
        Chat? dbChat = await _repository.GetChatByIdAsync(id);
        if (dbChat == null)
        {
            throw new KeyNotFoundException($"Chat with id {id} not found");
        }

        if (dto.Name != null)
        {
            dbChat.Name = dto.Name;
        }

        if (dto.Description != null)
        {
            dbChat.Description = dto.Description;
        }
        
        _repository.UpdateChat(dbChat);
        await _repository.SaveChangesAsync();

        return new ChatViewResponse(dbChat);
    }

    public async Task DeleteChat(Guid id)
    {
        Chat? dbChat = await _repository.GetChatByIdAsync(id);
        if (dbChat == null)
        {
            throw new KeyNotFoundException($"Chat with id {id} not found");
        }
        
        _repository.RemoveChat(dbChat);
        await _repository.SaveChangesAsync();
    }

    public async Task AddUserToChatAsync(Guid chatId, Guid userId)
    {
        Chat? dbChat = await _repository.GetChatByIdAsync(chatId);
        if (dbChat == null)
        {
            throw new KeyNotFoundException();
        }

        var newUserChat = new UserChat()
        {
            UserId = userId,
            ChatId = chatId,
            JoinedAt = DateTime.UtcNow
        };

        await _repository.AddUserToChatAsync(newUserChat);

        await _repository.SaveChangesAsync();
    }

    public async Task<ChatViewResponse> GetChatByEventIdAsync(Guid eventId)
    {
        var chat = await _repository.GetChatByEventIdAsync(eventId);
        if (chat == null)
        {
            throw new KeyNotFoundException();
        }

        return new ChatViewResponse()
        {
            Id = chat.Id,
            Name = chat.Name,
        };
    }

    public async Task DeleteUserFromChatAsync(Guid chatId, Guid userId)
    {
        var chat = await _repository.GetChatByIdAsync(chatId);
        if (chat == null)
        {
            throw new KeyNotFoundException();
        }
        
        chat.UserChats.Remove(chat.UserChats.First(e => e.UserId == userId));
        
        _repository.UpdateChat(chat);
        await _repository.SaveChangesAsync();
    }
}