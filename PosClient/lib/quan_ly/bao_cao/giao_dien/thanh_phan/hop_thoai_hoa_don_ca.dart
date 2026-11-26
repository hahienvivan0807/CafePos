import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../dich_vu/dich_vu_bao_cao.dart';
import '../../mo_hinh/du_lieu_bao_cao.dart';

String _formatVndHelper(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final posFromEnd = s.length - i;
    buf.write(s[i]);
    if (posFromEnd > 1 && posFromEnd % 3 == 1) {
      buf.write('.');
    }
  }
  return '${amount < 0 ? '-' : ''}${buf.toString()}đ';
}

String _formatDateTimeHelper(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  final mo = d.month.toString().padLeft(2, '0');
  return '$hh:$mm · $dd/$mo/${d.year}';
}

({String label, Color bg, Color fg}) _statusBadgeInfo(String status) {
  switch (status.toLowerCase()) {
    case 'paid':
      return (
        label: 'Đã thanh toán',
        bg: AppColors.mossSoft,
        fg: AppColors.mossDeep,
      );
    case 'awaiting_payment':
      return (
        label: 'Chờ VietQR',
        bg: const Color(0xFFFFECCE),
        fg: const Color(0xFF904D00),
      );
    default:
      return (
        label: 'Đang mở',
        bg: AppColors.daylightSubtle,
        fg: AppColors.inkSecondary,
      );
  }
}

/// Modal 1: Danh sách hóa đơn trong 1 ca làm việc
class HopThoaiHoaDonCa extends StatefulWidget {
  final DichVuBaoCao dichVu;
  final String maCa;
  final String tenCa;
  final DateTime tuNgay;
  final DateTime denNgay;

  const HopThoaiHoaDonCa({
    super.key,
    required this.dichVu,
    required this.maCa,
    required this.tenCa,
    required this.tuNgay,
    required this.denNgay,
  });

  @override
  State<HopThoaiHoaDonCa> createState() => _HopThoaiHoaDonCaState();
}

class _HopThoaiHoaDonCaState extends State<HopThoaiHoaDonCa> {
  bool _dangTai = true;
  String? _loi;
  DanhSachHoaDonCa? _duLieu;

  @override
  void initState() {
    super.initState();
    _taiDanhSach();
  }

