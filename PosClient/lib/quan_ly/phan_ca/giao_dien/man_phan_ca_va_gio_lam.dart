import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../nen_tang/giao_dien/bang_mau.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../dich_vu/dich_vu_phan_ca.dart';
import '../dieu_khien/dieu_khien_phan_ca.dart';
import '../mo_hinh/du_lieu_phan_ca.dart';
import 'thanh_phan/hop_thoai_khung_ca.dart';
import 'thanh_phan/hop_thoai_phan_cong_ca.dart';
import 'thanh_phan/hop_thoai_xac_nhan_huy_ca.dart';
import 'thanh_phan/tab_khung_ca.dart';
import 'thanh_phan/tab_lich_phan_ca.dart';

/// Màn Phân ca & Giờ làm (Màn 28, 29, 30, 31, 32, 33)
class ManPhanCaVaGioLam extends StatefulWidget {
  final PosAuthApiClient apiClient;
  final bool isDesktop;

  const ManPhanCaVaGioLam({
    super.key,
    required this.apiClient,
    required this.isDesktop,
  });

  @override
  State<ManPhanCaVaGioLam> createState() => _ManPhanCaVaGioLamState();
}

class _ManPhanCaVaGioLamState extends State<ManPhanCaVaGioLam> {
  late final DieuKhienPhanCa _dieuKhien;

  @override
  void initState() {
    super.initState();
    _dieuKhien = DieuKhienPhanCa(
      dichVu: DichVuPhanCa(apiClient: widget.apiClient),
    )..khoiTao();
  }

  @override
  void dispose() {
    _dieuKhien.dispose();
    super.dispose();
  }

  void _hienThongBao(String msg, {bool laLoi = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 480,
        backgroundColor: laLoi ? AppColors.danger : AppColors.mossDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _moThemKhungCa() async {
    final duLieu = await showDialog<DuLieuLuuKhungCa>(
      context: context,
      builder: (_) => HopThoaiKhungCa(
        danhSachKhungCaHienCo: _dieuKhien.danhSachKhungCaHienThi,
      ),
    );
    if (duLieu == null || !mounted) return;
    final res = await _dieuKhien.taoKhungCa(duLieu);
    if (!mounted) return;
    _hienThongBao(res.message, laLoi: !res.isSuccess);
  }

  Future<void> _moSuaKhungCa(KhungCaMau k) async {
    final duLieu = await showDialog<DuLieuLuuKhungCa>(
      context: context,
      builder: (_) => HopThoaiKhungCa(
        khungCa: k,
        danhSachKhungCaHienCo: _dieuKhien.danhSachKhungCaHienThi,
      ),
    );
    if (duLieu == null || !mounted) return;
    final res = await _dieuKhien.suaKhungCa(k.ma, duLieu);
    if (!mounted) return;
    _hienThongBao(res.message, laLoi: !res.isSuccess);
  }

  Future<void> _moXoaHoacNgungKhungCa(KhungCaMau k) async {
    final lyDo = await showDialog<String>(
      context: context,
      builder: (_) => HopThoaiXacNhanHuyCa(
        doiTuong: '${k.tenCa} (${k.ma} · ${k.gioBatDau} - ${k.gioKetThuc})',
        trangThaiHienTai: k.dangApDung ? 'Đang áp dụng' : 'Ngừng sử dụng',
        nhanSuAnhHuong: k.daCoLichSu
            ? const ['Đã liên kết hóa đơn / lịch trực (sẽ chuyển Ngừng sử dụng)']
            : const [],
        batBuocLyDo: k.daCoLichSu,
        nhanNutXacNhan: k.daCoLichSu
            ? 'Xác nhận ngừng sử dụng'
            : 'Xác nhận xóa khung ca',
      ),
    );
    if (lyDo == null || !mounted) return;
    final res = await _dieuKhien.xoaHoacNgungKhungCa(k.ma, lyDo: lyDo);
    if (!mounted) return;
    _hienThongBao(res.message, laLoi: !res.isSuccess);
  }

  Future<void> _moPhanCongCa(DateTime ngay, KhungCaMau ca) async {
    await showDialog<void>(
      context: context,
      builder: (_) => HopThoaiPhanCongCa(
        dieuKhien: _dieuKhien,
        ngayLam: ngay,
        khungCa: ca,
      ),
    );
  }

  Future<void> _congBoTuan() async {
    final res = await _dieuKhien.congBoTuan();
    if (!mounted) return;
    _hienThongBao(res.message, laLoi: !res.isSuccess);
  }

  Future<void> _saoChepTuanTruoc() async {
    final res = await _dieuKhien.saoChepTuanTruoc();
    if (!mounted) return;
    _hienThongBao(res.message, laLoi: !res.isSuccess);
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
              // Header + Dual Tab Switcher
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
                        'VẬN HÀNH & NHÂN SỰ · QUY CHUẨN TRẠM POS',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: AppColors.mossMid,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phân ca & Giờ làm',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: widget.isDesktop ? 26 : 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.daylightSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _tabBtn(
                          selected: _dieuKhien.tabDangChon == 0,
                          icon: Icons.calendar_view_week_rounded,
                          label: 'Lịch phân ca',
                          onTap: () => _dieuKhien.chonTab(0),
                        ),
                        const SizedBox(width: 4),
                        _tabBtn(
                          selected: _dieuKhien.tabDangChon == 1,
                          icon: Icons.tune_rounded,
                          label: 'Khung ca (${_dieuKhien.soKhungCaDangApDung})',
                          onTap: () => _dieuKhien.chonTab(1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              if (_dieuKhien.tabDangChon == 0)
                TabLichPhanCa(
                  dieuKhien: _dieuKhien,
                  onMoPhanCong: _moPhanCongCa,
                  onCongBoTuan: _congBoTuan,
                  onSaoChepTuanTruoc: _saoChepTuanTruoc,
                )
              else
                TabKhungCa(
                  dieuKhien: _dieuKhien,
                  onThemKhungCa: _moThemKhungCa,
                  onSuaKhungCa: _moSuaKhungCa,
                  onXoaHoacNgungKhungCa: _moXoaHoacNgungKhungCa,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabBtn({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.mossPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
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
          ],
        ),
      ),
    );
  }
}
