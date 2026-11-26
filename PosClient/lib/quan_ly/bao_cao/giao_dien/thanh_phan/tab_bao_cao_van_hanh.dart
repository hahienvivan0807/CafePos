import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../dieu_khien/dieu_khien_bao_cao.dart';
import '../../mo_hinh/du_lieu_bao_cao.dart';
import 'hop_thoai_hoa_don_ca.dart';

/// Tab 1 · Báo cáo kết quả vận hành (bám sát giao diện Stitch)
class TabBaoCaoVanHanh extends StatelessWidget {
  final DieuKhienBaoCao dieuKhien;
  final bool isDesktop;

  const TabBaoCaoVanHanh({
    super.key,
    required this.dieuKhien,
    required this.isDesktop,
  });

  static const Color _amberAccent = Color(0xFFFE932C);

  String _formatVnd(int amount) {
    final s = amount.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    final prefix = amount < 0 ? '-' : '';
    return '$prefix${buf.toString()}đ';
  }

  @override
  Widget build(BuildContext context) {
    if (dieuKhien.dangTaiBaoCao && dieuKhien.baoCao == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.mossPrimary),
        ),
      );
    }

    if (dieuKhien.loiBaoCao != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dieuKhien.loiBaoCao!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
            TextButton(
              onPressed: dieuKhien.taiBaoCao,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final bc = dieuKhien.baoCao;
    if (bc == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildKpiGrid(bc),
        const SizedBox(height: 18),
        _buildFourShiftsCard(context, bc),
        const SizedBox(height: 18),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: _buildHourlyChartCard(bc)),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _buildPaymentDonutCard(bc)),
            ],
          )
        else ...[
          _buildHourlyChartCard(bc),
          const SizedBox(height: 16),
          _buildPaymentDonutCard(bc),
        ],
        const SizedBox(height: 18),
        _buildTopItemsTableCard(bc),
      ],
    );
  }

  void _moHoaDonTrongCa(BuildContext context, KhungGioDoanhThu ca) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF133021).withValues(alpha: 0.42),
      builder: (_) => HopThoaiHoaDonCa(
        dichVu: dieuKhien.dichVu,
        maCa: ca.maKhung,
        tenCa: ca.nhanHienThi,
        tuNgay: dieuKhien.tuNgayBaoCao,
        denNgay: dieuKhien.denNgayBaoCao,
      ),
    );
  }

  Widget _buildFourShiftsCard(BuildContext context, BaoCaoVanHanh bc) {
    final icons = [
      Icons.wb_sunny_outlined,
      Icons.lunch_dining_outlined,
      Icons.menu_book_rounded,
      Icons.nights_stay_outlined,
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doanh thu theo 4 ca làm việc',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mossPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bấm vào từng ca để xem danh sách hóa đơn và chi tiết từng hóa đơn trong ca',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mossSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'pos."KhungCaLam" · 4 ca chuẩn',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mossDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 960
                  ? 4
                  : (constraints.maxWidth >= 560 ? 2 : 1);
              final itemWidth = (constraints.maxWidth - (cols - 1) * 12) / cols;

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(bc.khungGio.length, (idx) {
                  final ca = bc.khungGio[idx];
                  final icon = icons[idx % icons.length];
                  return SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      key: Key('bao_cao_ca_${ca.maKhung}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _moHoaDonTrongCa(context, ca),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.daylightSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.borderSoft,
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 18,
                                    color: AppColors.mossPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    ca.nhanHienThi,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1, color: AppColors.borderSoft),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${ca.soDon} hóa đơn',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatVnd(ca.thucThuVnd),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.mossPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 18,
                                      color: AppColors.inkMuted,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(BaoCaoVanHanh bc) {
    final cards = [
      _buildKpiCard(
        title: 'TỔNG GIÁ TRỊ ĐƠN HÀNG',
        subtitle: 'Gross Order Value (GOV)',
        value: _formatVnd(bc.tongGiaTriDonVnd),
        footer:
            '${bc.tongDonHang} đơn (${bc.donDaThanhToan} đã thu · ${bc.donChoQr} chờ QR · ${bc.donDangMo} đang mở)',
        icon: Icons.receipt_long_rounded,
        iconBg: AppColors.daylightSubtle,
        iconColor: AppColors.mossPrimary,
      ),
      _buildKpiCard(
        title: 'THỰC TẾ TIỀN ĐÃ THU',
        subtitle: 'Net Cash & QR Collected',
        value: _formatVnd(bc.thucTeDaThuVnd),
        footer: bc.tongGiaTriDonVnd > 0
            ? 'Tất toán: ${(bc.thucTeDaThuVnd * 100 / bc.tongGiaTriDonVnd).toStringAsFixed(1)}% tổng đơn'
            : 'Chưa phát sinh thanh toán',
        icon: Icons.payments_rounded,
        iconBg: AppColors.mossSoft,
        iconColor: AppColors.mossDeep,
        highlighted: true,
      ),
      _buildKpiCard(
        title: 'LƯỢT BÀN & ĐƠN HÀNG',
        subtitle: 'Order Flow & Capacity',
        value: '${bc.tongLuotBan} lượt · ${bc.tongDonHang} đơn',
        footer:
            'Tỷ lệ hoàn tất bàn: ${bc.tyLeHoanTatBan.toStringAsFixed(1)}% (${bc.luotBanHoanTat}/${bc.tongLuotBan})',
        icon: Icons.table_restaurant_rounded,
        iconBg: AppColors.daylightSubtle,
        iconColor: AppColors.mossPrimary,
      ),
      _buildKpiCard(
        title: 'MÓN BÁN CHẠY NHẤT',
        subtitle: 'Top Best Seller',
        value: bc.monBanChayNhat ?? 'Chưa có dữ liệu',
        footer: bc.soLuongMonBanChayNhat > 0
            ? 'Số lượng xuất: ${bc.soLuongMonBanChayNhat} ly/phần'
            : 'Chưa có món xuất trong kỳ',
        icon: Icons.emoji_events_rounded,
        iconBg: const Color(0xFFFFECCE),
        iconColor: const Color(0xFF904D00),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 1060
            ? 4
            : (constraints.maxWidth >= 600 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (cols - 1) * 14) / cols;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: cards
              .map((c) => SizedBox(width: cardWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String subtitle,
    required String value,
    required String footer,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    bool highlighted = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: highlighted ? AppColors.mossMid : AppColors.borderSoft,
          width: highlighted ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF133021).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (highlighted) Container(height: 4, color: AppColors.mossPrimary),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: highlighted
                                  ? AppColors.mossPrimary
                                  : AppColors.inkSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 19, color: iconColor),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  footer,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChartCard(BaoCaoVanHanh bc) {
    final maxVal = bc.khungGio.fold<int>(
      1,
      (prev, s) => math.max(prev, math.max(s.giaTriDonVnd, s.thucThuVnd)),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu đồ doanh thu theo khung giờ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mossPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'So sánh thực thu đối chiếu với tổng giá trị đơn phát sinh theo ca làm',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(AppColors.mossPrimary, 'Thực thu'),
                  const SizedBox(width: 14),
                  _legendDot(const Color(0xFFD5DCD7), 'Giá trị đơn'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bc.khungGio.map((slot) {
                final govRatio = maxVal > 0 ? slot.giaTriDonVnd / maxVal : 0.0;
                final paidRatio = maxVal > 0 ? slot.thucThuVnd / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          slot.thucThuVnd > 0 ? _formatVnd(slot.thucThuVnd) : '0đ',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mossPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _barColumn(
                                  heightFactor: govRatio,
                                  color: const Color(0xFFD5DCD7),
                                ),
                                const SizedBox(width: 6),
                                _barColumn(
                                  heightFactor: paidRatio,
                                  color: AppColors.mossPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          slot.nhanHienThi,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                        Text(
                          '${slot.soDon} đơn',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _barColumn({required double heightFactor, required Color color}) {
    final safeFactor = heightFactor <= 0 ? 0.03 : heightFactor.clamp(0.06, 1.0);
    return FractionallySizedBox(
      heightFactor: safeFactor,
      child: Container(
        width: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildPaymentDonutCard(BaoCaoVanHanh bc) {
    final qr = bc.coCauThanhToan
        .where((e) => e.maPhuongThuc == 'vietqr')
        .firstOrNull;
    final cash = bc.coCauThanhToan
        .where((e) => e.maPhuongThuc == 'cash')
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Cơ cấu phương thức thu',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.mossPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Phân bổ dòng tiền đối soát qua cổng thanh toán',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 156,
              height: 156,
              child: CustomPaint(
                painter: _DonutPainter(
                  primaryRatio: (qr?.tyLePhanTram ?? 0) / 100.0,
                  secondaryRatio: (cash?.tyLePhanTram ?? 0) / 100.0,
                  primaryColor: AppColors.mossPrimary,
                  secondaryColor: _amberAccent,
                  trackColor: AppColors.daylightSubtle,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'THỰC THU',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatVnd(bc.thucTeDaThuVnd),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      Text(
                        '${bc.donDaThanhToan} đơn paid',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _paymentLegendRow(
            color: AppColors.mossPrimary,
            label: qr?.nhanHienThi ?? 'Chuyển khoản VietQR',
            value:
                '${_formatVnd(qr?.soTienVnd ?? 0)} (${(qr?.tyLePhanTram ?? 0).toStringAsFixed(0)}%)',
          ),
          const SizedBox(height: 8),
          _paymentLegendRow(
            color: _amberAccent,
            label: cash?.nhanHienThi ?? 'Tiền mặt tại quầy',
            value:
                '${_formatVnd(cash?.soTienVnd ?? 0)} (${(cash?.tyLePhanTram ?? 0).toStringAsFixed(0)}%)',
          ),
        ],
      ),
    );
  }

  Widget _paymentLegendRow({
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.daylightSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.mossPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopItemsTableCard(BaoCaoVanHanh bc) {
    final items = dieuKhien.topMonLoc;
    final headerStyle = GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AppColors.inkSecondary,
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top món bán chạy',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mossPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Thống kê sản lượng thực tế từ các đơn hàng đã chốt',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: dieuKhien.danhMucLoc,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.daylightSubtle,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả nhóm món'),
                    ),
                    ...bc.danhMuc.map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (v) => dieuKhien.chonDanhMucLoc(v ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu món bán ra trong khoảng thời gian đã chọn.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth > 760
                    ? constraints.maxWidth
                    : 760.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.daylightSubtle,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text('THỨ HẠNG', style: headerStyle),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('TÊN MÓN', style: headerStyle),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('DANH MỤC', style: headerStyle),
                              ),
                              SizedBox(
                                width: 110,
                                child: Text(
                                  'SỐ LƯỢNG BÁN',
                                  textAlign: TextAlign.right,
                                  style: headerStyle,
                                ),
                              ),
                              SizedBox(
                                width: 150,
                                child: Text(
                                  'DOANH SỐ',
                                  textAlign: TextAlign.right,
                                  style: headerStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...items.map((item) {
                          final isTop1 = item.thuHang == 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.borderSoft,
                                  width: 0.7,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isTop1
                                            ? AppColors.mossSoft
                                            : AppColors.daylightSubtle,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: Text(
                                        '#${item.thuHang}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isTop1
                                              ? AppColors.mossDeep
                                              : AppColors.inkSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.tenMon,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.inkPrimary,
                                        ),
                                      ),
                                      Text(
                                        item.maMon,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.danhMuc,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    '${item.soLuongBan}',
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    _formatVnd(item.doanhSoVnd),
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.mossPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.inkSecondary,
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double primaryRatio;
  final double secondaryRatio;
  final Color primaryColor;
  final Color secondaryColor;
  final Color trackColor;

  const _DonutPainter({
    required this.primaryRatio,
    required this.secondaryRatio,
    required this.primaryColor,
    required this.secondaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    double startAngle = -math.pi / 2;
    if (primaryRatio > 0) {
      final sweep = 2 * math.pi * primaryRatio.clamp(0.0, 1.0);
      final p = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, p);
      startAngle += sweep;
    }

    if (secondaryRatio > 0) {
      final sweep = 2 * math.pi * secondaryRatio.clamp(0.0, 1.0);
      final p = Paint()
        ..color = secondaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.primaryRatio != primaryRatio ||
      oldDelegate.secondaryRatio != secondaryRatio;
}
