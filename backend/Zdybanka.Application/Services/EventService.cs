using Zdybanka.Application.DTO.Chat;
using Zdybanka.Application.DTO.Event;
using Zdybanka.Core;
using Zdybanka.Core.Filters;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Application.Services;

public class EventService(IEventRepository repository, ChatService chatService)
{
    private readonly IEventRepository _repository = repository;
    private readonly ChatService _chatService = chatService;

    public async Task<List<EventResponse>> GetEvents(EventFilter queryParams)
    {

        List<Event> events = await _repository.GetEventsAsync(queryParams);
        
        return events.Select(ev => new EventResponse(ev)).ToList();
    }

    public async Task<EventResponse> GetEventById(Guid id)
    {
        Event? dbEvent = await _repository.GetEventByIdAsync(id);
        if (dbEvent == null)
        {
            throw new KeyNotFoundException();
        }
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
        
        CreateChatDto chatDto = new CreateChatDto()
        {
            Name = newEvent.Name,
            Description = newEvent.Description ?? "",
            EventId = newEvent.Id,
            Status = ChatStatus.Active
        };
        chatDto.ParticipantsIds.Add(newEvent.CreatorId);
        
        await _chatService.CreateChat(chatDto);
        await _repository.SaveChangesAsync();
        
        return new EventResponse(newEvent);
    }

    public async Task<EventResponse> UpdateEvent(Guid id, UpdateEventDto dto)
    {
        Event? dbEvent = await _repository.GetEventByIdAsync(id);
        if (dbEvent == null)
        {
            throw new KeyNotFoundException();
        }
        
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
        Event? dbEvent = await _repository.GetEventByIdAsync(id);
        if (dbEvent == null)
        {
            throw new KeyNotFoundException();
        }
        
        _repository.RemoveEvent(dbEvent);
        await _repository.SaveChangesAsync();
    }
}