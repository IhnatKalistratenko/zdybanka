using NetTopologySuite.Geometries;
using Zdybanka.Application.DTO.Chat;
using Zdybanka.Application.DTO.Event;
using Zdybanka.Core;
using Zdybanka.Core.Extensions;
using Zdybanka.Core.Filters;
using Zdybanka.Core.Models;
using Zdybanka.Core.StorageInterfaces;

namespace Zdybanka.Application.Services;

public class EventService(IEventRepository repository, ChatService chatService, TagService tagService, UserService userService)
{
    private readonly IEventRepository _repository = repository;
    private readonly ChatService _chatService = chatService;
    private readonly TagService _tagService = tagService;
    private readonly UserService _userService = userService;

    public async Task<List<EventResponse>> GetEvents(EventFilter queryParams)
    {
        List<Event> events = await _repository.GetEventsAsync(queryParams);
        
        return events.Select(ev =>
            {
                var response = new EventResponse(ev);
                var userLocation = queryParams.UserLocationToPoint();
                if (userLocation != null)
                {
                    response.DistanceToUser = ev.GetDistanceToPointInMeters(userLocation);
                }

                return response;
            }
        ).ToList();
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
    
    public async Task<UserEventStatus> DetermineUserStatus(Guid eventId, Guid userId)
    {
        var requestedEvent = await _repository.GetEventByIdAsync(eventId);
        if (requestedEvent == null)
        {
            throw new KeyNotFoundException("Event does not exist");
        }
        
        if (requestedEvent.EndTime < DateTime.UtcNow)
        {
            return UserEventStatus.Past;
        }
        
        if (requestedEvent.CreatorId == userId)
        {
            return UserEventStatus.Created;
        }

        if (requestedEvent.UserEvents.Any(e => e.UserId == userId))
        {
            return UserEventStatus.Joined;
        }

        return UserEventStatus.Available;
    }

    public async Task<EventResponse> CreateEvent(CreateEventDto dto)
    {
        Event newEvent = new Event()
        {
            Name = dto.Name,
            Description = dto.Description,
            Status = EventStatus.Active,
            Address = dto.Address,
            CreatorId = dto.CreatorId,
            MaxParticipants = dto.MaxParticipants,
            StartTime = dto.StartTime.ToUniversalTime(),
            EndTime = dto.EndTime.ToUniversalTime(),
            Coordinates = dto.ToPoint(),
        };

        List<Tag> tags = await _tagService.GetTagsByIdsAsync(dto.TagIds);
        foreach (Tag tag in tags)
        {
            newEvent.Tags.Add(tag);
        }
        
        newEvent.UserEvents.Add(new UserEvent()
        {
            JoinedAt = DateTime.Now.ToUniversalTime(),
            Event = newEvent,
            UserId = newEvent.CreatorId
        });
        
        await _repository.AddEventAsync(newEvent);
        
        await _repository.SaveChangesAsync();
        
        CreateChatDto chatDto = new CreateChatDto()
        {
            Name = newEvent.Name,
            Description = newEvent.Description ?? "",
            EventId = newEvent.Id,
            Status = ChatStatus.Active
        };
        chatDto.ParticipantsIds.Add(newEvent.CreatorId);
        
        await _chatService.CreateChat(chatDto);
        
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
        dbEvent.Coordinates = dto.ToPoint();
        dbEvent.Tags.Clear();
        List<Tag> tags = await _tagService.GetTagsByIdsAsync(dto.TagIds);
        foreach (Tag tag in tags)
        {
            dbEvent.Tags.Add(tag);
        }

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

    public async Task<List<EventResponse>> GetJoinedEvents(Guid userId)
    {
        var events = await _repository.GetJoinedEvents(userId);
        return events.Select(@event => new EventResponse(@event)).ToList();
    }

    private Coordinate[] PrepareCoordinatesForBounds(EventBounds bounds)
    {
        return
        [
            new Coordinate()
            {
                X = bounds.TopLeftCornerLongitude,
                Y = bounds.TopLeftCornerLatitude,
            },
            new Coordinate()
            {
                X = bounds.BottomRightCornerLongitude,
                Y = bounds.TopLeftCornerLatitude,
            },
            new Coordinate()
            {
                X = bounds.BottomRightCornerLongitude,
                Y = bounds.BottomRightCornerLatitude,
            },
            new Coordinate()
            {
                X = bounds.TopLeftCornerLongitude,
                Y = bounds.BottomRightCornerLatitude,
            },
            new Coordinate()
            {
                X = bounds.TopLeftCornerLongitude,
                Y = bounds.TopLeftCornerLatitude,
            }
        ];
    }

    public async Task<List<EventLocationResponse>> GetEventInBounds(EventBounds bounds)
    {
        
        var linearRing = new LinearRing(PrepareCoordinatesForBounds(bounds));
        if (!linearRing.IsClosed)
        {
            throw new ArgumentException("Bounds must be closed");
        }
        
        var polygon = new Polygon(linearRing)
        {
            SRID = 4326
        };
        
        var events = await _repository.GetEventsInBordersAsync(polygon);

        return events.Select(e => new EventLocationResponse(e)).ToList();
    }

    public async Task AddUserToEvent(Guid eventId, Guid userId)
    {
        var dbEvent = await _repository.GetEventByIdAsync(eventId);
        if (dbEvent == null)
        {
            throw new KeyNotFoundException();
        }

        var user = await _userService.GetUserById(userId);
        dbEvent.UserEvents.Add(new UserEvent()
        {
            EventId = dbEvent.Id,
            UserId = user.Id
        });

        var chat = await _chatService.GetChatByEventIdAsync(dbEvent.Id);
        
        await _chatService.AddUserToChatAsync(chat.Id, userId);

        _repository.UpdateEvent(dbEvent);
        
        await _repository.SaveChangesAsync();
    }

    public async Task DeleteUserFromEvent(Guid eventId, Guid userId)
    {
        var dbEvent = await _repository.GetEventByIdAsync(eventId);
        if (dbEvent == null)
        {
            throw new KeyNotFoundException();
        }
        
        dbEvent.UserEvents.Remove(dbEvent.UserEvents.First(e => e.UserId == userId));
        var chat = await _chatService.GetChatByEventIdAsync(dbEvent.Id);
        await _chatService.DeleteUserFromChatAsync(chat.Id, userId);

        _repository.UpdateEvent(dbEvent);
        await _repository.SaveChangesAsync();
    }
}
