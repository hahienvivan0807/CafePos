import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../dieu_khien/dieu_khien_phan_ca.dart';
import '../../mo_hinh/du_lieu_phan_ca.dart';
import 'hop_thoai_xac_nhan_huy_ca.dart';

/// Màn 30 · Modal Phân công nhân viên vào ca
class HopThoaiPhanCongCa extends StatefulWidget {
  final DieuKhienPhanCa dieuKhien;
  final DateTime ngayLam;
  final KhungCaMau khungCa;

  const HopThoaiPhanCongCa({
    super.key,
    required this.dieuKhien,
    required this.ngayLam,
    required this.khungCa,
  });

  @override
  State<HopThoaiPhanCongCa> createState() => _HopThoaiPhanCongCaState();
}

class _HopThoaiPhanCongCaState extends State<HopThoaiPhanCongCa> {
  String? _selectedStaffId;
  String _selectedPosition = 'PhaChe';
  late final TextEditingController _gioVaoCtrl;
  late final TextEditingController _gioRaCtrl;
  String? _thongBao;
  bool _laLoi = false;

  @override
  void initState() {
    super.initState();
    _gioVaoCtrl = TextEditingController(text: widget.khungCa.gioBatDau);
    _gioRaCtrl = TextEditingController(text: widget.khungCa.gioKetThuc);
  }

  @override
  void dispose() {
    _gioVaoCtrl.dispose();
    _gioRaCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _themNhanVien() async {
    if (_selectedStaffId == null || _selectedStaffId!.isEmpty) {
      setState(() {
        _laLoi = true;
        _thongBao = 'Vui lòng chọn nhân viên đang hoạt động.';
      });
      return;
    }

    final res = await widget.dieuKhien.ganNhanVien(
      ngayLam: widget.ngayLam,
      maKhungCa: widget.khungCa.ma,
      idNhanVien: _selectedStaffId!,
      viTri: _selectedPosition,
      gioVao: _gioVaoCtrl.text,
      gioRa: _gioRaCtrl.text,
    );

    if (!mounted) return;
    setState(() {
      _laLoi = !res.isSuccess;
      _thongBao = res.message;
      if (res.isSuccess) {
        _selectedStaffId = null;
      }
    });
  }

  Future<void> _huyPhanCong(PhanCongCa pc) async {
    final canLyDo = pc.trangThaiTuan == 'DaCongBo';
    final lyDo = await showDialog<String>(
      context: context,
      builder: (_) => HopThoaiXacNhanHuyCa(
        doiTuong:
            '${widget.khungCa.tenCa} (${_formatDate(widget.ngayLam)}) · ${pc.tenNhanVien}',
        trangThaiHienTai: canLyDo ? 'Đã công bố' : 'Bản nháp',
        nhanSuAnhHuong: ['${pc.tenNhanVien} (${pc.nhanViTri})'],
        batBuocLyDo: canLyDo,
        nhanNutXacNhan: 'Xác nhận hủy phân công',
      ),
    );
    if (lyDo == null || !mounted) return;

    final res = await widget.dieuKhien.huyPhanCong(pc.id, lyDo: lyDo);
    if (!mounted) return;
    setState(() {
      _laLoi = !res.isSuccess;
      _thongBao = res.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.dieuKhien,
      builder: (context, _) {
        final assigned = widget.dieuKhien.phanCongChoO(
          widget.ngayLam,
          widget.khungCa.ma,
        );
        final activeStaff =
            widget.dieuKhien.lichTuan?.nhanVienSanSang ?? const [];
        final duDinhBien = assigned.length >= widget.khungCa.tongDinhBien;

        return Dialog(
          backgroundColor: AppColors.daylightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780, maxHeight: 740),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.mossSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: AppColors.mossPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phân công nhân viên vào ca',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            Text(
                              '${widget.khungCa.tenCa} · ${_formatDate(widget.ngayLam)} (${widget.khungCa.gioBatDau} — ${widget.khungCa.gioKetThuc})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: duDinhBien
                              ? AppColors.mossSoft
                              : const Color(0xFFFFECCE),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${assigned.length}/${widget.khungCa.tongDinhBien} nhân sự',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: duDinhBien
                                ? AppColors.mossDeep
                                : const Color(0xFF904D00),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.borderSoft),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Assigned list
                        Text(
                          '1. DANH SÁCH NHÂN SỰ ĐÃ PHÂN CÔNG (${assigned.length})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.mossPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (assigned.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.daylightSubtle,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Chưa có nhân viên nào được phân công vào ca này. Sử dụng biểu mẫu bên dưới để gán nhanh.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          )
                        else
                          ...assigned.map((pc) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.daylightSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderSoft),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${pc.tenNhanVien} (${pc.maNhanVien})',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.inkPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${pc.nhanViTri} · ${pc.gioVao} – ${pc.gioRa} (${pc.thoiLuongGio}h) · ${pc.trangThaiTuan == 'DaCongBo' ? 'Đã công bố' : 'Bản nháp'}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.inkSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: widget.dieuKhien.dangThaoTac
                                        ? null
                                        : () => _huyPhanCong(pc),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('Gỡ'),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 18),

                        // 2. Quick Add Form
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.daylightSubtle,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '2. THÊM NHÂN VIÊN VÀO CA',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: AppColors.inkPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  SizedBox(
                                    width: 240,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _selectedStaffId,
                                      hint: const Text('Chọn nhân viên...'),
                                      decoration: _deco('Nhân viên hoạt động'),
                                      items: activeStaff
                                          .map(
                                            (nv) => DropdownMenuItem(
                                              value: nv.id,
                                              child: Text(
                                                '${nv.hoTen} (${nv.maNhanVien})',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _selectedStaffId = v),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 170,
                                    child: DropdownButtonFormField<String>(
                                      isExpanded: true,
                                      initialValue: _selectedPosition,
                                      decoration: _deco('Vị trí đảm nhận'),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'PhaChe',
                                          child: Text('Pha chế'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'ThuNgan',
                                          child: Text('Thu ngân'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'PhucVu',
                                          child: Text('Phục vụ'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'TruongCa',
                                          child: Text('Trưởng ca'),
                                        ),
                                      ],
                                      onChanged: (v) => setState(
                                        () => _selectedPosition = v ?? 'PhaChe',
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _gioVaoCtrl,
                                      decoration: _deco('Giờ vào'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 100,
                                    child: TextField(
                                      controller: _gioRaCtrl,
                                      decoration: _deco('Giờ ra'),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: widget.dieuKhien.dangThaoTac
                                        ? null
                                        : _themNhanVien,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.mossPrimary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(11),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 18),
                                    label: const Text('Gán ca'),
                                  ),
                                ],
                              ),
                              if (_thongBao != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _thongBao!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _laLoi
                                        ? AppColors.danger
                                        : AppColors.mossDeep,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderSoft),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mossPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Hoàn tất'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
    );
  }
}
