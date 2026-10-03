namespace Zdybanka.Application.Dto;

public record TagDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = null!;
}