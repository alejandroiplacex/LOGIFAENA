using LogiFaena.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace LogiFaena.Api.Data;

public class LogiFaenaDbContext(DbContextOptions<LogiFaenaDbContext> options)
    : DbContext(options)
{
    public DbSet<SyncOperationEntity> SyncOperations =>
        Set<SyncOperationEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var entity = modelBuilder.Entity<SyncOperationEntity>();

        entity.ToTable("SyncOperations");

        entity.HasKey(x => x.Id);

        entity.Property(x => x.EntityType)
            .HasMaxLength(100)
            .IsRequired();

        entity.Property(x => x.EntityId)
            .HasMaxLength(200)
            .IsRequired();

        entity.Property(x => x.Operation)
            .HasMaxLength(50)
            .IsRequired();

        entity.Property(x => x.PayloadJson)
            .IsRequired();

        entity.Property(x => x.ClientStatus)
            .HasMaxLength(50)
            .IsRequired();

        entity.Property(x => x.ProcessingError)
            .HasMaxLength(2000);

        entity.HasIndex(x => new
        {
            x.EntityType,
            x.EntityId,
            x.Operation,
            x.ClientCreatedAtUtc
        });
    }
}