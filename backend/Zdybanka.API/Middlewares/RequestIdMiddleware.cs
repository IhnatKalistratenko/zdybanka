namespace Zdybanka.API.Middlewares;

public sealed class RequestIdMiddleware(RequestDelegate next)
{
    public async Task Invoke(HttpContext httpContext)
    {
        var requestId = httpContext.Request.Headers["X-Request-Id"].FirstOrDefault();

        if (string.IsNullOrWhiteSpace(requestId))
        {
            requestId = Guid.NewGuid().ToString();
        }

        httpContext.TraceIdentifier = requestId;
        
        httpContext.Response.OnStarting(() =>
        {
            httpContext.Response.Headers["X-Request-Id"] = requestId;
            return Task.CompletedTask;
        });

        await next(httpContext);
    }
}