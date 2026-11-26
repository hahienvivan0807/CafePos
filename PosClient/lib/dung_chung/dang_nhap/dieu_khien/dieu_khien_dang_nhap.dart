import 'package:flutter/material.dart';
import '../../../nhan_vien/ca_lam/dich_vu/dich_vu_ca_lam.dart';
import '../dich_vu/dich_vu_xac_thuc.dart';
import '../mo_hinh/phien_dang_nhap.dart';

/// Controller quản lý toàn bộ trạng thái (State) và luồng xử lý của màn hình Đăng nhập,
/// tách biệt hoàn toàn khỏi phần giao diện (Widget UI).
class LoginController extends ChangeNotifier {
  final AuthService authService;
  final ShiftService shiftService;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FocusNode usernameFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode submitFocus = FocusNode();

  bool obscurePassword = true;
  bool rememberMe = false;
  bool isHoveringSubmit = false;

  bool isRestoringSession = false;
  bool isSubmitting = false;
  bool isShiftActionInProgress = false;

  String? usernameError;
  String? passwordError;
  String? serverErrorMessage;
  String? routeGuardMessage;

  AuthSessionModel? currentSession;
  int initialManagerSection = 0;

  LoginController({
    required this.authService,
    required this.shiftService,
  }) {
    usernameFocus.addListener(_onFocusChanged);
    passwordFocus.addListener(_onFocusChanged);
    usernameController.addListener(_onInputChanged);
    passwordController.addListener(_onInputChanged);
  }

  void initialize({
    required bool autoRestoreSession,
    String? initialRoutePath,
  }) {
    final routePath = _resolveInitialRoutePath(initialRoutePath);
    initialManagerSection = AuthService.resolveManagerSectionFromPath(routePath);

    if (autoRestoreSession) {
      restoreExistingSession(requestedPath: routePath);
    } else if (AuthService.isManagerProtectedPath(routePath)) {
      routeGuardMessage =
          'Vui lòng đăng nhập bằng tài khoản Quản lý (Manager) để truy cập đường dẫn này.';
      notifyListeners();
    }
  }

  static String _resolveInitialRoutePath(String? overridePath) {
    if (overridePath != null && overridePath.trim().isNotEmpty) {
      return overridePath.trim();
    }
    final uri = Uri.base;
    if (uri.fragment.isNotEmpty && uri.fragment != '/') {
      return uri.fragment;
    }
    if (uri.path.isNotEmpty) {
      return uri.path;
    }
    return '/';
  }

  void _onFocusChanged() {
    notifyListeners();
  }

