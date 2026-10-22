
namespace Zdybanka.Core.StorageInterfaces;

public interface IChatRepository
{
    Task<Chat> AddChatAsync(Chat chat);
    Task<Chat?> GetChatByIdAsync(Guid id);
    Task<List<Chat>> GetChatsAsync();
    Task<List<Chat>> GetUserChatsAsync(Guid userId);
    void RemoveChat(Chat chat);
    Task<int> SaveChangesAsync();
    Chat UpdateChat(Chat chat);
}
