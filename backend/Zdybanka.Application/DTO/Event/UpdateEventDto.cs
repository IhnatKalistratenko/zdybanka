using NetTopologySuite.Geometries;

namespace Zdybanka.Application.DTO.Event;

public record UpdateEventDto
{
    public required string Name { get; set; }
    public required string Description { get; set; }
    public required string Address { get; set; }
    public required string Status { get; set; }
    public required DateTime  StartTime { get; set; }
    public required DateTime  EndTime { get; set; }
    public required int MaxParticipants { get; set; }
    public required Point Coordinates { get; set; }
}