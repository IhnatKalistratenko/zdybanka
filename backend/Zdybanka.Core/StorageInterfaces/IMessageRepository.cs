using Zdybanka.Core.Models;

namespace Zdybanka.Core.StorageInterfaces;

public interface IMessageRepository
{
    Task<Message> AddMessageAsync(Message message);
    Task<Message?> GetMessageByIdAsync(Guid id);
    Task<List<Message>> GetMessagesByChatIdAsync(Guid chatId);
    void RemoveMessage(Message message);
    Message UpdateMessage(Message message);
    Task<int> SaveChangesAsync();
}
