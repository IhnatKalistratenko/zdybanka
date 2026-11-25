namespace Zdybanka.Core.Models;

public class IdempotencyKey
{
    public Guid Id { get; set; }
    public string Key { get; set; } = null!;
    public string ResponseBody { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
}
