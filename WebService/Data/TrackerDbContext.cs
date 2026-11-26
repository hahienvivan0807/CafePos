using CafePosTracker.Models;
using Microsoft.EntityFrameworkCore;

namespace CafePosTracker.Data;

public class TrackerDbContext : DbContext
{
    public TrackerDbContext(DbContextOptions<TrackerDbContext> options) : base(options)
    {
    }

    public DbSet<WorkGroup> WorkGroups => Set<WorkGroup>();
    public DbSet<WorkItem> WorkItems => Set<WorkItem>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<WorkGroup>(entity =>
        {
            entity.ToTable("WorkGroups");
            entity.HasKey(g => g.Id);
            entity.HasIndex(g => g.Code).IsUnique();
            entity.Property(g => g.Code).HasMaxLength(64).IsUnicode(false).IsRequired();
            entity.Property(g => g.Name).HasMaxLength(200).IsUnicode(true).IsRequired();
            entity.Property(g => g.Description).HasMaxLength(500).IsUnicode(true);
        });

        modelBuilder.Entity<WorkItem>(entity =>
        {
            entity.ToTable("WorkItems");
            entity.HasKey(i => i.Id);
            entity.HasIndex(i => i.Code).IsUnique();
            entity.HasIndex(i => new { i.GroupId, i.DisplayOrder });

            entity.Property(i => i.Code).HasMaxLength(100).IsUnicode(false).IsRequired();
            entity.Property(i => i.Title).HasMaxLength(300).IsUnicode(true).IsRequired();
            entity.Property(i => i.ShortDescription).HasMaxLength(600).IsUnicode(true).IsRequired();
            entity.Property(i => i.AcceptanceCriteria).IsUnicode(true).IsRequired();
            entity.Property(i => i.StatusNote).HasMaxLength(300).IsUnicode(true);
            entity.Property(i => i.IsOpenDecision).HasDefaultValue(false);
            entity.Property(i => i.IsCompleted).HasDefaultValue(false);
            entity.Property(i => i.UpdatedAt).HasColumnType("datetime2");
            entity.Property(i => i.CompletedAt).HasColumnType("datetime2");

            entity.HasOne(i => i.Group)
                  .WithMany(g => g.Items)
                  .HasForeignKey(i => i.GroupId)
                  .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
