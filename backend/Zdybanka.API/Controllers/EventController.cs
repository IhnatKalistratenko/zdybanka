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
    
    [Authorize]
    [HttpGet("{id}")]
    public async Task<IActionResult> GetEvent([FromRoute] Guid id)
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

    [Authorize]
    [HttpPost("")]
    public async Task<IActionResult> CreateEvent([FromBody] CreateEventDto dto, [FromHeader] string authorization)
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

    [HttpPut("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> UpdateEvent([FromRoute] Guid id, [FromBody] UpdateEventDto dto)
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

    [HttpDelete("{id:guid}")]
    [Authorize]
    public async Task<IActionResult> DeleteEvent([FromRoute] Guid id)
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

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> GetUserEvents()
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

    [Authorize]
    [HttpPost("{eventId:guid}/join")]
    public async Task<IActionResult> JoinEvent([FromRoute] Guid eventId)
    {
        
            String userIdString = User.Claims.First(claim => claim.Type == ClaimTypes.NameIdentifier).Value;
            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                return Unauthorized();
            }

            await _eventService.AddUserToEvent(eventId, userId);

            return Ok();
        }

    [HttpPost("{eventId:guid}/leave")]
    [Authorize]
    public async Task<IActionResult> LeaveEvent([FromRoute] Guid eventId)
    {
        
            string? userIdString = User.Claims.FirstOrDefault(claim => claim.Type == ClaimTypes.NameIdentifier)?.Value;

            if (!Guid.TryParse(userIdString, out Guid userId))
            {
                return Unauthorized();
            }

            await _eventService.DeleteUserFromEvent(eventId, userId);

            return NoContent();
        }

    [Authorize]
    [HttpGet("in-bounds")]
    public async Task<IActionResult> GetEventsInBounds([FromHeader] EventBounds bounds)
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
}