  Future<void> _taiDanhSach() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final res = await widget.dichVu.layHoaDonTheoCa(
      maCa: widget.maCa,
      tuNgay: widget.tuNgay,
      denNgay: widget.denNgay,
    );
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      if (res.isSuccess && res.data != null) {
        _duLieu = res.data;
      } else {
        _loi = res.message;
      }
    });
  }

  void _moChiTietHoaDon(HoaDonTrongCa hd) {
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xFF133021).withValues(alpha: 0.42),
      builder: (_) => HopThoaiChiTietHoaDon(
        dichVu: widget.dichVu,
        orderId: hd.idDonHang,
        maDonHang: hd.maDonHang,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = _duLieu?.danhSachHoaDon ?? const <HoaDonTrongCa>[];
    return Dialog(
      backgroundColor: AppColors.daylightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HÓA ĐƠN TRONG CA LÀM VIỆC',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.mossMid,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _duLieu?.tenCa ?? widget.tenCa,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        if (_duLieu != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${ds.length} hóa đơn · Thực thu: ${_formatVndHelper(_duLieu!.tongDaThuVnd)} / Tổng đơn: ${_formatVndHelper(_duLieu!.tongGiaTriVnd)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 12),
              Flexible(
                child: _dangTai
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.mossPrimary,
                          ),
                        ),
                      )
                    : _loi != null
                    ? Center(
                        child: Text(
                          _loi!,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ds.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'Chưa có hóa đơn nào trong ca này ở khoảng thời gian đã chọn.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: ds.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final hd = ds[index];
                          final badge = _statusBadgeInfo(hd.trangThai);
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _moChiTietHoaDon(hd),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.daylightSubtle,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.borderSoft),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.borderSoft,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long_rounded,
                                      size: 20,
                                      color: AppColors.mossPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              hd.maDonHang,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.inkPrimary,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: badge.bg,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                badge.label,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: badge.fg,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${hd.tenBan} · ${hd.tenNhanVien} · ${_formatDateTimeHelper(hd.taoLuc)} · ${hd.tongSoMon} món',
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.inkSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatVndHelper(hd.tongTienVnd),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.mossPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Xem chi tiết ›',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal 2: Chi tiết hóa đơn (từng dòng món, nhân viên, bàn, tổng tiền)
class HopThoaiChiTietHoaDon extends StatefulWidget {
  final DichVuBaoCao dichVu;
  final int orderId;
  final String maDonHang;

  const HopThoaiChiTietHoaDon({
    super.key,
    required this.dichVu,
    required this.orderId,
    required this.maDonHang,
  });

  @override
  State<HopThoaiChiTietHoaDon> createState() => _HopThoaiChiTietHoaDonState();
}

class _HopThoaiChiTietHoaDonState extends State<HopThoaiChiTietHoaDon> {
  bool _dangTai = true;
  String? _loi;
  ChiTietHoaDonBaoCao? _chiTiet;

  @override
  void initState() {
    super.initState();
    _taiChiTiet();
  }

  Future<void> _taiChiTiet() async {
    final res = await widget.dichVu.layChiTietHoaDon(widget.orderId);
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      if (res.isSuccess && res.data != null) {
        _chiTiet = res.data;
      } else {
        _loi = res.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ct = _chiTiet;
    return Dialog(
      backgroundColor: AppColors.daylightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CHI TIẾT HÓA ĐƠN',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                            color: AppColors.mossMid,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ct?.maDonHang ?? widget.maDonHang,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 12),
              if (_dangTai)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.mossPrimary,
                    ),
                  ),
                )
              else if (_loi != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    _loi!,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (ct != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.daylightSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _infoRow('Bàn phục vụ', '${ct.tenBan} (${ct.maBan})'),
                      const SizedBox(height: 6),
                      _infoRow('Nhân viên lập đơn', ct.tenNhanVien),
                      const SizedBox(height: 6),
                      _infoRow('Thời gian tạo', _formatDateTimeHelper(ct.taoLuc)),
                      if (ct.thanhToanLuc != null) ...[
                        const SizedBox(height: 6),
                        _infoRow(
                          'Thanh toán lúc',
                          _formatDateTimeHelper(ct.thanhToanLuc!),
                        ),
                      ],
                      const SizedBox(height: 6),
                      _infoRow(
                        'Trạng thái',
                        _statusBadgeInfo(ct.trangThai).label,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'DANH SÁCH MÓN (${ct.danhSachMon.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: ct.danhSachMon.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borderSoft),
                    itemBuilder: (_, idx) {
                      final m = ct.danhSachMon[idx];
                      final biHuy =
                          m.trangThaiHuy?.toLowerCase() == 'approved';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.tenMon,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      decoration: biHuy
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: biHuy
                                          ? AppColors.inkMuted
                                          : AppColors.inkPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${_formatVndHelper(m.donGiaVnd)} × ${m.soLuong}${m.ghiChu != null && m.ghiChu!.isNotEmpty ? ' · ${m.ghiChu}' : ''}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.inkSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatVndHelper(m.thanhTienVnd),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                decoration: biHuy
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: biHuy
                                    ? AppColors.inkMuted
                                    : AppColors.mossPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderSoft),
                const SizedBox(height: 12),
                _infoRow(
                  'Tổng hóa đơn',
                  _formatVndHelper(ct.tongTienVnd),
                  bold: true,
                ),
                const SizedBox(height: 4),
                _infoRow(
                  'Đã thanh toán',
                  _formatVndHelper(ct.daThanhToanVnd),
                  valueColor: AppColors.mossDeep,
                ),
                if (ct.conLaiVnd > 0) ...[
                  const SizedBox(height: 4),
                  _infoRow(
                    'Còn lại chưa thu',
                    _formatVndHelper(ct.conLaiVnd),
                    valueColor: AppColors.danger,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: bold ? 14 : 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.inkSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: bold ? 16 : 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: valueColor ?? AppColors.inkPrimary,
          ),
        ),
      ],
    );
  }
}
