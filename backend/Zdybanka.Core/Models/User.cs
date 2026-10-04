using System;
using System.Collections.Generic;

namespace Zdybanka.Core;

public partial class User
{
    public Guid Id { get; set; }

    public string Username { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public virtual ICollection<Event> Events { get; set; } = new List<Event>();

    public virtual ICollection<UserChat> UserChats { get; set; } = new List<UserChat>();

    public virtual ICollection<UserEvent> UserEvents { get; set; } = new List<UserEvent>();
}
