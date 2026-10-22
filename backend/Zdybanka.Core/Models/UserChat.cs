namespace Zdybanka.Core;

public partial class UserChat
{
    public Guid UserId { get; set; }

    public Guid ChatId { get; set; }

    public DateTime JoinedAt { get; set; }

    public virtual Chat Chat { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
