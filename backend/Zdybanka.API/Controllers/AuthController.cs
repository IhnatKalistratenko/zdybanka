using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc;
using Zdybanka.Application.DTO;
using Zdybanka.Application.Services;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/{controller}")]
public class AuthController(AuthService authService) : Controller
{
    private readonly AuthService _authService = authService;
    
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest dto)
    {
        try
        {
            string token = await _authService.AuthorizeUser(dto);
            return Ok(new { token });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new ErrorResponse() { Code = ErrorCodes.NotFound, Error = "User not found." });
        }
        catch (UnauthorizedAccessException)
        {
            return BadRequest(new ErrorResponse() { Code = ErrorCodes.WrongPassword, Error = "Wrong password" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ErrorResponse() { Code = ErrorCodes.ServerError, Error = "Unknown error. Please try again." });
        }
        
    }
}