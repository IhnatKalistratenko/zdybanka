using System.Data;
using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using NetTopologySuite.Geometries;
using Xunit.Sdk;
using Zdybanka.Core;
using Zdybanka.Core.Extensions;
using Zdybanka.Core.Filters;
using Zdybanka.Core.Models;
using Zdybanka.Core.StorageInterfaces;
using Zdybanka.Data.DTO;

namespace Zdybanka.Data.Repositories;

public class EventRepository : IEventRepository
{
    private ZdybankaContext _context;
    public EventRepository(ZdybankaContext context)
    {
        _context = context;
    }

    public async Task<Event> AddEventAsync(Event @event)
    {
        return (await _context.Events.AddAsync(@event)).Entity;
    }

    public Task<Event?> GetEventByIdAsync(Guid id)
    {
        return _context.Events.Include(e => e.Tags).Include(e => e.UserEvents).FirstOrDefaultAsync(e => e.Id == id);
    }

    private Expression<Func<Event, Object>> OrderEnumToExpression(EventFilter filter)
    {
        switch (filter.OrderMethod)
        {
            case EventOrderMethod.StartDate:
                return @event => @event.StartTime;
            case EventOrderMethod.Distance:
                return @event => @event.Coordinates.Distance(filter.UserLocationToPoint());
            case EventOrderMethod.Name:
                return @event => @event.Name;
            default:
                throw new KeyNotFoundException("Unknown order method.");
        }
    }

    private Expression<Func<Event, bool>> UserStatusToExpression(EventFilter filter)
    {
        if (filter.UserStatus == null)
        {
            throw new NoNullAllowedException();
        }
        var now = DateTime.UtcNow;
        switch (filter.UserStatus)
        {
            
            case UserEventStatus.Available:
                return @event => @event.CreatorId != filter.UserId && @event.UserEvents.All(ue => ue.UserId != filter.UserId) && @event.EndTime > now;
            case UserEventStatus.Created:
                return @event => @event.CreatorId == filter.UserId && @event.EndTime > now;
            case UserEventStatus.Joined:
                return @event => @event.CreatorId != filter.UserId && @event.UserEvents.Any(ue => ue.UserId == filter.UserId) && @event.EndTime > now;
            case UserEventStatus.Past:
                return @event =>
                    @event.EndTime <= now &&
                    (@event.CreatorId == filter.UserId ||
                     @event.UserEvents.Any(ue => ue.UserId == filter.UserId));
            default:
                throw new KeyNotFoundException($"Unknown filter method: {filter.UserStatus.ToString()}");
        }
    }

    private IQueryable<Event> ApplyEventFilters(IQueryable<Event> query, EventFilter filter)
    {
        if (filter.Status != null)
        {
            query = query.Where(e => e.Status == filter.Status);
        }

        if (filter is { UserStatus: not null, UserId: not null })
        {
            query = query.Where(UserStatusToExpression(filter));
        }

        if (filter.CreatorId != null)
        {
            query = query.Where(e => e.CreatorId == filter.CreatorId);
        }

        if (filter.StartFrom != null)
        {
            query = query.Where(e => e.StartTime >= filter.StartFrom);
        }

        if (filter.EndTo != null)
        {
            query = query.Where(e => e.EndTime <= filter.EndTo);
        }

        if (filter.Tags.Count > 0)
        {
            query = query.Where(e => e.Tags.Any(t => filter.Tags.Contains(t.Id)));
        }

        if (filter.Radius != null && filter.UserLatitude != null && filter.UserLongitude != null)
        {
            query = query.Where(e => e.Coordinates.IsWithinDistance(filter.UserLocationToPoint(), (double)filter.Radius));
        }

        query = query.OrderBy(OrderEnumToExpression(filter));

        if (filter.Page != null && filter.PageSize != null)
        {
            int page = (int)filter.Page;
            int pageSize = (int)filter.PageSize;
            query = query.Skip((page - 1) * pageSize).Take(pageSize);
        }
        
        return query;
    }

    public Task<List<Event>> GetEventsAsync(EventFilter filter)
    {
        IQueryable<Event> query = _context.Events;
        query = query.Include(e => e.UserEvents);
        
        return ApplyEventFilters(query, filter).ToListAsync();
    }

    public List<Event> GetEventsByCreator(Guid creatorId)
    {
        return _context.Events.Where(e => e.CreatorId == creatorId).ToList();
    }

    public IQueryable<EventDistance> GetEventsByDistanceAsync(float latitude, float longtitude)
    {
        return _context.GetEventsByDistance(latitude, longtitude);
    }

    public Task<List<Event>> GetEventsInBordersAsync(Polygon bounds)
    {
        return _context.Events.FromSql($"""SELECT * FROM events WHERE ST_Within(events.coordinates::geometry, {bounds}::geometry) AND events.status <> 'completed'""").ToListAsync();
    }

    public void RemoveEvent(Event @event)
    {
        _context.Events.Remove(@event);
    }

    public Task<int> SaveChangesAsync()
    {
        return _context.SaveChangesAsync();
    }

    public Task<List<Event>> GetJoinedEvents(Guid userId)
    {
        return _context.UserEvents
            .Where(userEvent => userEvent.UserId == userId && userEvent.Event.CreatorId != userId)
            .Include(userEvent => userEvent.Event)
                .ThenInclude(@event => @event.Tags)
            .Include(userEvent => userEvent.Event)
                .ThenInclude(@event => @event.UserEvents)
            .Select(userEvent => userEvent.Event)
            .ToListAsync();
    }

    public Event UpdateEvent(Event @event)
    {
        return _context.Events.Update(@event).Entity;
    }
}
