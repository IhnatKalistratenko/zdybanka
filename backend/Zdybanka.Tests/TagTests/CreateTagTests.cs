using Microsoft.EntityFrameworkCore;
using Zdybanka.Application.DTO.Tag;
using Zdybanka.Core;
using Zdybanka.Tests.Common;

namespace Zdybanka.Tests.TagTests;

public class CreateTagTests : TagTest
{
    [Fact]
    public async Task CreateTag_Success()
    {
        // Arrange
        string newTagName = "testTag";
        // Act
        TagResponse response = await TagService.AddTagAsync(newTagName);
        // Assert
        Assert.Equal(newTagName, response.Name);
        Tag? dbTag = await _context.Tags.FirstOrDefaultAsync(t => t.Name == newTagName);
        Assert.NotNull(dbTag);
        Assert.Equal(newTagName, dbTag.Name);
    }

    [Fact]
    public async Task CreateTag_Fail_OnExistingName()
    {
        // Arrange
        string newTagName = "testTag";
        await _context.Tags.AddAsync(new Tag() {Name = newTagName});
        await _context.SaveChangesAsync();
        // Act
        
        // Assert
        await Assert.ThrowsAnyAsync<ArgumentException>(async () => await TagService.AddTagAsync(newTagName));
    }
}