
using Microsoft.EntityFrameworkCore;
using Zdybanka.Application.Services;
using Zdybanka.Core;
using Zdybanka.Data;
using Zdybanka.Data.Repositories;
using Zdybanka.Infrastructure.PasswordHasher;

namespace Zdybanka.API;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

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
        builder.Services.AddScoped<IUserRepository, UserRepository>();
        builder.Services.AddScoped<ITagRepository, TagRepository>();

        builder.Services.AddCors(options =>
        {
            options.AddDefaultPolicy(policy =>
            {
                policy.AllowAnyHeader().AllowAnyMethod().AllowAnyOrigin();
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

        app.UseHttpsRedirection();

        app.UseAuthorization();

        app.UseCors();


        app.MapControllers();

        app.Run();
    }
}
