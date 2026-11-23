using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Zdybanka.Application.DTO.Chat;
using Zdybanka.Application.Services;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChatController(ChatService chatService) : Controller
{
    private readonly ChatService _chatService = chatService;

    private Guid CheckUserAuthorization()
    {
        var rawToken = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(rawToken, out Guid userId))
        {
            throw new UnauthorizedAccessException();
        }

        return userId;
    }

    [HttpGet("")]
    public async Task<IActionResult> GetChats()
    {
        try
        {
            List<ChatViewResponse> chats = await _chatService.GetAllChats();
            
            return Ok(chats);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetUserChats()
    {
        try
        {
            var rawUserId = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(rawUserId, out Guid userId))
            {
                return Unauthorized();
            }

            var userChats = await _chatService.GetUserChatsAsync(userId);

            return Ok(userChats);
        }
        catch (Exception e)
        {
            Console.WriteLine(e);
            return StatusCode(500);
        }
    }

    [Authorize]
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetChatById(Guid id)
    {
        try
        {
            Guid userId = CheckUserAuthorization();
            ExtendedChatResponse chatView = await _chatService.GetChatById(id, userId);

            return Ok(chatView);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
        catch (UnauthorizedAccessException e)
        {
            Console.WriteLine(e);
            return Unauthorized();
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
            ChatViewResponse viewResponse = await _chatService.UpdateChat(id, dto);

            return Ok(viewResponse);
        }
        catch (KeyNotFoundException e)
        {
            return  NotFound();
        }
    }
}