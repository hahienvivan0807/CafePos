using System.ComponentModel.DataAnnotations;

namespace CafePosTracker.Models;

/// <summary>
/// Một đầu việc / tính năng cần theo dõi tiến độ trong dự án POS quán cà phê.
/// </summary>
public class WorkItem
{
    public int Id { get; set; }

    public int GroupId { get; set; }

    [Required]
    [MaxLength(100)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(300)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [MaxLength(600)]
    public string ShortDescription { get; set; } = string.Empty;

    [Required]
    public string AcceptanceCriteria { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? StatusNote { get; set; }

    public bool IsOpenDecision { get; set; }

    public int DisplayOrder { get; set; }

    public bool IsCompleted { get; set; }

    public DateTime? CompletedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public WorkGroup? Group { get; set; }
}
