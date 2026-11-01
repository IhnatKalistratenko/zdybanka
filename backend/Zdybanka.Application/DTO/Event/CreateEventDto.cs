using System.Text.Json.Serialization;
using NetTopologySuite;
using NetTopologySuite.Geometries;
using Zdybanka.Application.DTO.Tag;

namespace Zdybanka.Application.DTO.Event;

public record CreateEventDto
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public string? Address { get; set; }
    [JsonIgnore]
    public Guid CreatorId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int MaxParticipants { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public List<Guid> TagIds { get; set; } = new List<Guid>();

    public Point ToPoint()
    {
        var geometryFactory = NtsGeometryServices.Instance
            .CreateGeometryFactory(srid: 4326);

        return geometryFactory.CreatePoint(
            new Coordinate(Longitude, Latitude));
    }
}