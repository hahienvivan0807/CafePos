namespace CafePos.Application.DTOs.DungChung;

public class ServiceResult<T>
{
    public bool IsSuccess { get; init; }
    public int StatusCode { get; init; }
    public string ErrorCode { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public T? Data { get; init; }

    public static ServiceResult<T> Success(T data, string message = "Thành công", int statusCode = 200) =>
        new()
        {
            IsSuccess = true,
            StatusCode = statusCode,
            Message = message,
            Data = data
        };

    public static ServiceResult<T> Failure(string message, string errorCode = "ERROR", int statusCode = 400) =>
        new()
        {
            IsSuccess = false,
            StatusCode = statusCode,
            ErrorCode = errorCode,
            Message = message
        };
}
