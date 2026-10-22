using NetTopologySuite.Geometries;

namespace Zdybanka.Core.Filters;

public class EventFilter
{
    public EventStatus? Status { get; set; }
    public Guid? CreatorId { get; set; }
    public DateTime? StartFrom { get; set; }
    public DateTime? EndTo { get; set; }
    public Point? UserLocation { get; set; }
    public double Radius { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}