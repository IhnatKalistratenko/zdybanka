using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using Zdybanka.Core;
using Zdybanka.Data.DTO;

namespace Zdybanka.Data;

public partial class ZdybankaContext : DbContext
{
    public ZdybankaContext()
    {
    }

    public ZdybankaContext(DbContextOptions<ZdybankaContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Chat> Chats { get; set; }

    public virtual DbSet<Event> Events { get; set; }

    public virtual DbSet<Tag> Tags { get; set; }

    public virtual DbSet<User> Users { get; set; }

    public virtual DbSet<UserChat> UserChats { get; set; }

    public virtual DbSet<UserEvent> UserEvents { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder
            .HasPostgresEnum<ChatStatus>("chat_status")
            .HasPostgresEnum<EventStatus>("event_status")
            .HasPostgresExtension("pgcrypto")
            .HasPostgresExtension("postgis");

        modelBuilder.HasDbFunction(() => GetEventsByDistance(default, default)).HasName("nearby_events");
        modelBuilder.HasDbFunction(() => GetEventsInBorders(default, default, default, default)).HasName("events_in_borders");
        
        modelBuilder.Entity<Chat>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("chats_pkey");

            entity.ToTable("chats");

            entity.HasIndex(e => e.EventId, "chats_event_id_key").IsUnique();

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Description)
                .HasDefaultValueSql("''::text")
                .HasColumnName("description");
            entity.Property(e => e.Status)
                .HasDefaultValueSql("'active'::chat_status")
                .HasColumnName("status");
            entity.Property(e => e.EventId).HasColumnName("event_id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");

            entity.HasOne(d => d.Event).WithOne(p => p.Chat)
                .HasForeignKey<Chat>(d => d.EventId)
                .HasConstraintName("chats_event_id_fkey");
        });

        modelBuilder.Entity<Event>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("events_pkey");

            entity.ToTable("events");

            entity.HasIndex(e => e.CreatorId, "event_creator_index");

            entity.HasIndex(e => e.StartTime, "event_time_index");

            entity.HasIndex(e => e.Coordinates, "events_geo_index").HasMethod("gist");

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Address)
                .HasMaxLength(255)
                .HasDefaultValueSql("NULL::character varying")
                .HasColumnName("address");
            entity.Property(e => e.Coordinates)
                .HasColumnType("geography(Point,4326)")
                .HasColumnName("coordinates");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatorId).HasColumnName("creator_id");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.EndTime).HasColumnName("end_time");
            entity.Property(e => e.MaxParticipants).HasColumnName("max_participants");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.StartTime).HasColumnName("start_time");
            entity.Property(e => e.Status)
                .HasColumnName("event_status")
                .HasDefaultValueSql("'active'::event_status");

            entity.HasOne(d => d.Creator).WithMany(p => p.Events)
                .HasForeignKey(d => d.CreatorId)
                .HasConstraintName("events_creator_id_fkey");

            entity.HasMany(d => d.Tags).WithMany(p => p.Events)
                .UsingEntity<Dictionary<string, object>>(
                    "EventTag",
                    r => r.HasOne<Tag>().WithMany()
                        .HasForeignKey("TagId")
                        .HasConstraintName("event_tags_tag_id_fkey"),
                    l => l.HasOne<Event>().WithMany()
                        .HasForeignKey("EventId")
                        .HasConstraintName("event_tags_event_id_fkey"),
                    j =>
                    {
                        j.HasKey("EventId", "TagId").HasName("event_tags_pkey");
                        j.ToTable("event_tags");
                        j.IndexerProperty<Guid>("EventId").HasColumnName("event_id");
                        j.IndexerProperty<Guid>("TagId").HasColumnName("tag_id");
                    });
        });

        modelBuilder.Entity<Tag>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("tags_pkey");

            entity.ToTable("tags");

            entity.HasIndex(e => e.Name, "tags_name_key").IsUnique();

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("users_pkey");

            entity.ToTable("users");
            
            entity.HasIndex(e => e.Username, "users_username_key").IsUnique();

            entity.Property(e => e.Id)
                .HasDefaultValueSql("gen_random_uuid()")
                .HasColumnName("id");
            entity.Property(e => e.PasswordHash)
                .HasMaxLength(255)
                .HasColumnName("password_hash");
            entity.Property(e => e.Username)
                .HasMaxLength(50)
                .HasColumnName("username");
        });

        modelBuilder.Entity<UserChat>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.ChatId }).HasName("user_chats_pkey");

            entity.ToTable("user_chats");

            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.ChatId).HasColumnName("chat_id");
            entity.Property(e => e.JoinedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("joined_at");

            entity.HasOne(d => d.Chat).WithMany(p => p.UserChats)
                .HasForeignKey(d => d.ChatId)
                .HasConstraintName("user_chats_chat_id_fkey");

            entity.HasOne(d => d.User).WithMany(p => p.UserChats)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("user_chats_user_id_fkey");
        });

        modelBuilder.Entity<UserEvent>(entity =>
        {
            entity.HasKey(e => new { e.UserId, e.EventId }).HasName("user_events_pkey");

            entity.ToTable("user_events");

            entity.Property(e => e.UserId).HasColumnName("user_id");
            entity.Property(e => e.EventId).HasColumnName("event_id");
            entity.Property(e => e.JoinedAt)
                .HasDefaultValueSql("now()")
                .HasColumnName("joined_at");

            entity.HasOne(d => d.Event).WithMany(p => p.UserEvents)
                .HasForeignKey(d => d.EventId)
                .HasConstraintName("user_events_event_id_fkey");

            entity.HasOne(d => d.User).WithMany(p => p.UserEvents)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("user_events_user_id_fkey");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    public IQueryable<EventDistance> GetEventsByDistance(float latitude, float longtitude) =>
    FromExpression(() => GetEventsByDistance(latitude, longtitude));

    public IQueryable<EventInBorder> GetEventsInBorders(float minLatitude, float minLongtitude, float maxLatitude, float maxLongtitude) =>
    FromExpression(() => GetEventsInBorders(minLatitude, minLongtitude, maxLatitude, maxLongtitude));

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
