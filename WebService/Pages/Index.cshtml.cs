using CafePosTracker.Data;
using CafePosTracker.Models;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;

namespace CafePosTracker.Pages;

public class IndexModel : PageModel
{
    private readonly TrackerDbContext _db;

    public IndexModel(TrackerDbContext db)
    {
        _db = db;
    }

    public List<WorkGroup> Groups { get; private set; } = new();
    public int TotalItems { get; private set; }
    public int CompletedItems { get; private set; }
    public int ProgressPercent => TotalItems == 0 ? 0 : (int)Math.Round(CompletedItems * 100.0 / TotalItems);
    public string? DatabaseError { get; private set; }

    public async Task OnGetAsync(CancellationToken cancellationToken)
    {
        try
        {
            Groups = await _db.WorkGroups
                .AsNoTracking()
                .OrderBy(g => g.DisplayOrder)
                .Include(g => g.Items.OrderBy(i => i.DisplayOrder))
                .ToListAsync(cancellationToken);

            TotalItems = Groups.Sum(g => g.Items.Count);
            CompletedItems = Groups.Sum(g => g.Items.Count(i => i.IsCompleted));
        }
        catch (Exception ex)
        {
            DatabaseError = $"Không thể tải dữ liệu từ SQL Server: {ex.Message}";
        }
    }
}
