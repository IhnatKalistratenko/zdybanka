using Zdybanka.Application.DTO.Tag;
using Zdybanka.Core;

namespace Zdybanka.Tests.TagTests;

public class GetTagTests : TagTest
{
    [Fact]
    public async Task GetAllTags()
    {
        // Arrange
        Tag tag1 = new()
        {
            Name = "Programming"
        };

        Tag tag2 = new()
        {
            Name = "Music"
        };

        Tag tag3 = new()
        {
            Name = "Sport"
        };

        await _context.Tags.AddRangeAsync(tag1, tag2, tag3);
        await _context.SaveChangesAsync();

        // Act
        List<TagResponse> response = await TagService.GetTagsAsync();

        // Assert
        Assert.Equal(3, response.Count);

        foreach (var expected in new[] { tag1, tag2, tag3 })
        {
            var actual = Assert.Single(response, t => t.Id == expected.Id);

            Assert.Equal(expected.Name, actual.Name);
        }
    }

    [Fact]
    public async Task GetTagById_Success()
    {
        // Arrange
        Tag tag = new()
        {
            Name = "Programming"
        };

        await _context.Tags.AddAsync(tag);
        await _context.SaveChangesAsync();

        // Act
        TagResponse response = await TagService.GetTagByIdAsync(tag.Id);

        // Assert
        Assert.Equal(tag.Id, response.Id);
        Assert.Equal(tag.Name, response.Name);
    }
    
    [Fact]
    public async Task GetTagById_Fail_OnNotFound()
    {
        // Arrange
        Guid nonExistingId = Guid.NewGuid();

        // Act & Assert
        await Assert.ThrowsAsync<KeyNotFoundException>(
            () => TagService.GetTagByIdAsync(nonExistingId)
        );
    }
}