import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../nen_tang/giao_dien/bang_mau.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../../../nhan_vien/ca_lam/dich_vu/dich_vu_ca_lam.dart';
import '../../../nhan_vien/ca_lam/giao_dien/the_ca_nhan_vien.dart';
import '../../../quan_ly/khung_quan_ly.dart';
import '../dich_vu/dich_vu_xac_thuc.dart';
import '../dieu_khien/dieu_khien_dang_nhap.dart';
import 'thanh_phan/bieu_mau_dang_nhap.dart';
import 'thanh_phan/khung_thuong_hieu.dart';

/// Màn hình "01 · Đăng nhập" (Layout Shell)
/// - Tách biệt rõ ràng:
///   + Nghiệp vụ gọi API: AuthService & ShiftService
///   + Quản lý trạng thái form & phiên: LoginController
///   + Các thành phần giao diện: MossBrandPanel, LoginFormPanel, StaffShiftPanel
class LoginScreen extends StatefulWidget {
  final PosAuthApiClient? apiClient;
  final AuthService? authService;
  final ShiftService? shiftService;
  final bool autoRestoreSession;
  final String? initialRoutePath;

  const LoginScreen({
    super.key,
    this.apiClient,
    this.authService,
    this.shiftService,
    this.autoRestoreSession = true,
    this.initialRoutePath,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final PosAuthApiClient _apiClient;
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? PosAuthApiClient();
    final authService =
        widget.authService ?? AuthService(apiClient: _apiClient);
    final shiftService =
        widget.shiftService ?? ShiftService(apiClient: _apiClient);

    _controller = LoginController(
      authService: authService,
      shiftService: shiftService,
    )..initialize(
        autoRestoreSession: widget.autoRestoreSession,
        initialRoutePath: widget.initialRoutePath,
      );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final session = _controller.currentSession;

        // Nếu tài khoản có role Manager từ API: đi thẳng vào giao diện Quản lý
        if (session != null && session.isManager) {
          return ManagerShellScreen(
            apiClient: _apiClient,
            session: session,
            initialSectionIndex: _controller.initialManagerSection,
            onSectionChanged: _controller.updateManagerSection,
            onSessionUpdated: _controller.updateSession,
            onLoggedOut: ({String? reason}) =>
                _controller.clearSession(reason: reason),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.daylightBackground,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 32 : 16,
                      vertical: isDesktop ? 32 : 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 1060 : 520,
                      ),
                      child: isDesktop
                          ? _buildDesktopTwoColumnShell()
                          : _buildMobileResponsiveShell(),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTwoColumnShell() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2420).withValues(alpha: 0.07),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF1E2420).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Expanded(
                flex: 11,
                child: MossBrandPanel(isCompact: false),
              ),
              Expanded(
                flex: 12,
                child: _buildRightFormContainer(isCompact: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileResponsiveShell() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E2420).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MossBrandPanel(isCompact: true),
            _buildRightFormContainer(isCompact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildRightFormContainer({required bool isCompact}) {
    return Container(
      color: AppColors.daylightSurface,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 22 : 48,
        vertical: isCompact ? 26 : 44,
      ),
      child: _controller.isRestoringSession
          ? _buildRestoringSessionView()
          : (_controller.currentSession != null
                ? StaffShiftPanel(controller: _controller)
                : LoginFormPanel(
                    controller: _controller,
                    isCompact: isCompact,
                  )),
    );
  }

  Widget _buildRestoringSessionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: AppColors.mossMid,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Đang kiểm tra phiên đăng nhập (/api/auth/me)...',
              textAlign: TextAlign.center,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
