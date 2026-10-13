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
        try
        {
            return Ok(await tagService.GetTagsAsync());
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
        
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetTagById(Guid id)
    {
        try
        {
            TagResponse tag = await tagService.GetTagByIdAsync(id);

            return Ok(tag);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpPost("")]
    public async Task<IActionResult> CreateTag(string name)
    {
        try
        {
            TagResponse tag = await tagService.AddTagAsync(name);
            return CreatedAtAction(nameof(GetTagById), tag);
        }
        catch (ArgumentException e)
        {
            return BadRequest(e.Message);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> RemoveTag(Guid id)
    {
        try
        {
            await tagService.RemoveTag(id);
            return NoContent();
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateTag([FromRoute] Guid id, [FromBody] string name)
    {
        try
        {
            TagResponse result = await tagService.UpdateTag(id, name);
            
            return Ok(result);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }
}