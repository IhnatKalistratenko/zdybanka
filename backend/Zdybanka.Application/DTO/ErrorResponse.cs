namespace Zdybanka.Application.DTO;

public record ErrorResponse
{
    public required string Error { get; set; }
    public required string Code { get; set; }
    public Dictionary<string, string> Details { get; set; } = new Dictionary<string, string>();
}

public static class ErrorCodes
{
    public const string UserNotFound = "USER_NOT_FOUND";
    public const string UserAlreadyExists = "USER_ALREADY_EXISTS";
    public const string Unauthorized = "UNAUTHORIZED";
}