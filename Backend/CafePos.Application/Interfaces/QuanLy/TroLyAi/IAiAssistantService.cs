using CafePos.Application.DTOs.DungChung;
using CafePos.Application.DTOs.QuanLy.TroLyAi;

namespace CafePos.Application.Interfaces.QuanLy.TroLyAi;

public interface IAiAssistantService
{
    Task<ServiceResult<AiAssistantStatusDto>> GetStatusAsync(CancellationToken ct = default);

    Task<ServiceResult<AiChatResponseDto>> ChatAsync(
        AiChatRequestDto request,
        CancellationToken ct = default);

    Task<ServiceResult<AiConfirmActionResultDto>> ConfirmActionAsync(
        AiConfirmActionRequestDto request,
        CancellationToken ct = default);
}
