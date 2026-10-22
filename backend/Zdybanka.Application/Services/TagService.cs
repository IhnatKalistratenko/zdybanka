using Zdybanka.Application.DTO.Tag;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Application.Services;

public class TagService
{
    private ITagRepository _repository;

    public TagService(ITagRepository repository)
    {
        _repository = repository;
    }

    public async Task<TagResponse> GetTagByIdAsync(Guid id)
    {
        Tag? dbTag = await _repository.GetTagByIdAsync(id);
        if (dbTag == null)
        {
            throw new KeyNotFoundException("Tag not found");
        }
        
        return new TagResponse()
        {
            Id = dbTag.Id,
            Name = dbTag.Name
        };
    }

    public async Task<List<TagResponse>> GetTagsAsync()
    {
        List<Tag> tags =  await _repository.GetTagsAsync();
        return tags.Select(t => new TagResponse()
        {
            Id = t.Id,
            Name = t.Name
        }).ToList();
    }

    public async Task<TagResponse> AddTagAsync(string name)
    {
        if ((await _repository.FindTagAsync(t => t.Name == name)) != null)
        {
            throw new ArgumentException($"Tag \"{name}\" already exists");
        }
        
        Tag tag = new Tag()
        {
            Name = name
        };

        tag = await _repository.AddTagAsync(tag);

        await _repository.SaveChangesAsync();

        return new TagResponse()
        {
            Id = tag.Id,
            Name = tag.Name
        };
    }

    public async Task RemoveTag(Guid id)
    {
        Tag? tag = await _repository.GetTagByIdAsync(id);
        if (tag == null)
        {
            throw new KeyNotFoundException("Tag not found");
        }
        
        _repository.RemoveTag(tag);
        await _repository.SaveChangesAsync();
    }

    public async Task<TagResponse> UpdateTag(Guid id, string newName)
    {
        Tag? tag = await _repository.GetTagByIdAsync(id);
        if (tag == null)
        {
            throw new KeyNotFoundException("Tag not found");
        }

        if (await _repository.FindTagAsync(t => t.Name == newName) != null)
        {
            throw new ArgumentException($"Tag with name {newName} already exists");
        }

        tag.Name = newName;

        _repository.UpdateTag(tag);

        await _repository.SaveChangesAsync();

        return new TagResponse()
        {
            Id = tag.Id,
            Name = tag.Name
        };
    }
}
