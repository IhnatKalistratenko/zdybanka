using Microsoft.EntityFrameworkCore;
using Zdybanka.Core;

namespace Zdybanka.Tests.TagTests;

public class DeleteTagTests : TagTest
{
    [Fact]
    public async Task RemoveTag_Success()
    {
        // Arrange
        Tag tag = new Tag()
        {
            Name = "testTag"
        };
        await _context.Tags.AddAsync(tag);
        await _context.SaveChangesAsync();
        
        // Act
        await TagService.RemoveTag(tag.Id);

        // Assert
        Tag? dbTag = await _context.Tags.FirstOrDefaultAsync(t => t.Id == tag.Id);
        Assert.Null(dbTag);
        dbTag = await _context.Tags.FirstOrDefaultAsync(t => t.Name == tag.Name);
        Assert.Null(dbTag);
    }

    [Fact]
    public async Task RemoveTag_Fail_OnWrongId()
    {
        // Arrange
        
        // Act
        
        // Assert
        await Assert.ThrowsAnyAsync<KeyNotFoundException>(async () => await TagService.RemoveTag(Guid.NewGuid()));
    }
}