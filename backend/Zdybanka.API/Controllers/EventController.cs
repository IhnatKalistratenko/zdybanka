using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Zdybanka.Application.DTO;
using Zdybanka.Application.DTO.Event;
using Zdybanka.Application.Services;
using Zdybanka.Core;
using Zdybanka.Core.Filters;
using Zdybanka.Core.Models;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/{controller}")]
public class EventController(EventService eventService, IAuthorizationService authorizationService) : Controller
{
    private readonly EventService _eventService = eventService;
    private readonly IAuthorizationService _authorizationService = authorizationService;
    
    [Authorize]
    [HttpGet("")]
    public async Task<IActionResult> GetEvents([FromQuery] EventFilter filter)
    {
        try
        {
            var userIdString = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                return Forbid();
            }

            filter.UserId = userId;
            
            List<EventResponse> events = await _eventService.GetEvents(filter);

            foreach (var @event in events)
            {
                UserEventStatus status = await _eventService.DetermineUserStatus(@event.Id, userId);
                @event.UserStatus = status.ToString();
            }
            
            return Ok(events);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }
    
    [Authorize]
    [HttpGet("{id}")]
    public async Task<IActionResult> GetEvent([FromRoute] Guid id)
    {
        try
        {
            string? userIdString = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;

            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                return Unauthorized();
            }
            EventResponse @event = await _eventService.GetEventById(id);
            UserEventStatus status = await _eventService.DetermineUserStatus(eventId: @event.Id, userId); 
            @event.UserStatus = status.ToString();
            
            return Ok(@event);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
    }

    [Authorize]
    [HttpPost("")]
    public async Task<IActionResult> CreateEvent([FromBody] CreateEventDto dto, [FromHeader] string authorization)
    {
        try
        {
            string? userId = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;

            if (!Guid.TryParse(userId, out Guid id))
            {
                return Unauthorized();
            }

            dto.CreatorId = id;
            
            EventResponse response = await _eventService.CreateEvent(dto);
            return CreatedAtAction(nameof(GetEvent), new { id = response.Id }, response);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpPut("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> UpdateEvent([FromRoute] Guid id, [FromBody] UpdateEventDto dto)
    {
        try
        {
            EventResponse existingEvent = await _eventService.GetEventById(id);
            AuthorizationResult authorizationResult = await _authorizationService.AuthorizeAsync(
                User, existingEvent.CreatorId, "Ownership");
            if (!authorizationResult.Succeeded)
            {
                return Forbid();
            }

            EventResponse response = await _eventService.UpdateEvent(id, dto);
            return Ok(response);
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

    [HttpDelete("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> DeleteEvent([FromRoute] Guid id)
    {
        try
        {
            EventResponse existingEvent = await _eventService.GetEventById(id);
            AuthorizationResult authorizationResult = await _authorizationService.AuthorizeAsync(
                User, existingEvent.CreatorId, "Ownership");
            if (!authorizationResult.Succeeded)
            {
                return Forbid();
            }

            await _eventService.DeleteEvent(id);
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

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetUserEvents()
    {
        try
        {
            var idString = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;
            if (idString == null)
            {
                return Unauthorized();
            }

            if (!Guid.TryParse(idString, out Guid userId))
            {
                return Unauthorized();
            }

            var createdEvents = await _eventService.GetEvents(new EventFilter()
            {
                CreatorId = userId
            });
            var joinedEvents = await _eventService.GetJoinedEvents(userId);
            var events = createdEvents
                .Concat(joinedEvents)
                .ToList();

            foreach (var @event in events)
            {
                UserEventStatus status = await _eventService.DetermineUserStatus(@event.Id, userId);
                @event.UserStatus = status.ToString();
            }

            return Ok(events);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [Authorize]
    [HttpPost("{eventId:guid}/join")]
    public async Task<IActionResult> JoinEvent([FromRoute] Guid eventId)
    {
        try
        {
            String userIdString = User.Claims.First(claim => claim.Type == ClaimTypes.NameIdentifier).Value;
            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                return Unauthorized();
            }

            await _eventService.AddUserToEvent(eventId, userId);

            return Ok();
        }
        catch (KeyNotFoundException e)
        {
            return BadRequest(new ErrorResponse()
            {
                Code = ErrorCodes.NotFound,
                Error = e.Message
            });
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpPost("{eventId:guid}/leave")]
    [Authorize]
    public async Task<IActionResult> LeaveEvent([FromRoute] Guid eventId)
    {
        try
        {
            string? userIdString = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;

            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                return Unauthorized();
            }

            await _eventService.DeleteUserFromEvent(eventId, userId);

            return NoContent();
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [Authorize]
    [HttpGet("in-bounds")]
    public async Task<IActionResult> GetEventsInBounds([FromHeader] EventBounds bounds)
    {
        try
        {
            string? userIdString = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;

            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                return Unauthorized();
            }
            var result = await _eventService.GetEventInBounds(bounds);

            foreach (var @event in result)
            {
                UserEventStatus status = await _eventService.DetermineUserStatus(@event.Id, userId);
                @event.UserStatus = status.ToString();
            }

            return Ok(result);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }
}
