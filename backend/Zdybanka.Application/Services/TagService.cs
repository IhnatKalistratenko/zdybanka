using Zdybanka.Application.DTO.Tag;
using Zdybanka.Core;
using Zdybanka.Data.Repositories;

namespace Zdybanka.Application.Services;

public class TagService
{
    private ITagRepository _repository;

    public TagService(ITagRepository repository)
    {
        _repository = repository;
    }

    public Task<Tag> GetTagByIdAsync(Guid id)
    {
        return _repository.GetTagByIdAsync(id);
    }

    public Task<List<Tag>> GetTagsAsync()
    {
        return _repository.GetTagsAsync();
    }

    public async Task<TagDto> AddTagAsync(TagDto tagDto)
    {
        Tag tag = new Tag()
        {
            Name = tagDto.Name
        };

        tag = await _repository.AddTagAsync(tag);

        await _repository.SaveChangesAsync();

        return new TagDto()
        {
            Id = tag.Id,
            Name = tag.Name
        };
    }

    public async void RemoveTag(Guid id)
    {
        Tag tag = await _repository.GetTagByIdAsync(id);
        _repository.RemoveTag(tag);
        await _repository.SaveChangesAsync();
    }

    public async void UpdateTag(TagDto dto)
    {
        Tag tag = await _repository.GetTagByIdAsync(dto.Id);

        tag.Name = dto.Name;

        _repository.UpdateTag(tag);

        await _repository.SaveChangesAsync();
    }
}
