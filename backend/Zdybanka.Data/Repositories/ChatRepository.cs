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
        return ChatsWithLastMessage().ToListAsync();
    }

    public Task<Chat?> GetChatByIdAsync(Guid id)
    {
        return _context.Chats
            .Include(chat => chat.UserChats)
            .Include(chat => chat.Messages.OrderByDescending(message => message.SentAt))
            .ThenInclude(message => message.Sender)
            .FirstOrDefaultAsync(ch => ch.Id == id);
    }

    public Task<List<Chat>> GetUserChatsAsync(Guid userId)
    {
        return _context.UserChats
            .Where(userChat => userChat.UserId == userId)
            .Include(userChat => userChat.Chat)
            .ThenInclude(chat => chat.Messages
                .OrderByDescending(message => message.SentAt)
                .Take(1))
            .ThenInclude(message => message.Sender)
            .Select(userChat => userChat.Chat)
            .ToListAsync();
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

    public Task<Chat?> GetChatByEventIdAsync(Guid eventId)
    {
        return ChatsWithLastMessage().FirstOrDefaultAsync(ch => ch.EventId == eventId);
    }

    public Task AddUserToChatAsync(UserChat userChat)
    {
        _context.UserChats.AddAsync(userChat);
        return Task.CompletedTask;
    }

    public Task<bool> IsUserMemberOfChat(Guid chatId, Guid userId)
    {
        return _context.UserChats.AnyAsync(uc => uc.ChatId == chatId && uc.UserId == userId);
    }

    public Task<int> SaveChangesAsync()
    {
        return _context.SaveChangesAsync();
    }

    private IQueryable<Chat> ChatsWithLastMessage()
    {
        return _context.Chats
            .Include(chat => chat.Messages.OrderByDescending(message => message.SentAt).Take(1))
            .ThenInclude(message => message.Sender);
    }
}
