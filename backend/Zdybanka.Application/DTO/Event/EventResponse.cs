using NetTopologySuite.Geometries;
using Zdybanka.Application.DTO.Tag;

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
    public int ParticipantsCount { get; set; }
    public int MaxParticipants { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public List<TagResponse> Tags { get; set; }
    public double? DistanceToUser { get; set; }
    public String UserStatus { get; set; }

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
        Longitude = domainEvent.Coordinates.X;
        ParticipantsCount = domainEvent.UserEvents.Count;
        Tags = domainEvent.Tags.Select(tag => new TagResponse
        {
            Id = tag.Id,
            Name = tag.Name
        }).ToList();
    }
}