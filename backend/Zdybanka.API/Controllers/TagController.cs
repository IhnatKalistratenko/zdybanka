using Microsoft.AspNetCore.Mvc;
using System.Text.Json;
using Zdybanka.Application.DTO;
using Zdybanka.Application.DTO.Tag;
using Zdybanka.Application.Services;
using Zdybanka.Core;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TagController(TagService tagService, IdempotencyService idempotencyService) : Controller
{
    private readonly IdempotencyService _idempotencyService = idempotencyService;
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
        if (!Guid.TryParse(Request.Headers["Idempotency-Key"], out var key))
        {
            return BadRequest(new ErrorResponse
            {
                Message = "A valid Idempotency-Key GUID header is required.",
                Code = ErrorCodes.InvalidArgument,
                RequestId = HttpContext.TraceIdentifier
            });
        }

        var previousResponse = await _idempotencyService.GetResponseAsync(key.ToString());
        if (previousResponse is not null)
        {
            return new ContentResult
            {
                Content = previousResponse,
                ContentType = "application/json",
                StatusCode = StatusCodes.Status201Created
            };
        }

        TagResponse tag = await tagService.AddTagAsync(name);
        var response = JsonSerializer.Serialize(tag, new JsonSerializerOptions(JsonSerializerDefaults.Web));
        await _idempotencyService.SaveResponseAsync(key.ToString(), response);
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
