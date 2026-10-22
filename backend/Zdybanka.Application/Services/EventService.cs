using Zdybanka.Application.DTO.Event;
using Zdybanka.Core;
using Zdybanka.Core.Filters;
using Zdybanka.Data.Repositories;

namespace Zdybanka.Application.Services;

public class EventService(IEventRepository repository)
{
    private readonly IEventRepository _repository = repository;

    public async Task<List<EventResponse>> GetEvents(GetEventsDto queryParams)
    {
        EventFilter filter = new EventFilter()
        {
            StartFrom = queryParams.StartFrom,
            EndTo = queryParams.EndTo,
            Status = queryParams.Status != null ? Enum.Parse<EventStatus>(queryParams.Status) : null,
            CreatorId = queryParams.CreatorId,
            Radius = queryParams.Radius,
            UserLocation = queryParams.UserLocation,
            Page = queryParams.Page,
            PageSize = queryParams.PageSize
        };
        List<Event> events = await _repository.GetEventsAsync(filter);
        
        return events.Select(ev => new EventResponse(ev)).ToList();
    }

    public async Task<EventResponse> GetEventById(Guid id)
    {
        Event dbEvent = await _repository.GetEventByIdAsync(id);
        return new EventResponse(dbEvent);
    }

    public async Task<EventResponse> CreateEvent(CreateEventDto dto)
    {
        Event newEvent = new Event()
        {
            Name = dto.Name,
            Description = dto.Description,
            Status = Enum.Parse<EventStatus>(dto.Status, true),
            Address = dto.Address,
            CreatorId = dto.CreatorId,
            MaxParticipants = dto.MaxParticipants,
            StartTime = dto.StartTime,
            EndTime = dto.EndTime,
            Coordinates = dto.Coordinates
        };
        
        await _repository.AddEventAsync(newEvent);
        await _repository.SaveChangesAsync();
        
        return new EventResponse(newEvent);
    }

    public async Task<EventResponse> UpdateEvent(Guid id, UpdateEventDto dto)
    {
        Event dbEvent = await _repository.GetEventByIdAsync(id);
        
        dbEvent.Name = dto.Name;
        dbEvent.Description = dto.Description;
        dbEvent.Address = dto.Address;
        dbEvent.Status = Enum.Parse<EventStatus>(dto.Status, true);
        dbEvent.StartTime = dto.StartTime;
        dbEvent.EndTime = dto.EndTime;
        dbEvent.MaxParticipants = dto.MaxParticipants;
        dbEvent.Coordinates = dto.Coordinates;

        _repository.UpdateEvent(dbEvent);
        await _repository.SaveChangesAsync();

        return new EventResponse(dbEvent);
    }

    public async Task DeleteEvent(Guid id)
    {
        Event dbEvent = await _repository.GetEventByIdAsync(id);
        
        _repository.RemoveEvent(dbEvent);
        await _repository.SaveChangesAsync();
    }
}