using System.Linq.Expressions;

namespace Zdybanka.Core.StorageInterfaces;

public interface ITagRepository
{
    Task<Tag> AddTagAsync(Tag tag);
    Task<Tag?> GetTagByIdAsync(Guid id);
    Task<List<Tag>> GetTagsAsync();
    void RemoveTag(Tag tag);
    Task<int> SaveChangesAsync();
    Tag UpdateTag(Tag tag);
    Task<Tag?> FindTagAsync(Expression<Func<Tag, bool>> predicate);
}
