using NetTopologySuite;
using NetTopologySuite.Geometries;

namespace Zdybanka.Core.Filters;

public class EventFilter
{
    public EventStatus? Status { get; set; }
    public Guid? CreatorId { get; set; }
    public DateTime? StartFrom { get; set; }
    public DateTime? EndTo { get; set; }
    public double? UserLongtitude { get; set; }
    public double? UserLatitude { get; set; }
    public double Radius { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    
    public Point? ToPoint()
    {
        var geometryFactory = NtsGeometryServices.Instance
            .CreateGeometryFactory(srid: 4326);

        if (UserLongtitude == null || UserLatitude == null)
        {
            return null;
        }
        
        return geometryFactory.CreatePoint(
            new Coordinate((double)UserLongtitude, (double)UserLatitude));
    }
}