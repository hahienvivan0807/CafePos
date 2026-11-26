import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../dung_chung/dang_nhap/dieu_khien/dieu_khien_dang_nhap.dart';
import '../../../nen_tang/giao_dien/bang_mau.dart';

/// Thẻ quản lý ca làm việc dành cho Nhân viên (Staff) sau khi đăng nhập
class StaffShiftPanel extends StatelessWidget {
  final LoginController controller;

  const StaffShiftPanel({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final session = controller.currentSession!;
    final activeShift = session.activeShift;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (controller.routeGuardMessage != null) ...[
          _buildErrorBanner(controller.routeGuardMessage!),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.daylightSubtle,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.mossMid,
                    child: Text(
                      session.user.fullName.isNotEmpty
                          ? session.user.fullName[0].toUpperCase()
                          : 'S',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.user.fullName,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        Text(
                          '${session.user.title} · Mã: ${session.user.staffCode}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 14),
              Text(
                activeShift == null
                    ? 'Trạng thái ca: Chưa có ca làm việc đang mở'
                    : 'Trạng thái ca: Đang mở ca (${activeShift.status})',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: activeShift == null
                      ? AppColors.inkSecondary
                      : AppColors.mossMid,
                ),
              ),
            ],
          ),
        ),
        if (controller.serverErrorMessage != null) ...[
          const SizedBox(height: 14),
          _buildErrorBanner(controller.serverErrorMessage!),
        ],
        const SizedBox(height: 20),
        if (activeShift == null)
          ElevatedButton.icon(
            key: const Key('start_shift_button'),
            onPressed: controller.isShiftActionInProgress
                ? null
                : controller.startShift,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mossMid,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              controller.isShiftActionInProgress
                  ? 'Đang mở ca...'
                  : 'Bắt đầu ca',
              style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberPreviewBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.amberPreviewBorder),
            ),
            child: Text(
              'Ca làm việc đã mở. Giao diện riêng cho Nhân viên sẽ được triển khai ở bước tiếp theo.',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12.5,
                color: AppColors.amberPreviewInk,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('end_shift_button'),
            onPressed: controller.isShiftActionInProgress
                ? null
                : controller.endShift,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.inkPrimary,
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.stop_circle_outlined),
            label: const Text('Kết thúc ca'),
          ),
        ],
        const SizedBox(height: 12),
        TextButton.icon(
          key: const Key('staff_logout_button'),
          onPressed: controller.isShiftActionInProgress
              ? null
              : controller.logout,
          icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
          label: Text(
            'Đăng xuất khỏi thiết bị',
            style: GoogleFonts.beVietnamPro(
              fontWeight: FontWeight.w600,
              color: AppColors.danger,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
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
}
