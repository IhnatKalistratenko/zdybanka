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
        
            List<ChatViewResponse> chats = await _chatService.GetAllChats();
            
            return Ok(chats);
        }

    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> GetUserChats()
    {
        
            var rawUserId = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(rawUserId, out Guid userId))
            {
                return Unauthorized();
            }

            var userChats = await _chatService.GetUserChatsAsync(userId);

            return Ok(userChats);
        }

    [Authorize]
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetChatById(Guid id)
    {
        
            Guid userId = CheckUserAuthorization();
            ExtendedChatResponse chatView = await _chatService.GetChatById(id, userId);

            return Ok(chatView);
        }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteChat([FromRoute] Guid id)
    {
        
            await _chatService.DeleteChat(id);

            return NoContent();
        }

    [HttpPost("{id:guid}")]
    public async Task<IActionResult> UpdateChat([FromRoute] Guid id, [FromBody] UpdateChatDto dto)
    {
        
            ChatViewResponse viewResponse = await _chatService.UpdateChat(id, dto);

            return Ok(viewResponse);
        }
}