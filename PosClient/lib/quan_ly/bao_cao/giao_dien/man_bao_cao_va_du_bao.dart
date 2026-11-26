import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../nen_tang/giao_dien/bang_mau.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../dich_vu/dich_vu_bao_cao.dart';
import '../dieu_khien/dieu_khien_bao_cao.dart';
import 'thanh_phan/tab_bao_cao_van_hanh.dart';
import 'thanh_phan/tab_du_bao_ai.dart';

/// Màn Báo cáo kinh doanh & Dự báo vận hành (Daylight AI) cho Quản lý
class ManBaoCaoVaDuBao extends StatefulWidget {
  final PosAuthApiClient apiClient;
  final bool isDesktop;
  final int initialTabIndex;

  const ManBaoCaoVaDuBao({
    super.key,
    required this.apiClient,
    required this.isDesktop,
    this.initialTabIndex = 0,
  });

  @override
  State<ManBaoCaoVaDuBao> createState() => _ManBaoCaoVaDuBaoState();
}

class _ManBaoCaoVaDuBaoState extends State<ManBaoCaoVaDuBao> {
  late final DieuKhienBaoCao _dieuKhien;

  @override
  void initState() {
    super.initState();
    _dieuKhien = DieuKhienBaoCao(
      dichVu: DichVuBaoCao(apiClient: widget.apiClient),
      initialTabIndex: widget.initialTabIndex,
    )..khoiTao();
  }

  @override
  void dispose() {
    _dieuKhien.dispose();
    super.dispose();
  }

  Future<void> _chonKhoangNgay({required bool choDuBao}) async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: choDuBao ? _dieuKhien.tuNgayDuBao : _dieuKhien.tuNgayBaoCao,
      end: choDuBao ? _dieuKhien.denNgayDuBao : _dieuKhien.denNgayBaoCao,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      initialDateRange: initialRange,
      helpText: 'Chọn khoảng thời gian phân tích',
      cancelText: 'Hủy',
      confirmText: 'Áp dụng',
    );

    if (picked == null || !mounted) return;
    if (choDuBao) {
      await _dieuKhien.datKhoangNgayDuBao(picked.start, picked.end);
    } else {
      await _dieuKhien.datKhoangNgayBaoCao(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _dieuKhien,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Context Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 14,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHÂN TÍCH CHUYÊN SÂU · DỮ LIỆU THẬT POSTGRESQL',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: const Color(0xFF904D00),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Báo cáo kinh doanh & Dự báo vận hành',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: widget.isDesktop ? 26 : 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.mossPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('bao_cao_btn_lam_moi'),
                        onPressed:
                            (_dieuKhien.dangTaiBaoCao ||
                                _dieuKhien.dangTaiDuBao)
                            ? null
                            : _dieuKhien.lamMoiTatCa,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.inkPrimary,
                          backgroundColor: AppColors.daylightSurface,
                          side: const BorderSide(color: AppColors.borderSoft),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Làm mới'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // View Mode Switcher + Timeframe Bar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.daylightSubtle,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    // 2 Mode Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.daylightSurface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _modeTabButton(
                            keyName: 'tab_bao_cao_van_hanh',
                            selected: _dieuKhien.tabDangChon == 0,
                            icon: Icons.query_stats_rounded,
                            label: 'Báo cáo kết quả vận hành',
                            onTap: () => _dieuKhien.chonTab(0),
                          ),
                          const SizedBox(width: 4),
                          _modeTabButton(
                            keyName: 'tab_du_bao_ai',
                            selected: _dieuKhien.tabDangChon == 1,
                            icon: Icons.auto_graph_rounded,
                            label: 'Dự báo (Daylight AI)',
                            badge: 'BETA',
                            onTap: () => _dieuKhien.chonTab(1),
                          ),
                        ],
                      ),
                    ),

                    // Timeframe filters for Tab 1
                    if (_dieuKhien.tabDangChon == 0)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _periodChip(
                            label: 'Hôm nay',
                            selected: _dieuKhien.kyBaoCao == KyBaoCao.homNay,
                            onTap: () =>
                                _dieuKhien.chonKyBaoCao(KyBaoCao.homNay),
                          ),
                          _periodChip(
                            label: '7 ngày qua',
                            selected:
                                _dieuKhien.kyBaoCao == KyBaoCao.bayNgayQua,
                            onTap: () =>
                                _dieuKhien.chonKyBaoCao(KyBaoCao.bayNgayQua),
                          ),
                          _periodChip(
                            label: 'Tháng này',
                            selected: _dieuKhien.kyBaoCao == KyBaoCao.thangNay,
                            onTap: () =>
                                _dieuKhien.chonKyBaoCao(KyBaoCao.thangNay),
                          ),
                          _periodChip(
                            label: 'Tùy chọn ngày',
                            icon: Icons.calendar_today_rounded,
                            selected: _dieuKhien.kyBaoCao == KyBaoCao.tuyChon,
                            onTap: () => _chonKhoangNgay(choDuBao: false),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_dieuKhien.tabDangChon == 0)
                TabBaoCaoVanHanh(
                  dieuKhien: _dieuKhien,
                  isDesktop: widget.isDesktop,
                )
              else
                TabDuBaoAi(
                  dieuKhien: _dieuKhien,
                  isDesktop: widget.isDesktop,
                  onChonKhoangNgay: () => _chonKhoangNgay(choDuBao: true),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeTabButton({
    required String keyName,
    required bool selected,
    required IconData icon,
    required String label,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: Key(keyName),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.mossPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : AppColors.inkSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.inkSecondary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDCC3),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2F1500),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _periodChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.mossPrimary : AppColors.daylightSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.mossPrimary : AppColors.borderSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.inkSecondary,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
