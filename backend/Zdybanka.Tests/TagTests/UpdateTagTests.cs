using Microsoft.EntityFrameworkCore;
using Zdybanka.Core;

namespace Zdybanka.Tests.TagTests;

public class UpdateTagTests : TagTest
{
    [Fact]
    public async Task UpdateTag_Success()
    {
        // Arrange
        
        string oldName = "tagTest";
        string newName = "newName";
        Tag tag = new Tag()
        {
            Name = oldName,
        };
        await _context.Tags.AddAsync(tag);
        await _context.SaveChangesAsync();
        
        // Act
        await TagService.UpdateTag(tag.Id, newName);
        
        // Assert
        Tag? updatedTag =  await _context.Tags.FindAsync(tag.Id);
        Assert.NotNull(updatedTag);
        Assert.Equal(newName, updatedTag.Name);
        Assert.Null(await _context.Tags.FirstOrDefaultAsync(t => t.Name == oldName));
    }

    [Fact]
    public async Task UpdateTag_Fail_OnExistingName()
    {
        // Arrange
        string existingName = "existingName";
        string testTag =  "testTag";
        Tag tag1 = new Tag()
        {
            Name = existingName
        };
        Tag tag2 = new Tag()
        {
            Name = testTag
        };
        await _context.Tags.AddAsync(tag1);
        await _context.Tags.AddAsync(tag2);
        await _context.SaveChangesAsync();
        // Act
        
        // Assert
        await Assert.ThrowsAnyAsync<ArgumentException>(async () => await TagService.UpdateTag(tag2.Id, existingName));
        Assert.Equal(existingName, tag1.Name);
        var updatedTag = await _context.Tags
            .AsNoTracking()
            .SingleAsync(t => t.Id == tag2.Id);

        Assert.Equal(testTag, updatedTag.Name);
    }

    [Fact]
    public async Task UpdateTag_Fail_OnWrongId()
    {
        // Arrange
        
        // Act
        
        // Assert
        await Assert.ThrowsAnyAsync<KeyNotFoundException>(async () => await TagService.UpdateTag(Guid.NewGuid(), "newName"));
    }
}