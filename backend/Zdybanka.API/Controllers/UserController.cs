using System.Net.Http.Headers;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Zdybanka.Application.DTO;
using Zdybanka.Application.DTO.User;
using Zdybanka.Application.Services;
using Zdybanka.Infrastructure.TokenValidation;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController(UserService userService, ITokenController tokenController) : Controller
{
    private readonly UserService _userService = userService;
    private readonly ITokenController _tokenController = tokenController;

    [HttpGet("")]
    public async Task<IActionResult> GetUsers()
    {
         List<UserResponse> users = await _userService.GetAllUsers();
         return Ok(users);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetUserById([FromRoute] Guid id)
    {
        
            UserResponse user = await _userService.GetUserById(id);

            return Ok(user);
        }

    [HttpPost("")]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest dto)
    {
        
            UserResponse user = await _userService.CreateUserAsync(dto);
            return CreatedAtAction(nameof(GetUserById), new { id = user.Id }, user);
        }
    
    [Authorize]
    [HttpPatch("{id}")]
    public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserRequest dto)
    {
        
            dto.Id = id;
            UserResponse user = await _userService.UpdateUserAsync(dto);

            return Ok(user);
        }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        
            await _userService.RemoveUserAsync(id);
            return NoContent();
        }
    
    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetUserInformation([FromHeader] string authorization)
    {
        string? idString = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(idString, out Guid id))
        {
            return Unauthorized();
        }

        UserResponse user = await _userService.GetUserById(id);

        return Ok(user);
    }
}