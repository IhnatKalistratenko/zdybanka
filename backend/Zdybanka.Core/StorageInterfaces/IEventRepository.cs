using NetTopologySuite.Geometries;
using Zdybanka.Core.Filters;

namespace Zdybanka.Core.StorageInterfaces;

public interface IEventRepository
{
    Task<List<Event>> GetEventsAsync(EventFilter filter);
    Task<Event?> GetEventByIdAsync(Guid id);
    List<Event> GetEventsByCreator(Guid creatorId);
    Task<Event> AddEventAsync(Event @event);
    void RemoveEvent(Event @event);
    Event UpdateEvent(Event @event);
    Task<int> SaveChangesAsync();
    Task<List<Event>> GetJoinedEvents(Guid userId);
    Task<List<Event>> GetEventsInBordersAsync(Polygon bounds);
}