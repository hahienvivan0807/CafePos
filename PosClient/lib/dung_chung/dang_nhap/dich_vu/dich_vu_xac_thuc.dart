import '../../../nen_tang/mang/cong_api.dart';
import '../mo_hinh/phien_dang_nhap.dart';

/// Service chuyên trách nghiệp vụ Xác thực, Khôi phục phiên, Hồ sơ & Bảo vệ đường dẫn (Route Guard)
class AuthService {
  final PosAuthApiClient apiClient;

  const AuthService({required this.apiClient});

  /// Kiểm tra đầu vào form đăng nhập
  static ({String? usernameError, String? passwordError}) validateCredentials({
    required String username,
    required String password,
  }) {
    final trimmedUser = username.trim();
    return (
      usernameError: trimmedUser.isEmpty
          ? 'Vui lòng nhập Tên đăng nhập.'
          : null,
      passwordError: password.isEmpty ? 'Vui lòng nhập Mật khẩu.' : null,
    );
  }

  /// Kiểm tra đường dẫn có yêu cầu quyền Manager hay không
  static bool isManagerProtectedPath(String path) {
    final lower = path.toLowerCase();
    return lower.startsWith('/manager') ||
        lower.startsWith('manager') ||
        lower.startsWith('/pos') ||
        lower.startsWith('/reconciliation') ||
        lower.startsWith('/reports') ||
        lower.startsWith('/ai');
  }

  /// Ánh xạ đường dẫn URL sang tab tương ứng trong không gian Quản lý
  static int resolveManagerSectionFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.startsWith('/pos') || lower.contains('/manager/pos')) return 1;
    if (lower.contains('nhan-vien') || lower.contains('staff')) return 2;
    if (lower.startsWith('/reconciliation') ||
        lower.contains('/manager/reconciliation') ||
        lower.contains('doi-soat')) {
      return 3;
    }
    if (lower.startsWith('/reports') ||
        lower.contains('/manager/reports') ||
        lower.contains('bao-cao')) {
      return 4;
    }
    if (lower.startsWith('/ai') || lower.contains('/manager/ai')) return 5;
    return 0;
  }

  /// Khôi phục phiên đăng nhập từ Cookie (GET /api/auth/me)
  Future<ApiResult<AuthSessionModel>> restoreSession() =>
      apiClient.restoreSession();

  /// Đăng nhập (POST /api/auth/login)
  Future<ApiResult<AuthSessionModel>> login({
    required String identifier,
    required String password,
    required bool rememberMe,
  }) => apiClient.login(
    identifier: identifier,
    password: password,
    rememberMe: rememberMe,
  );

  /// Đăng xuất (POST /api/auth/logout)
  Future<ApiResult<bool>> logout() => apiClient.logout();

  /// Cập nhật hồ sơ (PUT /api/profile)
  Future<ApiResult<UserProfileModel>> updateProfile({
    required String fullName,
    String? phoneNumber,
  }) => apiClient.updateProfile(fullName: fullName, phoneNumber: phoneNumber);
}
