using System.Diagnostics;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.PhanCa;
using CafePos.Application.DTOs.QuanLy.TroLyAi;
using CafePos.Application.Interfaces.QuanLy.BaoCao;
using CafePos.Application.Interfaces.QuanLy.PhanCa;
using CafePos.Application.Interfaces.QuanLy.TroLyAi;
using CafePos.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace CafePos.Infrastructure.Services.QuanLy.TroLyAi;

/// <summary>
/// Trợ lý AI tiếng Việt (Daylight AI) kết nối trực tiếp tới Ollama chạy local (0đ API Key).
/// Hỗ trợ Tool Calling an toàn trên dữ liệu PostgreSQL thật và Mini-Form xác nhận (Human-in-the-loop).
/// </summary>
public class OllamaAiAssistantService : IAiAssistantService
{
    private static readonly TimeSpan VietnamOffset = TimeSpan.FromHours(7);
    private static readonly JsonSerializerOptions JsonOpts = new(JsonSerializerDefaults.Web)
    {
        PropertyNameCaseInsensitive = true
    };

    private const string SystemPrompt =
        "Bạn là Daylight AI, trợ lý quản lý quán cà phê học bài (PinVuTru Cafe POS) nói tiếng Việt tự nhiên, ngắn gọn, chính xác. " +
        "LUÔN dùng các công cụ (tools) được cung cấp để lấy số liệu thật từ hệ thống, TUYỆT ĐỐI KHÔNG tự bịa doanh thu, số đơn, tên món hay lịch trực. " +
        "Với yêu cầu thay đổi dữ liệu (giảm giá món hoặc phân công ca), hãy gọi công cụ tạo bản nháp Mini-Form (draft_menu_promotion hoặc draft_shift_assignment) để quản lý xem và bấm Xác nhận. " +
        "Nếu yêu cầu thiếu thông tin bắt buộc, hãy hỏi lại ngắn gọn. Nếu yêu cầu ngoài phạm vi quản lý quán cà phê (hack, xóa database, viết code không liên quan), hãy từ chối lịch sự.";

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;
    private readonly CafePosDbContext _db;
    private readonly IReportAnalyticsService _reportService;
    private readonly IShiftScheduleService _shiftScheduleService;
    private readonly ILogger<OllamaAiAssistantService> _logger;

