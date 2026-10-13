using Microsoft.AspNetCore.Mvc;
using Zdybanka.Application.DTO.Event;
using Zdybanka.Application.Services;
using Zdybanka.Core.Filters;

namespace Zdybanka.API.Controllers;

[ApiController]
[Route("api/{controller}")]
public class EventController(EventService eventService) : Controller
{
    private readonly EventService _eventService = eventService;

    [HttpGet("")]
    public async Task<IActionResult> GetEvents([FromQuery] EventFilter filter)
    {
        try
        {
            List<EventResponse> events = await _eventService.GetEvents(filter);
            
            return Ok(events);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetEvent([FromRoute] Guid id)
    {
        try
        {
            EventResponse @event = await _eventService.GetEventById(id);
            
            return Ok(@event);
        }
        catch (KeyNotFoundException e)
        {
            return NotFound();
        }
    }

    [HttpPost]
    public async Task<IActionResult> CreateEvent([FromBody] CreateEventDto dto)
    {
        try
        {
            EventResponse response = await _eventService.CreateEvent(dto);
            return CreatedAtAction(nameof(GetEvent), new { id = response.Id }, response);
        }
        catch (Exception e)
        {
            return StatusCode(500);
        }
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateEvent([FromRoute] Guid id, [FromBody] UpdateEventDto dto)
    {
        try
        {
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
    public async Task<IActionResult> DeleteChat([FromRoute] Guid id)
    {
        try
        {
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
}