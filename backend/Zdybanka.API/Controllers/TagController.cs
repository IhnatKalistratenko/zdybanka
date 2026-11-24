using Microsoft.AspNetCore.Mvc;
using Zdybanka.Application.DTO.Tag;
using Zdybanka.Application.Services;
using Zdybanka.Core;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TagController(TagService tagService) : Controller
{
    [HttpGet("")]
    public async Task<IActionResult> GetAllTags()
    {
        
            return Ok(await tagService.GetTagsAsync());
        }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetTagById(Guid id)
    {
        
            TagResponse tag = await tagService.GetTagByIdAsync(id);

            return Ok(tag);
        }

    [HttpPost("")]
    public async Task<IActionResult> CreateTag(string name)
    {
        
            TagResponse tag = await tagService.AddTagAsync(name);
            return CreatedAtAction(nameof(GetTagById), tag);
        }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> RemoveTag(Guid id)
    {
        
            await tagService.RemoveTag(id);
            return NoContent();
        }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateTag([FromRoute] Guid id, [FromBody] string name)
    {
        
            TagResponse result = await tagService.UpdateTag(id, name);
            
            return Ok(result);
        }
}