    public OllamaAiAssistantService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        CafePosDbContext db,
        IReportAnalyticsService reportService,
        IShiftScheduleService shiftScheduleService,
        ILogger<OllamaAiAssistantService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
        _db = db;
        _reportService = reportService;
        _shiftScheduleService = shiftScheduleService;
        _logger = logger;
    }

    private string OllamaBaseUrl =>
        (_configuration["Ollama:BaseUrl"] ?? "http://127.0.0.1:11434").TrimEnd('/');

    private string OllamaModel =>
        (_configuration["Ollama:Model"] ?? "qwen2.5:3b").Trim();

    public async Task<ServiceResult<AiAssistantStatusDto>> GetStatusAsync(CancellationToken ct = default)
    {
        var context = await BuildStoreContextAsync(ct);
        var installedModels = new List<string>();
        bool isOnline = false;
        string statusMessage;

        try
        {
            var client = _httpClientFactory.CreateClient("Ollama");
            using var response = await client.GetAsync($"{OllamaBaseUrl}/api/tags", ct);
            if (response.IsSuccessStatusCode)
            {
                isOnline = true;
                var json = await response.Content.ReadAsStringAsync(ct);
                using var doc = JsonDocument.Parse(json);
                if (doc.RootElement.TryGetProperty("models", out var modelsEl) &&
                    modelsEl.ValueKind == JsonValueKind.Array)
                {
                    foreach (var m in modelsEl.EnumerateArray())
                    {
                        if (m.TryGetProperty("name", out var nameEl))
                        {
                            var name = nameEl.GetString();
                            if (!string.IsNullOrWhiteSpace(name))
                            {
                                installedModels.Add(name);
                            }
                        }
                    }
                }

                var hasTarget = installedModels.Any(m =>
                    string.Equals(m, OllamaModel, StringComparison.OrdinalIgnoreCase) ||
                    m.StartsWith(OllamaModel + ":", StringComparison.OrdinalIgnoreCase));

                statusMessage = hasTarget
                    ? $"Ollama sẵn sàng · Model {OllamaModel} (Local GPU)"
                    : $"Ollama trực tuyến nhưng chưa thấy model '{OllamaModel}'. Hãy chạy: ollama pull {OllamaModel}";
            }
            else
            {
                statusMessage = $"Ollama phản hồi mã lỗi HTTP {(int)response.StatusCode}.";
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Không kết nối được tới Ollama tại {Url}", OllamaBaseUrl);
            statusMessage = $"Chưa kết nối được Ollama tại {OllamaBaseUrl}. Hãy khởi chạy 'ollama serve' với OLLAMA_MODELS=D:\\AI_Models\\ollama.";
        }

        return ServiceResult<AiAssistantStatusDto>.Success(
            new AiAssistantStatusDto(
                isOnline,
                OllamaModel,
                OllamaBaseUrl,
                statusMessage,
                installedModels,
                context));
    }

    public async Task<ServiceResult<AiChatResponseDto>> ChatAsync(
        AiChatRequestDto request,
        CancellationToken ct = default)
    {
        var userMessage = (request.Message ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(userMessage))
        {
            return ServiceResult<AiChatResponseDto>.Failure(
                "Vui lòng nhập câu hỏi cho Daylight AI.",
                "EMPTY_MESSAGE",
                400);
        }

        var sw = Stopwatch.StartNew();
        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(VietnamOffset).DateTime);

        var messages = new List<object>
        {
            new
            {
                role = "system",
                content = $"{SystemPrompt} Ngày hiện tại theo giờ Việt Nam là {todayLocal:yyyy-MM-dd} ({GetVietnameseDayOfWeek(todayLocal)})."
            }
        };

        if (request.History is { Count: > 0 })
        {
            foreach (var h in request.History.TakeLast(6))
            {
                var role = string.Equals(h.Role, "assistant", StringComparison.OrdinalIgnoreCase)
                    ? "assistant"
                    : "user";
                if (!string.IsNullOrWhiteSpace(h.Content))
                {
                    messages.Add(new { role, content = h.Content.Trim() });
                }
            }
        }

        messages.Add(new { role = "user", content = userMessage });

        var tools = BuildOllamaToolsDefinition();
        string? toolUsed = null;
        AiMiniFormDraftDto? miniFormDraft = null;
        string finalReply;

        try
        {
            var firstResp = await CallOllamaChatAsync(messages, tools, ct);
            if (firstResp is null)
            {
                return ServiceResult<AiChatResponseDto>.Failure(
                    $"Không kết nối được tới Ollama local tại {OllamaBaseUrl}. Vui lòng kiểm tra 'ollama serve'.",
                    "OLLAMA_UNAVAILABLE",
                    503);
            }

            if (firstResp.ToolCalls is { Count: > 0 })
            {
                var call = firstResp.ToolCalls[0];
                toolUsed = call.FunctionName;

                var (toolPayloadJson, draft) = await ExecuteToolAsync(call.FunctionName, call.Arguments, todayLocal, ct);
                miniFormDraft = draft;

                // Gửi lại kết quả Tool cho Ollama để model diễn giải tiếng Việt tự nhiên
                messages.Add(new
                {
                    role = "assistant",
                    content = firstResp.Content ?? string.Empty,
                    tool_calls = new[]
                    {
                        new
                        {
                            function = new
                            {
                                name = call.FunctionName,
                                arguments = call.Arguments
                            }
                        }
                    }
                });
                messages.Add(new
                {
                    role = "tool",
                    content = toolPayloadJson
                });

                var secondResp = await CallOllamaChatAsync(messages, null, ct);
                finalReply = !string.IsNullOrWhiteSpace(secondResp?.Content)
                    ? secondResp!.Content.Trim()
                    : BuildFallbackSummaryFromTool(toolUsed, draft);
            }
            else
            {
                finalReply = string.IsNullOrWhiteSpace(firstResp.Content)
                    ? "Daylight AI chưa nhận được nội dung phản hồi rõ ràng. Bạn thử diễn đạt lại ngắn gọn hơn nhé."
                    : firstResp.Content.Trim();
            }
        }
        catch (TaskCanceledException)
        {
            return ServiceResult<AiChatResponseDto>.Failure(
                "Ollama xử lý quá thời gian chờ. Nếu đây là lần gọi đầu tiên (cold-start nạp GPU), vui lòng thử gửi lại.",
                "OLLAMA_TIMEOUT",
                504);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Lỗi khi gọi Ollama Chat API");
            return ServiceResult<AiChatResponseDto>.Failure(
                $"Lỗi khi giao tiếp với Ollama local: {ex.Message}",
                "OLLAMA_ERROR",
                502);
        }

        sw.Stop();
        var context = await BuildStoreContextAsync(ct);

        return ServiceResult<AiChatResponseDto>.Success(
            new AiChatResponseDto(
                finalReply,
                toolUsed,
                OllamaModel,
                sw.ElapsedMilliseconds,
                miniFormDraft,
                context));
    }

    public async Task<ServiceResult<AiConfirmActionResultDto>> ConfirmActionAsync(
        AiConfirmActionRequestDto request,
        CancellationToken ct = default)
    {
        var actionType = (request.ActionType ?? string.Empty).Trim();
        var values = request.Values ?? new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        if (string.Equals(actionType, "draft_menu_promotion", StringComparison.OrdinalIgnoreCase))
        {
            values.TryGetValue("product_name", out var productName);
            values.TryGetValue("discount_percent", out var discountStr);
            values.TryGetValue("apply_window", out var applyWindow);

            if (string.IsNullOrWhiteSpace(productName))
            {
                return ServiceResult<AiConfirmActionResultDto>.Failure(
                    "Vui lòng chọn món áp dụng khuyến mãi.",
                    "INVALID_PRODUCT",
                    400);
            }

            var cleanDiscount = (discountStr ?? string.Empty).Replace("%", string.Empty).Trim();
            if (!int.TryParse(cleanDiscount, out var discountPercent) || discountPercent < 5 || discountPercent > 50)
            {
                return ServiceResult<AiConfirmActionResultDto>.Failure(
                    "Mức giảm giá hợp lệ phải từ 5% đến 50%.",
                    "INVALID_DISCOUNT",
                    400);
            }

            var targetName = productName.Trim();
            var mon = await _db.Mons.FirstOrDefaultAsync(
                m => m.DangHoatDong && m.Ten.ToLower() == targetName.ToLower(),
                ct);
            mon ??= await _db.Mons.FirstOrDefaultAsync(
                m => m.DangHoatDong && m.Ten.ToLower().Contains(targetName.ToLower()),
                ct);

            if (mon is null)
            {
                return ServiceResult<AiConfirmActionResultDto>.Failure(
                    $"Không tìm thấy món '{targetName}' đang kinh doanh trong thực đơn.",
                    "PRODUCT_NOT_FOUND",
                    404);
            }

            var oldPrice = mon.GiaVnd;
            var rawNewPrice = (long)Math.Round(oldPrice * (100 - discountPercent) / 100.0);
            var roundedNewPrice = Math.Max(5000L, (long)(Math.Round(rawNewPrice / 1000.0) * 1000));
            mon.GiaVnd = roundedNewPrice;
            await _db.SaveChangesAsync(ct);

            var windowText = string.IsNullOrWhiteSpace(applyWindow) ? "Hôm nay" : applyWindow.Trim();
            var summary =
                $"Đã áp dụng giảm {discountPercent}% cho món '{mon.Ten}' ({oldPrice:N0}đ → {roundedNewPrice:N0}đ) · Khung áp dụng: {windowText}.";
            var context = await BuildStoreContextAsync(ct);

            return ServiceResult<AiConfirmActionResultDto>.Success(
                new AiConfirmActionResultDto(actionType, summary, DateTimeOffset.UtcNow, context),
                summary);
        }

        if (string.Equals(actionType, "draft_shift_assignment", StringComparison.OrdinalIgnoreCase))
        {
            values.TryGetValue("staff_code", out var staffCode);
            values.TryGetValue("shift_code", out var shiftCode);
            values.TryGetValue("work_date", out var workDateStr);
            values.TryGetValue("position", out var position);

            if (string.IsNullOrWhiteSpace(staffCode) || string.IsNullOrWhiteSpace(shiftCode))
            {
                return ServiceResult<AiConfirmActionResultDto>.Failure(
                    "Vui lòng điền đủ Nhân viên và Khung ca.",
                    "INVALID_ASSIGNMENT",
                    400);
            }

            var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(VietnamOffset).DateTime);
            var workDate = DateOnly.TryParse(workDateStr, out var parsedDate) ? parsedDate : todayLocal;

            var codeToken = staffCode.Split('·')[0].Trim().ToLowerInvariant();
            var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(
                u => u.UserName != null && u.UserName.ToLower() == codeToken,
                ct);

            if (user is null)
            {
                return ServiceResult<AiConfirmActionResultDto>.Failure(
                    $"Không tìm thấy nhân viên có mã '{codeToken}'.",
                    "STAFF_NOT_FOUND",
                    404);
            }

            var normalizedPos = NormalizePosition(position);
            var assignRes = await _shiftScheduleService.AssignStaffAsync(
                new CreateShiftAssignmentRequestDto(
                    workDate,
                    shiftCode.Trim().ToUpperInvariant(),
                    user.Id,
                    normalizedPos),
                ct);

            if (!assignRes.IsSuccess)
            {
                return ServiceResult<AiConfirmActionResultDto>.Failure(
                    assignRes.Message,
                    assignRes.ErrorCode,
                    assignRes.StatusCode);
            }

            var summary =
                $"Đã phân công {staffCode.Trim()} vào {shiftCode.Trim().ToUpperInvariant()} ngày {workDate:dd/MM/yyyy} ({normalizedPos}).";
            var context = await BuildStoreContextAsync(ct);

            return ServiceResult<AiConfirmActionResultDto>.Success(
                new AiConfirmActionResultDto(actionType, summary, DateTimeOffset.UtcNow, context),
                summary);
        }

        return ServiceResult<AiConfirmActionResultDto>.Failure(
            $"Loại hành động '{actionType}' chưa được hỗ trợ.",
            "UNSUPPORTED_ACTION",
            400);
    }

    private async Task<(string PayloadJson, AiMiniFormDraftDto? Draft)> ExecuteToolAsync(
        string toolName,
        JsonObject args,
        DateOnly todayLocal,
        CancellationToken ct)
    {
        switch (toolName)
        {
            case "get_shift_revenue":
            {
                var range = GetStringArg(args, "range") ?? "today";
                var shiftCode = (GetStringArg(args, "shift_code") ?? "ALL").ToUpperInvariant();
                var (fromDate, toDate) = ResolveDateRange(range, todayLocal);

                var res = await _reportService.GetRevenueAnalyticsAsync(fromDate, toDate, ct);
                if (!res.IsSuccess || res.Data is null)
                {
                    return (JsonSerializer.Serialize(new { error = res.Message }), null);
                }

                var d = res.Data;
                var slots = d.TimeSlots.Select(s => new
                {
                    s.SlotKey,
                    s.Label,
                    s.OrderValueVnd,
                    s.CollectedVnd,
                    s.OrderCount
                }).ToList();

                if (shiftCode != "ALL")
                {
                    var keyMap = shiftCode switch
                    {
                        "CA_SANG" => "morning",
                        "CA_TRUA" => "noon",
                        "CA_CHIEU" => "afternoon",
                        "CA_TOI" => "evening",
                        _ => ""
                    };
                    if (!string.IsNullOrEmpty(keyMap))
                    {
                        slots = slots.Where(s => s.SlotKey == keyMap).ToList();
                    }
                }

                var payload = new
                {
                    range,
                    fromDate = d.FromDate.ToString("yyyy-MM-dd"),
                    toDate = d.ToDate.ToString("yyyy-MM-dd"),
                    totalOrderValueVnd = d.TotalOrderValueVnd,
                    actualCollectedVnd = d.ActualCollectedAmountVnd,
                    totalOrders = d.TotalOrders,
                    paidOrders = d.PaidOrders,
                    awaitingPaymentOrders = d.AwaitingPaymentOrders,
                    openOrders = d.OpenOrders,
                    shifts = slots
                };
                return (JsonSerializer.Serialize(payload, JsonOpts), null);
            }

            case "get_top_products":
            {
                var range = GetStringArg(args, "range") ?? "7d";
                var limit = Math.Clamp(GetIntArg(args, "limit") ?? 5, 1, 10);
                var (fromDate, toDate) = ResolveDateRange(range, todayLocal);

                var res = await _reportService.GetRevenueAnalyticsAsync(fromDate, toDate, ct);
                if (!res.IsSuccess || res.Data is null)
                {
                    return (JsonSerializer.Serialize(new { error = res.Message }), null);
                }

                var items = res.Data.TopItems.Take(limit).Select(i => new
                {
                    i.Rank,
                    i.ItemName,
                    i.CategoryName,
                    i.QuantitySold,
                    i.RevenueVnd
                }).ToList();

                return (JsonSerializer.Serialize(new
                {
                    range,
                    fromDate = fromDate.ToString("yyyy-MM-dd"),
                    toDate = toDate.ToString("yyyy-MM-dd"),
                    topProducts = items
                }, JsonOpts), null);
            }

            case "get_weekly_shift_gaps":
            {
                var offset = GetIntArg(args, "week_offset") ?? 0;
                var targetDate = todayLocal.AddDays(offset == 1 ? 7 : 0);
                var res = await _shiftScheduleService.GetWeeklyScheduleAsync(targetDate, ct);
                if (!res.IsSuccess || res.Data is null)
                {
                    return (JsonSerializer.Serialize(new { error = res.Message }), null);
                }

                var w = res.Data;
                var gaps = new List<object>();
                for (var day = 0; day < 7; day++)
                {
                    var d = w.WeekStart.AddDays(day);
                    foreach (var tpl in w.Templates)
                    {
                        var activeCount = w.Assignments.Count(a =>
                            a.WorkDate == d &&
                            a.ShiftCode == tpl.Code &&
                            a.Status == "HoatDong");
                        var required = tpl.BaristaQuota + tpl.CashierQuota + tpl.FloorQuota;
                        if (activeCount < required)
                        {
                            gaps.Add(new
                            {
                                date = d.ToString("yyyy-MM-dd"),
                                dayOfWeek = GetVietnameseDayOfWeek(d),
                                shiftCode = tpl.Code,
                                shiftName = tpl.Name,
                                assigned = activeCount,
                                required,
                                missing = required - activeCount
                            });
                        }
                    }
                }

                var payload = new
                {
                    weekStart = w.WeekStart.ToString("yyyy-MM-dd"),
                    weekEnd = w.WeekEnd.ToString("yyyy-MM-dd"),
                    weekStatus = w.WeekStatus,
                    totalPlannedHours = w.TotalPlannedHours,
                    understaffedSlotsCount = w.UnderstaffedSlotsCount,
                    sampleGaps = gaps.Take(10)
                };
                return (JsonSerializer.Serialize(payload, JsonOpts), null);
            }

            case "draft_menu_promotion":
            {
                var rawProduct = GetStringArg(args, "product_name") ?? string.Empty;
                var discount = Math.Clamp(GetIntArg(args, "discount_percent") ?? 10, 5, 50);
                var window = GetStringArg(args, "apply_window") ?? "Ca Chiều hôm nay (14:00 - 18:00)";

                var activeMons = await _db.Mons
                    .AsNoTracking()
                    .Where(m => m.DangHoatDong)
                    .OrderBy(m => m.Ten)
                    .ToListAsync(ct);

                var matched = activeMons.FirstOrDefault(m =>
                    !string.IsNullOrWhiteSpace(rawProduct) &&
                    m.Ten.Contains(rawProduct.Trim(), StringComparison.OrdinalIgnoreCase))
                    ?? activeMons.FirstOrDefault();

                var selectedName = matched?.Ten ?? (string.IsNullOrWhiteSpace(rawProduct) ? "Bạc xỉu" : rawProduct.Trim());
                var options = activeMons.Select(m => m.Ten).ToList();

                var draft = new AiMiniFormDraftDto(
                    Guid.NewGuid().ToString("N")[..8],
                    "draft_menu_promotion",
                    "Bản nháp Mini-Form · Đề xuất khuyến mãi",
                    $"Giảm {discount}% cho món {selectedName} ({window})",
                    "pending",
                    new List<AiMiniFormFieldDto>
                    {
                        new("product_name", "Món áp dụng", selectedName, "select", options, "Chọn món trong thực đơn", true),
                        new("discount_percent", "Mức giảm (%)", $"{discount}", "number", null, "5 - 50", true),
                        new("apply_window", "Thời gian áp dụng", window, "text", null, "VD: Ca Chiều 14:00 - 18:00", true)
                    });

                var payload = new
                {
                    status = "draft_created",
                    requiresManagerConfirmation = true,
                    matchedProduct = selectedName,
                    currentPriceVnd = matched?.GiaVnd ?? 0,
                    discountPercent = discount,
                    applyWindow = window
                };
                return (JsonSerializer.Serialize(payload, JsonOpts), draft);
            }

            case "draft_shift_assignment":
            {
                var staffKeyword = GetStringArg(args, "staff_keyword") ?? string.Empty;
                var shiftCode = (GetStringArg(args, "shift_code") ?? "CA_TOI").ToUpperInvariant();
                var workDateStr = GetStringArg(args, "work_date") ?? todayLocal.ToString("yyyy-MM-dd");
                var position = NormalizePosition(GetStringArg(args, "position"));

                var scheduleRes = await _shiftScheduleService.GetWeeklyScheduleAsync(todayLocal, ct);
                var activeStaff = scheduleRes.Data?.ActiveStaff ?? Array.Empty<StaffOptionDto>();
                var templates = scheduleRes.Data?.Templates ?? Array.Empty<ShiftTemplateDto>();

                var matchedStaff = activeStaff.FirstOrDefault(s =>
                    !string.IsNullOrWhiteSpace(staffKeyword) &&
                    (s.StaffCode.Contains(staffKeyword.Trim(), StringComparison.OrdinalIgnoreCase) ||
                     s.FullName.Contains(staffKeyword.Trim(), StringComparison.OrdinalIgnoreCase)))
                    ?? activeStaff.FirstOrDefault();

                var staffLabel = matchedStaff is not null
                    ? $"{matchedStaff.StaffCode} · {matchedStaff.FullName}"
                    : "nv01";
                var staffOptions = activeStaff.Select(s => $"{s.StaffCode} · {s.FullName}").ToList();
                var shiftOptions = templates.Select(t => t.Code).ToList();
                if (shiftOptions.Count == 0)
                {
                    shiftOptions = new List<string> { "CA_SANG", "CA_TRUA", "CA_CHIEU", "CA_TOI" };
                }

                var draft = new AiMiniFormDraftDto(
                    Guid.NewGuid().ToString("N")[..8],
                    "draft_shift_assignment",
                    "Bản nháp Mini-Form · Phân công ca trực",
                    $"Xếp {staffLabel} vào {shiftCode} ngày {workDateStr} ({position})",
                    "pending",
                    new List<AiMiniFormFieldDto>
                    {
                        new("staff_code", "Nhân viên", staffLabel, "select", staffOptions, "Chọn nhân viên", true),
                        new("shift_code", "Khung ca", shiftCode, "select", shiftOptions, "Chọn khung ca", true),
                        new("work_date", "Ngày làm việc", workDateStr, "date", null, "yyyy-MM-dd", true),
                        new("position", "Vị trí", position, "select", new[] { "PhaChe", "ThuNgan", "PhucVu" }, "Chọn vị trí", true)
                    });

                var payload = new
                {
                    status = "draft_created",
                    requiresManagerConfirmation = true,
                    staff = staffLabel,
                    shiftCode,
                    workDate = workDateStr,
                    position
                };
                return (JsonSerializer.Serialize(payload, JsonOpts), draft);
            }

            default:
                return (JsonSerializer.Serialize(new { error = $"Tool '{toolName}' không tồn tại." }), null);
        }
    }

    private async Task<OllamaChatTurn?> CallOllamaChatAsync(
        List<object> messages,
        object[]? tools,
        CancellationToken ct)
    {
        var client = _httpClientFactory.CreateClient("Ollama");
        var payload = new Dictionary<string, object>
        {
            ["model"] = OllamaModel,
            ["stream"] = false,
            ["messages"] = messages,
            ["options"] = new Dictionary<string, object>
            {
                ["temperature"] = 0.2
            }
        };

        if (tools is { Length: > 0 })
        {
            payload["tools"] = tools;
        }

        var json = JsonSerializer.Serialize(payload, JsonOpts);
        using var content = new StringContent(json, Encoding.UTF8, "application/json");
        using var response = await client.PostAsync($"{OllamaBaseUrl}/api/chat", content, ct);
        if (!response.IsSuccessStatusCode)
        {
            var errText = await response.Content.ReadAsStringAsync(ct);
            _logger.LogWarning("Ollama /api/chat trả về {Code}: {Body}", (int)response.StatusCode, errText);
            return null;
        }

        var respJson = await response.Content.ReadAsStringAsync(ct);
        using var doc = JsonDocument.Parse(respJson);
        if (!doc.RootElement.TryGetProperty("message", out var msgEl))
        {
            return new OllamaChatTurn(string.Empty, new List<OllamaToolCall>());
        }

        var text = msgEl.TryGetProperty("content", out var cEl) ? cEl.GetString() ?? string.Empty : string.Empty;
        var calls = new List<OllamaToolCall>();

        if (msgEl.TryGetProperty("tool_calls", out var tcEl) && tcEl.ValueKind == JsonValueKind.Array)
        {
            foreach (var tc in tcEl.EnumerateArray())
            {
                if (tc.TryGetProperty("function", out var fnEl) &&
                    fnEl.TryGetProperty("name", out var nameEl))
                {
                    var fnName = nameEl.GetString() ?? string.Empty;
                    var argsObj = new JsonObject();
                    if (fnEl.TryGetProperty("arguments", out var argsEl))
                    {
                        if (argsEl.ValueKind == JsonValueKind.Object)
                        {
                            argsObj = JsonNode.Parse(argsEl.GetRawText())?.AsObject() ?? new JsonObject();
                        }
                        else if (argsEl.ValueKind == JsonValueKind.String)
                        {
                            var rawStr = argsEl.GetString();
                            if (!string.IsNullOrWhiteSpace(rawStr))
                            {
                                try
                                {
                                    argsObj = JsonNode.Parse(rawStr)?.AsObject() ?? new JsonObject();
                                }
                                catch
                                {
                                    // ignore malformed inner JSON string
                                }
                            }
                        }
                    }

                    if (!string.IsNullOrWhiteSpace(fnName))
                    {
                        calls.Add(new OllamaToolCall(fnName, argsObj));
                    }
                }
            }
        }

        return new OllamaChatTurn(text, calls);
    }

    private async Task<AiStoreContextDto> BuildStoreContextAsync(CancellationToken ct)
    {
        var todayLocal = DateOnly.FromDateTime(DateTimeOffset.UtcNow.ToOffset(VietnamOffset).DateTime);
        var revRes = await _reportService.GetRevenueAnalyticsAsync(todayLocal, todayLocal, ct);
        var weekRes = await _shiftScheduleService.GetWeeklyScheduleAsync(todayLocal, ct);

        var todayRevenue = revRes.Data?.ActualCollectedAmountVnd ?? 0;
        var todayGov = revRes.Data?.TotalOrderValueVnd ?? 0;
        var pendingOrders = (revRes.Data?.AwaitingPaymentOrders ?? 0) + (revRes.Data?.OpenOrders ?? 0);
        var understaffed = weekRes.Data?.UnderstaffedSlotsCount ?? 0;

        return new AiStoreContextDto(
            todayRevenue,
            todayGov,
            pendingOrders,
            understaffed,
            DateTimeOffset.UtcNow);
    }

    private static object[] BuildOllamaToolsDefinition() =>
    [
        new
        {
            type = "function",
            function = new
            {
                name = "get_shift_revenue",
                description = "Lấy báo cáo doanh thu, số đơn và tổng hợp theo 4 khung ca (CA_SANG, CA_TRUA, CA_CHIEU, CA_TOI).",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        range = new { type = "string", @enum = new[] { "today", "7d", "30d" }, description = "Khoảng thời gian: today, 7d, 30d." },
                        shift_code = new { type = "string", @enum = new[] { "ALL", "CA_SANG", "CA_TRUA", "CA_CHIEU", "CA_TOI" }, description = "Mã khung ca cần lọc." }
                    },
                    required = new[] { "range" }
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_top_products",
                description = "Lấy danh sách các món nước bán chạy nhất và doanh thu từng món trong thực đơn.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        range = new { type = "string", @enum = new[] { "today", "7d", "30d" }, description = "Khoảng thời gian thống kê." },
                        limit = new { type = "integer", description = "Số lượng món top (1-10, mặc định 5)." }
                    },
                    required = new[] { "range" }
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "get_weekly_shift_gaps",
                description = "Kiểm tra lịch phân ca tuần hiện tại (0) hoặc tuần tới (1) xem những ca nào đang thiếu nhân sự so với định biên.",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        week_offset = new { type = "integer", @enum = new[] { 0, 1 }, description = "0 là tuần hiện tại, 1 là tuần kế tiếp." }
                    },
                    required = new[] { "week_offset" }
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "draft_menu_promotion",
                description = "Tạo bản nháp Mini-Form đề xuất khuyến mãi giảm giá cho một món có thật trong thực đơn (chờ quản lý xác nhận).",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        product_name = new { type = "string", description = "Tên món trong thực đơn." },
                        discount_percent = new { type = "integer", description = "Phần trăm giảm giá (5-50)." },
                        apply_window = new { type = "string", description = "Khung thời gian áp dụng." }
                    },
                    required = new[] { "product_name", "discount_percent" }
                }
            }
        },
        new
        {
            type = "function",
            function = new
            {
                name = "draft_shift_assignment",
                description = "Tạo bản nháp Mini-Form phân công một nhân viên vào một khung ca cụ thể (chờ quản lý xác nhận).",
                parameters = new
                {
                    type = "object",
                    properties = new
                    {
                        staff_keyword = new { type = "string", description = "Mã hoặc tên nhân viên (vd: nv01, Minh)." },
                        shift_code = new { type = "string", @enum = new[] { "CA_SANG", "CA_TRUA", "CA_CHIEU", "CA_TOI" }, description = "Mã khung ca." },
                        work_date = new { type = "string", description = "Ngày làm việc dạng yyyy-MM-dd." },
                        position = new { type = "string", @enum = new[] { "PhaChe", "ThuNgan", "PhucVu" }, description = "Vị trí trong ca." }
                    },
                    required = new[] { "staff_keyword", "shift_code", "position" }
                }
            }
        }
    ];

    private static (DateOnly From, DateOnly To) ResolveDateRange(string range, DateOnly today) =>
        range.ToLowerInvariant() switch
        {
            "30d" => (today.AddDays(-29), today),
            "7d" => (today.AddDays(-6), today),
            _ => (today, today)
        };

    private static string NormalizePosition(string? pos) =>
        (pos ?? string.Empty).Trim().ToLowerInvariant() switch
        {
            "thungan" or "thu ngân" => "ThuNgan",
            "phucvu" or "phục vụ" => "PhucVu",
            _ => "PhaChe"
        };

    private static string GetVietnameseDayOfWeek(DateOnly d) =>
        d.DayOfWeek switch
        {
            DayOfWeek.Monday => "Thứ Hai",
            DayOfWeek.Tuesday => "Thứ Ba",
            DayOfWeek.Wednesday => "Thứ Tư",
            DayOfWeek.Thursday => "Thứ Năm",
            DayOfWeek.Friday => "Thứ Sáu",
            DayOfWeek.Saturday => "Thứ Bảy",
            _ => "Chủ Nhật"
        };

    private static string? GetStringArg(JsonObject args, string key) =>
        args.TryGetPropertyValue(key, out var node) && node is not null ? node.ToString() : null;

    private static int? GetIntArg(JsonObject args, string key)
    {
        if (!args.TryGetPropertyValue(key, out var node) || node is null) return null;
        return int.TryParse(node.ToString(), out var val) ? val : null;
    }

    private static string BuildFallbackSummaryFromTool(string? toolName, AiMiniFormDraftDto? draft)
    {
        if (draft is not null)
        {
            return $"Dưới đây là {draft.Title.ToLowerInvariant()}: {draft.Summary}. Vui lòng kiểm tra, chỉnh sửa nếu cần rồi bấm Xác nhận để áp dụng.";
        }
        return $"Daylight AI đã truy vấn xong dữ liệu từ công cụ {toolName}.";
    }

    private sealed record OllamaToolCall(string FunctionName, JsonObject Arguments);
    private sealed record OllamaChatTurn(string Content, List<OllamaToolCall> ToolCalls);
}
