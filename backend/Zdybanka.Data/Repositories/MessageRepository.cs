using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Zdybanka.Core.Models;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Data.Repositories;

public class MessageRepository(ZdybankaContext context) : IMessageRepository
{
    private readonly ZdybankaContext _context = context;

    public async Task<Message> AddMessageAsync(Message message)
    {
        message.Sender = await _context.Users
            .FirstAsync(user => user.Id == message.SenderId);
        EntityEntry<Message> entry = await _context.Messages.AddAsync(message);
        return entry.Entity;
    }

    public Task<Message?> GetMessageByIdAsync(Guid id)
    {
        return _context.Messages
            .Include(message => message.Sender)
            .FirstOrDefaultAsync(message => message.Id == id);
    }

    public Task<List<Message>> GetMessagesByChatIdAsync(Guid chatId)
    {
        return _context.Messages
            .Where(message => message.ChatId == chatId)
            .Include(message => message.Sender)
            .OrderBy(message => message.SentAt)
            .ToListAsync();
    }

    public void RemoveMessage(Message message)
    {
        _context.Messages.Remove(message);
    }

    public Message UpdateMessage(Message message)
    {
        return _context.Messages.Update(message).Entity;
    }

    public Task<int> SaveChangesAsync()
    {
        return _context.SaveChangesAsync();
    }
}
