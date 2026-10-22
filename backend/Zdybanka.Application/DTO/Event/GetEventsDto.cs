using NetTopologySuite.Geometries;
using Zdybanka.Core;

namespace Zdybanka.Application.DTO.Event;

public record GetEventsDto
{
    public string? Status { get; set; }
    public Guid? CreatorId { get; set; }
    public DateTime? StartFrom { get; set; }
    public DateTime? EndTo { get; set; }
    public Point? UserLocation { get; set; }
    public double Radius { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}