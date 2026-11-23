using NetTopologySuite;
using NetTopologySuite.Geometries;
using Zdybanka.Core.Models;

namespace Zdybanka.Core.Filters;

public class EventFilter
{
    public EventStatus? Status { get; set; }
    public Guid? CreatorId { get; set; }
    public DateTime? StartFrom { get; set; }
    public DateTime? EndTo { get; set; }
    public double? UserLongitude { get; set; }
    public double? UserLatitude { get; set; }
    public double? Radius { get; set; }
    public int? Page { get; set; }
    public int? PageSize { get; set; }
    public Guid? UserId { get; set; }
    public List<Guid> Tags { get; set; } = [];
        public UserEventStatus? UserStatus { get; set; }
    public EventOrderMethod OrderMethod { get; set; } = EventOrderMethod.StartDate;
    
    public Point? UserLocationToPoint()
    {
        var geometryFactory = NtsGeometryServices.Instance
            .CreateGeometryFactory(srid: 4326);

        if (!(UserLongitude.HasValue && UserLatitude.HasValue))
        {
            return null;
        }
        
        return geometryFactory.CreatePoint(
            new Coordinate((double)UserLongitude, (double)UserLatitude));
    }
}

public enum EventOrderMethod
{
    StartDate,
    Distance,
    Name
}