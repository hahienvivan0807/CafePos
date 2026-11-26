using System.ComponentModel.DataAnnotations;

namespace CafePosTracker.Models;

/// <summary>
/// Nhóm công việc theo vai trò hoặc tầng hệ thống (Nhân viên, Quản lý, Backend).
/// </summary>
public class WorkGroup
{
    public int Id { get; set; }

    [Required]
    [MaxLength(64)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }

    public int DisplayOrder { get; set; }

    public ICollection<WorkItem> Items { get; set; } = new List<WorkItem>();
}
