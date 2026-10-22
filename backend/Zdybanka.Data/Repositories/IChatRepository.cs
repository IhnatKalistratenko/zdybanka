using Microsoft.EntityFrameworkCore.ChangeTracking;
using Zdybanka.Core;

namespace Zdybanka.Data.Repositories;

public interface IChatRepository
{
    ValueTask<EntityEntry<Chat>> AddChatAsync(Chat chat);
    Task<Chat?> GetChatByIdAsync(Guid id);
    Task<List<Chat>> GetChatsAsync();
    Task<List<Chat>> GetUserChatsAsync(Guid userId);
    EntityEntry<Chat> RemoveChat(Chat chat);
    Task<int> SaveChangesAsync();
    EntityEntry<Chat> UpdateChat(Chat chat);
}
