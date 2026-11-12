using Zdybanka.Application.DTO.Message;
using Zdybanka.Core.Models;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Application.Services;

public class MessageService(IMessageRepository repository)
{
    private readonly IMessageRepository _repository = repository;

    public async Task<MessageResponse> CreateMessageAsync(CreateMessageRequest request)
    {
        ValidateMessageData(request.ChatId, request.SenderId, request.Content);

        var message = new Message
        {
            ChatId = request.ChatId,
            SenderId = request.SenderId,
            Content = request.Content.Trim(),
            SentAt = DateTime.UtcNow,
        };

        await _repository.AddMessageAsync(message);
        await _repository.SaveChangesAsync();
        return new MessageResponse(message, request.SenderId);
    }

    public async Task<MessageResponse> GetMessageByIdAsync(Guid id, Guid requesterId)
    {
        if (id == Guid.Empty)
        {
            throw new ArgumentException("Message id cannot be empty.", nameof(id));
        }

        var message = await _repository.GetMessageByIdAsync(id);
        if (message is null)
        {
            throw new KeyNotFoundException($"Message with id {id} was not found.");
        }

        return new MessageResponse(message, requesterId);
    }

    public async Task<List<MessageResponse>> GetMessagesByChatIdAsync(Guid chatId, Guid requesterId)
    {
        if (chatId == Guid.Empty)
        {
            throw new ArgumentException("Chat id cannot be empty.", nameof(chatId));
        }

        var messages = await _repository.GetMessagesByChatIdAsync(chatId);
        return messages.Select(message => new MessageResponse(message, requesterId)).ToList();
    }

    public async Task<MessageResponse> UpdateMessageAsync(Guid id, string content, Guid requesterId)
    {
        if (id == Guid.Empty)
        {
            throw new ArgumentException("Message id cannot be empty.", nameof(id));
        }
        ValidateContent(content);

        var message = await _repository.GetMessageByIdAsync(id);
        if (message is null)
        {
            throw new KeyNotFoundException($"Message with id {id} was not found.");
        }

        message.Content = content.Trim();
        _repository.UpdateMessage(message);
        await _repository.SaveChangesAsync();
        return new MessageResponse(message, requesterId);
    }

    public async Task DeleteMessageAsync(Guid id)
    {
        if (id == Guid.Empty)
        {
            throw new ArgumentException("Message id cannot be empty.", nameof(id));
        }

        var message = await _repository.GetMessageByIdAsync(id);
        if (message is null)
        {
            throw new KeyNotFoundException($"Message with id {id} was not found.");
        }

        _repository.RemoveMessage(message);
        await _repository.SaveChangesAsync();
    }

    private static void ValidateMessageData(Guid chatId, Guid senderId, string? content)
    {
        if (chatId == Guid.Empty)
        {
            throw new ArgumentException("Chat id cannot be empty.", nameof(chatId));
        }
        if (senderId == Guid.Empty)
        {
            throw new ArgumentException("Sender id cannot be empty.", nameof(senderId));
        }
        ValidateContent(content);
    }

    private static void ValidateContent(string? content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new ArgumentException("Message content cannot be empty.", nameof(content));
        }
    }
}
