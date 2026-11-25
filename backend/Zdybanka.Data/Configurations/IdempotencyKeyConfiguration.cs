using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Zdybanka.Core.Models;

namespace Zdybanka.Data.Configurations;

public class IdempotencyKeyConfiguration : IEntityTypeConfiguration<IdempotencyKey>
{
    public void Configure(EntityTypeBuilder<IdempotencyKey> builder)
    {
        builder.ToTable("IdempotencyKeys");
        builder.HasKey(entry => entry.Id);

        builder.Property(entry => entry.Id)
            .HasDefaultValueSql("gen_random_uuid()");
        builder.Property(entry => entry.Key)
            .IsRequired();
        builder.Property(entry => entry.ResponseBody)
            .IsRequired();
        builder.Property(entry => entry.CreatedAt)
            .HasDefaultValueSql("now()");

        builder.HasIndex(entry => entry.Key)
            .IsUnique();
    }
}
