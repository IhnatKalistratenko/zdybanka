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
        string token = await _authService.AuthorizeUser(dto);
        return Ok(new { token });
    }
}