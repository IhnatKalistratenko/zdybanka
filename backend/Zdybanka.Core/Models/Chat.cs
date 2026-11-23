using System;
using System.Collections.Generic;
using Zdybanka.Core.Models;

namespace Zdybanka.Core;

public partial class Chat
{
    public Guid Id { get; set; }

    public Guid EventId { get; set; }

    public string Name { get; set; } = null!;

    public string Description { get; set; } = null!;
    
    public ChatStatus Status { get; set; }

    public virtual Event Event { get; set; } = null!;

    public virtual ICollection<UserChat> UserChats { get; set; } = new List<UserChat>();
    public ICollection<Message> Messages { get; set; } = new List<Message>();
}
