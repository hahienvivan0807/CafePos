import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import 'bieu_tuong_ca_phe.dart';

/// Cột trái (hoặc phần trên ở mobile): Panel nhận diện quán màu xanh rêu (Moss Green)
class MossBrandPanel extends StatelessWidget {
  final bool isCompact;

  const MossBrandPanel({super.key, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 24 : 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mossMid,
            AppColors.mossPrimary,
            AppColors.mossDeep,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CoffeeLogoBadge(size: isCompact ? 46 : 54),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.mossBadgeBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.mossBorderLight,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.emeraldDot,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Flexible(
                                child: Text(
                                  'Hệ thống POS Phục vụ tại bàn',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warmCreamText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Quản Lý Quán Cà Phê',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: isCompact ? 18 : 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warmCreamText,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 20 : 36),
              Text(
                'Không gian vận hành ca làm việc & phục vụ tại bàn.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: isCompact ? 20 : 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warmCreamText,
                  height: 1.3,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đồng bộ sơ đồ bàn, lượt sử dụng, ghi món, thanh toán VietQR và báo cáo quản trị trong một giao diện Daylight rõ ràng.',
                style: GoogleFonts.beVietnamPro(
                  fontSize: isCompact ? 13.5 : 14.5,
                  fontWeight: FontWeight.w400,
                  color: AppColors.warmSandMuted,
                  height: 1.55,
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 32),
                _buildFeatureItem(
                  icon: Icons.table_restaurant_outlined,
                  title: 'Sơ đồ bàn & Lượt sử dụng',
                  subtitle:
                      'Mở bàn, ghi món giỏ tạm và theo dõi đơn theo thời gian thực.',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  icon: Icons.qr_code_2_rounded,
                  title: 'Thanh toán VietQR & Đối soát',
                  subtitle:
                      'Tạo mã theo số còn phải thu và kiểm soát giao dịch minh bạch.',
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  icon: Icons.verified_user_outlined,
                  title: 'Phân quyền Nhân viên & Quản lý',
                  subtitle:
                      'Bảo mật ca làm việc, duyệt hủy món và báo cáo vận hành.',
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: isCompact ? 18 : 36),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mossBorderLight),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '01 · Đăng nhập',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmCreamText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Daylight UI · POS Web',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warmSandMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: AppColors.warmCreamText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warmCreamText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.warmSandMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