  void _onInputChanged() {
    bool shouldNotify = false;
    if (usernameError != null && usernameController.text.trim().isNotEmpty) {
      usernameError = null;
      shouldNotify = true;
    }
    if (passwordError != null && passwordController.text.isNotEmpty) {
      passwordError = null;
      shouldNotify = true;
    }
    if (serverErrorMessage != null) {
      serverErrorMessage = null;
      shouldNotify = true;
    }
    if (shouldNotify) {
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    if (isSubmitting) return;
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    if (isSubmitting) return;
    rememberMe = value;
    notifyListeners();
  }

  void toggleRememberMe() {
    setRememberMe(!rememberMe);
  }

  void setHoveringSubmit(bool value) {
    if (isHoveringSubmit == value) return;
    isHoveringSubmit = value;
    notifyListeners();
  }

  void updateManagerSection(int index) {
    initialManagerSection = index;
  }

  void updateSession(AuthSessionModel updatedSession) {
    currentSession = updatedSession;
    notifyListeners();
  }

  void clearSession({String? reason}) {
    currentSession = null;
    routeGuardMessage = null;
    passwordController.clear();
    serverErrorMessage = reason;
    notifyListeners();
  }

  /// Khôi phục phiên từ Cookie qua GET /api/auth/me
  Future<void> restoreExistingSession({required String requestedPath}) async {
    isRestoringSession = true;
    serverErrorMessage = null;
    notifyListeners();

    final result = await authService.restoreSession();

    if (result.isSuccess && result.data != null) {
      final session = result.data!;
      isRestoringSession = false;
      currentSession = session;
      if (AuthService.isManagerProtectedPath(requestedPath) &&
          !session.isManager) {
        routeGuardMessage =
            'Tài khoản ${session.user.username} không có quyền Manager để truy cập khu vực Quản lý.';
      } else {
        routeGuardMessage = null;
      }
      notifyListeners();
      return;
    }

    isRestoringSession = false;
    currentSession = null;
    if (AuthService.isManagerProtectedPath(requestedPath)) {
      routeGuardMessage =
          'Phiên Quản lý chưa đăng nhập hoặc đã hết hạn. Vui lòng đăng nhập bằng tài khoản Manager.';
    }
    notifyListeners();
  }

  /// Kiểm tra hợp lệ và gửi yêu cầu POST /api/auth/login
  Future<void> submitLogin(BuildContext context) async {
    if (isSubmitting || isRestoringSession) return;

    final validation = AuthService.validateCredentials(
      username: usernameController.text,
      password: passwordController.text,
    );

    if (validation.usernameError != null || validation.passwordError != null) {
      usernameError = validation.usernameError;
      passwordError = validation.passwordError;
      serverErrorMessage = null;
      notifyListeners();

      if (validation.usernameError != null) {
        usernameFocus.requestFocus();
      } else if (validation.passwordError != null) {
        passwordFocus.requestFocus();
      }
      return;
    }

    FocusScope.of(context).unfocus();
    usernameError = null;
    passwordError = null;
    serverErrorMessage = null;
    routeGuardMessage = null;
    isSubmitting = true;
    notifyListeners();

    final result = await authService.login(
      identifier: usernameController.text.trim(),
      password: passwordController.text,
      rememberMe: rememberMe,
    );

    if (!result.isSuccess || result.data == null) {
      isSubmitting = false;
      serverErrorMessage = result.message;
      notifyListeners();
      return;
    }

    isSubmitting = false;
    currentSession = result.data!;
    passwordController.clear();
    notifyListeners();
  }

  /// Bắt đầu ca làm việc cho tài khoản Nhân viên (POST /api/shifts/start)
  Future<void> startShift() async {
    if (isShiftActionInProgress || currentSession == null) return;
    isShiftActionInProgress = true;
    serverErrorMessage = null;
    notifyListeners();

    final result = await shiftService.startShift();
    if (!result.isSuccess || result.data == null) {
      isShiftActionInProgress = false;
      serverErrorMessage = result.message;
      notifyListeners();
      return;
    }

    isShiftActionInProgress = false;
    currentSession = currentSession!.copyWith(
      activeShift: result.data,
      nextAction: 'CONTINUE_SHIFT',
    );
    notifyListeners();
  }

  /// Kết thúc ca làm việc cho tài khoản Nhân viên (POST /api/shifts/end)
  Future<void> endShift() async {
    if (isShiftActionInProgress || currentSession == null) return;
    isShiftActionInProgress = true;
    serverErrorMessage = null;
    notifyListeners();

    final result = await shiftService.endShift();
    if (!result.isSuccess) {
      isShiftActionInProgress = false;
      serverErrorMessage = result.message;
      notifyListeners();
      return;
    }

    isShiftActionInProgress = false;
    currentSession = currentSession!.copyWith(
      clearActiveShift: true,
      nextAction: 'START_SHIFT',
    );
    notifyListeners();
  }

  /// Đăng xuất khỏi phiên hiện tại (POST /api/auth/logout)
  Future<void> logout() async {
    if (isShiftActionInProgress) return;
    isShiftActionInProgress = true;
    serverErrorMessage = null;
    notifyListeners();

    await authService.logout();

    isShiftActionInProgress = false;
    clearSession();
  }

  @override
  void dispose() {
    usernameFocus.removeListener(_onFocusChanged);
    passwordFocus.removeListener(_onFocusChanged);
    usernameController.removeListener(_onInputChanged);
    passwordController.removeListener(_onInputChanged);
    usernameController.dispose();
    passwordController.dispose();
    usernameFocus.dispose();
    passwordFocus.dispose();
    submitFocus.dispose();
    super.dispose();
  }
}
