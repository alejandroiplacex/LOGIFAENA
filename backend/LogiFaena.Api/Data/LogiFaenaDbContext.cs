using LogiFaena.Api.Entities;
using Microsoft.EntityFrameworkCore;

namespace LogiFaena.Api.Data;

public class LogiFaenaDbContext(DbContextOptions<LogiFaenaDbContext> options)
    : DbContext(options)
{
    public DbSet<SyncOperationEntity> SyncOperations =>
        Set<SyncOperationEntity>();

    public DbSet<WorkerEntity> Workers =>
        Set<WorkerEntity>();

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

        // Configuración de WorkerEntity
        var worker = modelBuilder.Entity<WorkerEntity>();

        worker.ToTable("Workers");

        worker.HasKey(x => x.Id);

        worker.Property(x => x.ExternalId)
            .HasMaxLength(200)
            .IsRequired();

        worker.HasIndex(x => x.ExternalId)
            .IsUnique();

        worker.Property(x => x.Rut).HasMaxLength(30);
        worker.Property(x => x.FirstName).HasMaxLength(100);
        worker.Property(x => x.LastName).HasMaxLength(100);
        worker.Property(x => x.Company).HasMaxLength(150);
        worker.Property(x => x.Role).HasMaxLength(150);
        worker.Property(x => x.Project).HasMaxLength(150);
        worker.Property(x => x.Shift).HasMaxLength(50);
        worker.Property(x => x.Supervisor).HasMaxLength(150);
        worker.Property(x => x.City).HasMaxLength(100);
        worker.Property(x => x.Phone).HasMaxLength(50);
        worker.Property(x => x.Email).HasMaxLength(200);
        worker.Property(x => x.Status).HasMaxLength(100);
    }
}