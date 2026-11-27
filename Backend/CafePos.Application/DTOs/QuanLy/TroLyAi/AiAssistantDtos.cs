namespace CafePos.Application.DTOs.QuanLy.TroLyAi;

public record AiStoreContextDto(
    long TodayRevenueVnd,
    long TodayOrderValueVnd,
    int PendingOrdersCount,
    int UnderstaffedSlotsCount,
    DateTimeOffset SyncedAt
);

public record AiAssistantStatusDto(
    bool IsOllamaOnline,
    string ModelName,
    string OllamaBaseUrl,
    string StatusMessage,
    IReadOnlyList<string> InstalledModels,
    AiStoreContextDto StoreContext
);

public record AiChatHistoryItemDto(
    string Role,      // "user" | "assistant"
    string Content
);

public record AiChatRequestDto(
    string Message,
    IReadOnlyList<AiChatHistoryItemDto>? History = null
);

public record AiMiniFormFieldDto(
    string Key,
    string Label,
    string Value,
    string InputType, // "text" | "number" | "select" | "date"
    IReadOnlyList<string>? Options = null,
    string? Placeholder = null,
    bool IsRequired = true
);

public record AiMiniFormDraftDto(
    string DraftId,
    string ActionType, // "draft_menu_promotion" | "draft_shift_assignment"
    string Title,
    string Summary,
    string Status,     // "pending" | "confirmed" | "cancelled"
    IReadOnlyList<AiMiniFormFieldDto> Fields
);

public record AiChatResponseDto(
    string Reply,
    string? ToolUsed,
    string ModelUsed,
    long LatencyMs,
    AiMiniFormDraftDto? MiniFormDraft,
    AiStoreContextDto StoreContext
);

public record AiConfirmActionRequestDto(
    string ActionType,
    Dictionary<string, string> Values
);

public record AiConfirmActionResultDto(
    string ActionType,
    string Summary,
    DateTimeOffset AppliedAt,
    AiStoreContextDto StoreContext
);
