
using System.Text;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi;
using Zdybanka.API.Middlewares;
using Zdybanka.API.Hubs;
using Zdybanka.Application.Services;
using Zdybanka.Core;
using Zdybanka.Core.StorageInterfaces;
using Zdybanka.Data;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;
using Zdybanka.Infrastructure.TokenValidation;
using Zdybanka.API.Policies;
using Zdybanka.Application.DTO;

namespace Zdybanka.API;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        
        builder.WebHost.UseUrls("http://0.0.0.0:5000");

        // Add services to the container.
        builder.Services.AddDbContext<ZdybankaContext>(options =>
        {
            options.UseNpgsql(connectionString: builder.Configuration.GetConnectionString("ConnectionString"), x =>
            {
                x.UseNetTopologySuite();
                x.MapEnum<ChatStatus>("chat_status");
                x.MapEnum<EventStatus>("event_status");
            });
        });

        builder.Services.AddScoped<IPasswordHasher, BcryptPasswordHasher>();
        builder.Services.AddScoped<UserService>();
        builder.Services.AddScoped<TagService>();
        builder.Services.AddScoped<ChatService>();
        builder.Services.AddScoped<EventService>();
        builder.Services.AddScoped<MessageService>();
        builder.Services.AddScoped<AuthService>();
        builder.Services.AddScoped<IdempotencyService>();
        builder.Services.AddScoped<IUserRepository, UserRepository>();
        builder.Services.AddScoped<ITagRepository, TagRepository>();
        builder.Services.AddScoped<IChatRepository, ChatRepository>();
        builder.Services.AddScoped<IEventRepository, EventRepository>();
        builder.Services.AddScoped<IMessageRepository, MessageRepository>();
        builder.Services.AddScoped<ITokenController, JwtTokenController>();
        builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
        builder.Services.AddMemoryCache();
        builder.Services.AddRateLimiter(options =>
        {
            options.GlobalLimiter =
                PartitionedRateLimiter.Create<HttpContext, string>(
                    _ => RateLimitPartition.GetFixedWindowLimiter(
                        "global",
                        _ => new FixedWindowRateLimiterOptions
                        {
                            PermitLimit = 100,
                            Window = TimeSpan.FromMinutes(1),
                            QueueLimit = 0,
                            AutoReplenishment = true
                        }));

            options.RejectionStatusCode = 429;
            
            options.OnRejected = async (context, cancellationToken) =>
            {
                var retryAfter = TimeSpan.FromMinutes(1);

                if (context.Lease.TryGetMetadata(
                        MetadataName.RetryAfter,
                        out var retryAfterMetadata))
                {
                    retryAfter = retryAfterMetadata;
                }

                context.HttpContext.Response.Headers.RetryAfter =
                    Math.Max(1, (int)Math.Ceiling(retryAfter.TotalSeconds)).ToString();

                await context.HttpContext.Response.WriteAsJsonAsync(
                    new ErrorResponse
                    {
                        Message = "Too many requests",
                        Code = ErrorCodes.RetryAfter,
                        RequestId = context.HttpContext.Response.Headers["X-Request-Id"].FirstOrDefault()!
                    },
                    cancellationToken);
            };
        });

        builder.Services.AddSignalR();

        builder.Services.AddCors(options =>
        {
            options.AddDefaultPolicy(policy =>
            {
                policy.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin();
            });
        });

        builder.Services.AddAuthentication().AddJwtBearer(options =>
        {
            options.TokenValidationParameters = new TokenValidationParameters()
            {
                ValidateIssuer = true,
                ValidateAudience = false,
                ValidateIssuerSigningKey = true,
                ValidateLifetime = true,
                ValidIssuer = "zdybanka-api",
                IssuerSigningKey =
                    new SymmetricSecurityKey(
                        Encoding.UTF8.GetBytes("your_super_secret_key_with_at_least_256_bits_for_security"))
            };
            options.Events = new JwtBearerEvents()
            {
                OnMessageReceived = context =>
                {
                    var accessToken = context.Request.Query["access_token"];
                    var urlPath = context.Request.Path;

                    if (urlPath.StartsWithSegments("/hubs/chat") && !string.IsNullOrEmpty(accessToken))
                    {
                        context.Token = accessToken;
                    }

                    return Task.CompletedTask;
                }
            };
        });
        builder.Services.AddSingleton<IAuthorizationHandler, OwnershipHandler>();
        builder.Services.AddAuthorization(options =>
        {
            options.AddPolicy("Ownership", policy =>
            {
                policy.RequireAuthenticatedUser();
                policy.AddRequirements(new OwnershipRequirement());
            });
        });

        builder.Services.AddControllers();
        
        // Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
        builder.Services.AddOpenApi();
        
        var app = builder.Build();

        // Configure the HTTP request pipeline.
        if (app.Environment.IsDevelopment())
        {
            app.MapOpenApi();
        }
        
        app.UseExceptionHandler(_ => { });
        app.UseMiddleware<RequestIdMiddleware>();

        app.UseHttpsRedirection();
        
        app.UseCors();
        
        app.UseRateLimiter();

        app.UseAuthentication();
        app.UseAuthorization();
        
        app.MapControllers();
        app.MapHub<ChatHub>("hubs/chat");

        app.Run();
    }
}
