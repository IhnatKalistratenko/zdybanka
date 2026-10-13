using Zdybanka.Application.DTO.Chat;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Application.Services;

public class ChatService(IChatRepository repository)
{
    private readonly IChatRepository _repository = repository;

    public async Task<ChatResponse> CreateChat(CreateChatDto dto)
    {
        Chat newChat = new Chat()
        {
            Name = dto.Name,
            Description = dto.Description,
            Status = dto.Status,
            EventId = dto.EventId
        };
        
        await _repository.AddChatAsync(newChat);

        return new ChatResponse(newChat);
    }

    public async Task<List<ChatResponse>> GetAllChats()
    {
        List<Chat> chats = await _repository.GetChatsAsync();

        return chats.Select(chat => new ChatResponse(chat)).ToList();
    }

    public async Task<ChatResponse> GetChatById(Guid id)
    {
        Chat? dbChat = await _repository.GetChatByIdAsync(id);
        if (dbChat == null)
        {
            throw new KeyNotFoundException($"Chat with id {id} not found");
        }
        
        return new ChatResponse(dbChat);
    }

    public async Task<List<ChatResponse>> GetUserChatsAsync(Guid userId)
    {
        List<Chat> chats = await _repository.GetUserChatsAsync(userId);
        return chats.Select(chat => new ChatResponse(chat)).ToList();
    }

    public async Task<ChatResponse> UpdateChat(Guid id, UpdateChatDto dto)
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

        if (dto.Status != null)
        {
             dbChat.Status = Enum.Parse<ChatStatus>(dto.Status, true);
        }
        
        _repository.UpdateChat(dbChat);
        await _repository.SaveChangesAsync();

        return new ChatResponse(dbChat);
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
}