using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Data.Repositories;

public class ChatRepository(ZdybankaContext context) : IChatRepository
{
    private ZdybankaContext _context = context;

    public Task<List<Chat>> GetChatsAsync()
    {
        return _context.Chats.ToListAsync();
    }

    public Task<Chat?> GetChatByIdAsync(Guid id)
    {
        return _context.Chats.FirstOrDefaultAsync(ch => ch.Id == id);
    }

    public Task<List<Chat>> GetUserChatsAsync(Guid userId)
    {
        return _context.UserChats.Where(ch => ch.UserId == userId).Select(userChat => userChat.Chat).ToListAsync();
    }

    public async Task<Chat> AddChatAsync(Chat chat)
    {
        return (await _context.Chats.AddAsync(chat)).Entity;
    }

    public void RemoveChat(Chat chat)
    {
        _context.Chats.Remove(chat);
    }

    public Chat UpdateChat(Chat chat)
    {
        return _context.Chats.Update(chat).Entity;
    }

    public Task<int> SaveChangesAsync()
    {
        return _context.SaveChangesAsync();
    }
}