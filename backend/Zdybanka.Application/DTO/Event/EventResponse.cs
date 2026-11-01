using NetTopologySuite.Geometries;

namespace Zdybanka.Application.DTO.Event;

public record EventResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
    public string? Description { get; set; }
    public string? Address { get; set; }
    public string Status { get; set; } = null!;
    public Guid CreatorId { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime StartTime { get; set; }
    public DateTime EndTime { get; set; } 
    public int MaxParticipants { get; set; }
    public double Latitude { get; set; }
    public double Longtitude { get; set; }

    public EventResponse(Core.Event domainEvent)
    {
        Id = domainEvent.Id;
        Name = domainEvent.Name;
        Description = domainEvent.Description;
        Address = domainEvent.Address;
        Status = domainEvent.Status.ToString();
        CreatorId = domainEvent.CreatorId;
        CreatedAt = domainEvent.CreatedAt;
        StartTime = domainEvent.StartTime;
        EndTime = domainEvent.EndTime;
        MaxParticipants = domainEvent.MaxParticipants;
        Latitude = domainEvent.Coordinates.Y;
        Longtitude = domainEvent.Coordinates.X;
    }
}