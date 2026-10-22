namespace Zdybanka.Application.DTO.Tag;

public record TagDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
}