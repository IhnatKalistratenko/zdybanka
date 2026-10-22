using Microsoft.AspNetCore.Mvc;
using Zdybanka.Application.DTO;
using Zdybanka.Application.DTO.User;
using Zdybanka.Application.Services;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController : Controller
{
    private readonly UserService _userService;

    public UserController(UserService userService)
    {
        _userService = userService;
    }

    [HttpGet("")]
    public async Task<IActionResult> GetUsers()
    {
         List<UserResponse> users = await _userService.GetAllUsers();
         return Ok(users);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetUserById([FromRoute] Guid id)
    {
        try
        {
            UserResponse user = await _userService.GetUserById(id);

            return Ok(user);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound(new ErrorResponse()
            {
                Code = ErrorCodes.UserNotFound,
                Error = e.Message
            });
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpPost("")]
    public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest dto)
    {
        try
        {
            UserResponse user = await _userService.CreateUserAsync(dto);
            return CreatedAtAction(nameof(GetUserById), new { id = user.Id }, user);
        }
        catch (ArgumentException e)
        {
            return BadRequest(new ErrorResponse()
            {
                Code = ErrorCodes.UserAlreadyExists,
                Error = e.Message,
            });
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpPatch("{id}")]
    public async Task<IActionResult> UpdateUser(Guid id, [FromBody] UpdateUserRequest dto)
    {
        try
        {
            dto.Id = id;
            UserResponse user = await _userService.UpdateUserAsync(dto);

            return Ok(user);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound(new ErrorResponse()
            {
                Code = ErrorCodes.UserNotFound,
                Error = e.Message
            });
        }
        catch (ArgumentException e)
        {
            return BadRequest(new ErrorResponse()
            {
                Code = ErrorCodes.UserAlreadyExists,
                Error = e.Message,
            });
        }
        catch (UnauthorizedAccessException e)
        {
            return Forbid();
        }
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        try
        {
            await _userService.RemoveUserAsync(id);
            return NoContent();
        }
        catch (KeyNotFoundException e)
        {
            return NotFound(new ErrorResponse()
            {
                Code = ErrorCodes.UserNotFound,
                Error = e.Message
            });
        }
    }
}