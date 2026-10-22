using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Zdybanka.Core;
using Zdybanka.Core.Filters;
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
        return _context.Events.FirstOrDefaultAsync(e => e.Id == id);
    }

    private IQueryable<Event> ApplyEventFilters(IQueryable<Event> query, EventFilter filter)
    {
        if (filter.Status != null)
        {
            query = query.Where(e => e.Status == filter.Status);
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

        if (filter.UserLocation != null)
        {
            query = query.Where(e => e.Coordinates.IsWithinDistance(filter.UserLocation, filter.Radius));
        }
        
        return query.Skip((filter.Page - 1) * filter.PageSize).Take(filter.PageSize);
    }

    public Task<List<Event>> GetEventsAsync(EventFilter filter)
    {
        IQueryable<Event> query = _context.Events;
        
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

    public IQueryable<EventInBorder> GetEventsInBordersAsync(float minLatitude, float minLongtitude, float maxLatitude, float maxLongtitude)
    {
        return _context.GetEventsInBorders(minLatitude, minLongtitude, maxLatitude, maxLongtitude);
    }

    public void RemoveEvent(Event @event)
    {
        _context.Events.Remove(@event);
    }

    public Task<int> SaveChangesAsync()
    {
        return _context.SaveChangesAsync();
    }

    public Event UpdateEvent(Event @event)
    {
        return _context.Events.Update(@event).Entity;
    }
}