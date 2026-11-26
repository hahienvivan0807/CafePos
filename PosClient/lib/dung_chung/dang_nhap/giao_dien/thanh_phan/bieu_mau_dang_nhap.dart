import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../dieu_khien/dieu_khien_dang_nhap.dart';

/// Cột phải (hoặc phần dưới trên mobile): Form đăng nhập trên nền sáng Daylight
class LoginFormPanel extends StatelessWidget {
  final LoginController controller;
  final bool isCompact;

  const LoginFormPanel({
    super.key,
    required this.controller,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.daylightSubtle,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                'Quầy POS & Phục vụ · Ca làm việc',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mossMid,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đăng nhập',
            style: GoogleFonts.beVietnamPro(
              fontSize: isCompact ? 24 : 28,
              fontWeight: FontWeight.w800,
              color: AppColors.inkPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập thông tin tài khoản nhân viên hoặc quản lý để truy cập hệ thống.',
            style: GoogleFonts.beVietnamPro(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.inkSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          if (controller.routeGuardMessage != null) ...[
            _buildServerErrorBanner(controller.routeGuardMessage!),
            const SizedBox(height: 16),
          ],

          if (controller.serverErrorMessage != null) ...[
            _buildServerErrorBanner(controller.serverErrorMessage!),
            const SizedBox(height: 16),
          ],

          // Trường 1: Tên đăng nhập
          _buildFieldLabel('Tên đăng nhập'),
          const SizedBox(height: 8),
          _buildUsernameField(),
          if (controller.usernameError != null) ...[
            const SizedBox(height: 6),
            _buildFieldErrorText(controller.usernameError!),
          ],

          const SizedBox(height: 20),

          // Trường 2: Mật khẩu
          _buildFieldLabel('Mật khẩu'),
          const SizedBox(height: 8),
          _buildPasswordField(context),
          if (controller.passwordError != null) ...[
            const SizedBox(height: 6),
            _buildFieldErrorText(controller.passwordError!),
          ],

          const SizedBox(height: 16),

          // Ghi nhớ đăng nhập
          _buildRememberMeRow(),

          const SizedBox(height: 24),

          // Nút Đăng nhập
          _buildSubmitButton(context),

          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: AppColors.borderSoft),
          const SizedBox(height: 16),

          Text(
            'Cần cấp tài khoản hoặc đặt lại mật khẩu? Vui lòng liên hệ Quản lý ca.',
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerErrorBanner(String message) {
    return Container(
      key: const Key('login_server_error_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkLabel,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '*',
          style: GoogleFonts.beVietnamPro(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.danger,
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    final hasFocus = controller.usernameFocus.hasFocus;
    final hasError = controller.usernameError != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: hasFocus ? AppColors.inputFillFocused : AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.danger
              : (hasFocus
                    ? AppColors.inputBorderFocused
                    : AppColors.inputBorder),
          width: hasFocus || hasError ? 1.6 : 1.0,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: (hasError ? AppColors.danger : AppColors.mossMid)
                      .withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: TextField(
        key: const Key('login_username_input'),
        controller: controller.usernameController,
        focusNode: controller.usernameFocus,
        enabled: !controller.isSubmitting,
        textInputAction: TextInputAction.next,
        onSubmitted: (_) => controller.passwordFocus.requestFocus(),
        style: GoogleFonts.beVietnamPro(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppColors.inkPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: InputBorder.none,
          hintText: 'Nhập mã nhân viên hoặc tên đăng nhập',
          hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.inkMuted,
          ),
          prefixIcon: Icon(
            Icons.badge_outlined,
            size: 20,
            color: hasError
                ? AppColors.danger
                : (hasFocus ? AppColors.mossMid : AppColors.inputIcon),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(BuildContext context) {
    final hasFocus = controller.passwordFocus.hasFocus;
    final hasError = controller.passwordError != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: hasFocus ? AppColors.inputFillFocused : AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? AppColors.danger
              : (hasFocus
                    ? AppColors.inputBorderFocused
                    : AppColors.inputBorder),
          width: hasFocus || hasError ? 1.6 : 1.0,
        ),
        boxShadow: hasFocus
            ? [
                BoxShadow(
                  color: (hasError ? AppColors.danger : AppColors.mossMid)
                      .withValues(alpha: 0.12),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: TextField(
        key: const Key('login_password_input'),
        controller: controller.passwordController,
        focusNode: controller.passwordFocus,
        enabled: !controller.isSubmitting,
        obscureText: controller.obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => controller.submitLogin(context),
        style: GoogleFonts.beVietnamPro(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppColors.inkPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          border: InputBorder.none,
          hintText: 'Nhập mật khẩu',
          hintStyle: GoogleFonts.beVietnamPro(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.inkMuted,
          ),
          prefixIcon: Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: hasError
                ? AppColors.danger
                : (hasFocus ? AppColors.mossMid : AppColors.inputIcon),
          ),
          suffixIcon: IconButton(
            key: const Key('toggle_password_visibility_button'),
            tooltip: controller.obscurePassword
                ? 'Hiện mật khẩu'
                : 'Ẩn mật khẩu',
            onPressed: controller.isSubmitting
                ? null
                : controller.togglePasswordVisibility,
            icon: Icon(
              controller.obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
              color: hasFocus ? AppColors.mossMid : AppColors.inputIcon,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldErrorText(String message) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 15,
          color: AppColors.danger,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberMeRow() {
    return InkWell(
      key: const Key('remember_me_toggle'),
      borderRadius: BorderRadius.circular(8),
      onTap: controller.isSubmitting ? null : controller.toggleRememberMe,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: controller.rememberMe,
                activeColor: AppColors.mossMid,
                checkColor: Colors.white,
                side: const BorderSide(
                  color: AppColors.inputBorder,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: controller.isSubmitting
                    ? null
                    : (value) => controller.setRememberMe(value ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ghi nhớ đăng nhập',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkLabel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return FocusableActionDetector(
      focusNode: controller.submitFocus,
      onShowHoverHighlight: controller.setHoveringSubmit,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            controller.submitLogin(context);
            return null;
          },
        ),
      },
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          key: const Key('login_submit_button'),
          onPressed: controller.isSubmitting
              ? null
              : () => controller.submitLogin(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.isHoveringSubmit
                ? AppColors.mossPrimary
                : AppColors.mossMid,
            disabledBackgroundColor: AppColors.mossMid.withValues(alpha: 0.65),
            foregroundColor: AppColors.warmCreamText,
            elevation: controller.isHoveringSubmit ? 4 : 1,
            shadowColor: AppColors.mossDeep.withValues(alpha: 0.28),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isSubmitting
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Đang xác thực...',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmCreamText,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đăng nhập',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warmCreamText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: AppColors.warmCreamText,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
