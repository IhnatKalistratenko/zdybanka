using System;
using System.Collections.Generic;
using NetTopologySuite.Geometries;

namespace Zdybanka.Core;

public partial class Event
{
    public Guid Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public string? Address { get; set; }

    public Guid CreatorId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime StartTime { get; set; }

    public DateTime EndTime { get; set; }

    public int MaxParticipants { get; set; }

    public Point Coordinates { get; set; } = null!;
    public EventStatus Status { get; set; }

    public virtual Chat? Chat { get; set; }

    public virtual User Creator { get; set; } = null!;

    public virtual ICollection<UserEvent> UserEvents { get; set; } = new List<UserEvent>();

    public virtual ICollection<Tag> Tags { get; set; } = new List<Tag>();
}
