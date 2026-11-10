namespace Zdybanka.Application.DTO.Event;

public class EventLocationResponse
{
    public Guid Id { get; set; }
    public double Longitude { get; set; }
    public double Latitude { get; set; }
    public String UserStatus { get; set; }

    public EventLocationResponse(Core.Event domainEvent)
    {
        Id = domainEvent.Id;
        Longitude = domainEvent.Coordinates.X;
        Latitude = domainEvent.Coordinates.Y;
    }
}