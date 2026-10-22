using NetTopologySuite.Geometries;

namespace Zdybanka.Application.DTO.Event;

public record CreateEventDto
{
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public string Status { get; set; } = null!;
    public Guid CreatorId { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; }
    public int MaxParticipants { get; set; }
    public required Point Coordinates { get; set; }
}