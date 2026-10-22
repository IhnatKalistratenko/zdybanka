using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Data.Repositories;

public class TagRepository(ZdybankaContext context) : ITagRepository
{
    private ZdybankaContext _context = context;

    public Task<List<Tag>> GetTagsAsync()
    {
        return _context.Tags.ToListAsync();
    }

    public Task<Tag?> GetTagByIdAsync(Guid id)
    {
        return _context.Tags.FirstOrDefaultAsync(t => t.Id == id);
    }

    public async Task<Tag> AddTagAsync(Tag tag)
    {
        EntityEntry<Tag> entry = await _context.Tags.AddAsync(tag);

        return entry.Entity;
    }

    public void RemoveTag(Tag tag)
    {
        _context.Tags.Remove(tag);
    }

    public Tag UpdateTag(Tag tag)
    {
        return _context.Tags.Update(tag).Entity;
    }

    public Task<Tag?> FindTagAsync(Expression<Func<Tag, bool>> predicate)
    {
        return _context.Tags.FirstOrDefaultAsync(predicate);
    }

    public Task<int> SaveChangesAsync()
    {
        return _context.SaveChangesAsync();
    }
    
    

}