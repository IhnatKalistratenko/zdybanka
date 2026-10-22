using Microsoft.AspNetCore.Mvc;
using Zdybanka.Application.DTO.Chat;
using Zdybanka.Application.Services;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChatController(ChatService chatService) : Controller
{
    private readonly ChatService _chatService = chatService;

    [HttpGet("")]
    public async Task<IActionResult> GetChats()
    {
        try
        {
            List<ChatResponse> chats = await _chatService.GetAllChats();
            
            return Ok(chats);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetChatById(Guid id)
    {
        try
        {
            ChatResponse chat =  await _chatService.GetChatById(id);

            return Ok(chat);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteChat([FromRoute] Guid id)
    {
        try
        {
            await _chatService.DeleteChat(id);

            return NoContent();
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
    }

    [HttpPost("{id:guid}")]
    public async Task<IActionResult> UpdateChat([FromRoute] Guid id, [FromBody] UpdateChatDto dto)
    {
        try
        {
            ChatResponse response = await _chatService.UpdateChat(id, dto);

            return Ok(response);
        }
        catch (KeyNotFoundException e)
        {
            return  NotFound();
        }
    }
}