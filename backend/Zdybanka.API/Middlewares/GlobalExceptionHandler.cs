using Microsoft.AspNetCore.Diagnostics;
using System;
using Zdybanka.Application.DTO;

namespace Zdybanka.API.Middlewares;

public class GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, code, message) = exception switch
        {
            KeyNotFoundException => (404, ErrorCodes.NotFound, "Resource not found"),
            UnauthorizedAccessException => (403, ErrorCodes.Forbidden, "Access denied"),
            ArgumentException argumentException when argumentException.Message.Contains("already exists", StringComparison.OrdinalIgnoreCase)
                => (400, ErrorCodes.UserAlreadyExists, argumentException.Message),
            ArgumentException => (400, ErrorCodes.InvalidArgument, exception.Message),
            _ => (500, ErrorCodes.ServerError, "Internal server error")
        };
        
        logger.LogError(exception, "Request failed. Request id: {RequestId}", httpContext.TraceIdentifier);

        httpContext.Response.StatusCode = status;
        httpContext.Response.ContentType = "application/json";

        var response = new ErrorResponse()
        {
            Message = message,
            Code = code,
            RequestId = httpContext.TraceIdentifier
        };

        await httpContext.Response.WriteAsJsonAsync(response, cancellationToken);

        return true;
    }
}
