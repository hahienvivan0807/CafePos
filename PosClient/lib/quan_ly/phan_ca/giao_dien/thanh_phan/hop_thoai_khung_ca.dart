import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../mo_hinh/du_lieu_phan_ca.dart';

/// Màn 29 & 33 · Modal Tạo mới / Chỉnh sửa Khung ca
/// - Khi sửa: khóa chỉ đọc Mã khung ca (bảo toàn DonHang.MaKhungCa)
/// - Tự động kiểm tra giờ kết thúc > giờ bắt đầu (trừ ca qua đêm) & cảnh báo trùng giờ với khung ca khác
class HopThoaiKhungCa extends StatefulWidget {
  final KhungCaMau? khungCa;
  final List<KhungCaMau> danhSachKhungCaHienCo;

  const HopThoaiKhungCa({
    super.key,
    this.khungCa,
    required this.danhSachKhungCaHienCo,
  });

  @override
  State<HopThoaiKhungCa> createState() => _HopThoaiKhungCaState();
}

class _HopThoaiKhungCaState extends State<HopThoaiKhungCa> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _maCtrl;
  late final TextEditingController _tenCtrl;
  late final TextEditingController _gioBatDauCtrl;
  late final TextEditingController _gioKetThucCtrl;
  late final TextEditingController _nghiPhutCtrl;
  late final TextEditingController _ghiChuCtrl;

  late bool _quaDem;
  late int _phaChe;
  late int _thuNgan;
  late int _phucVu;
  late bool _dangApDung;

  bool get _laChinhSua => widget.khungCa != null;

  @override
  void initState() {
    super.initState();
    final k = widget.khungCa;
    _maCtrl = TextEditingController(text: k?.ma ?? '');
    _tenCtrl = TextEditingController(text: k?.tenCa ?? '');
    _gioBatDauCtrl = TextEditingController(text: k?.gioBatDau ?? '07:00');
    _gioKetThucCtrl = TextEditingController(text: k?.gioKetThuc ?? '11:00');
    _nghiPhutCtrl = TextEditingController(text: '${k?.nghiGiuaCaPhut ?? 0}');
    _ghiChuCtrl = TextEditingController(text: k?.ghiChuBanGiao ?? '');
    _quaDem = k?.quaDem ?? false;
    _phaChe = k?.dinhBienPhaChe ?? 1;
    _thuNgan = k?.dinhBienThuNgan ?? 1;
    _phucVu = k?.dinhBienPhucVu ?? 1;
    _dangApDung = k?.dangApDung ?? true;
  }

  @override
  void dispose() {
    _maCtrl.dispose();
    _tenCtrl.dispose();
    _gioBatDauCtrl.dispose();
    _gioKetThucCtrl.dispose();
    _nghiPhutCtrl.dispose();
    _ghiChuCtrl.dispose();
    super.dispose();
  }

  int? _parseMinutes(String raw) {
    final parts = raw.trim().split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return h * 60 + m;
  }

  String? get _loiMocGio {
    final s = _parseMinutes(_gioBatDauCtrl.text);
    final e = _parseMinutes(_gioKetThucCtrl.text);
    if (s == null || e == null) {
      return 'Vui lòng nhập giờ đúng định dạng HH:mm (ví dụ 07:00, 14:30).';
    }
    if (!_quaDem && e <= s) {
      return 'Giờ kết thúc phải lớn hơn giờ bắt đầu (hoặc chọn “Ca kết thúc vào ngày hôm sau” đối với ca qua đêm).';
    }
    return null;
  }

  KhungCaMau? get _khungCaBiTrung {
    if (!_dangApDung || _loiMocGio != null) return null;
    final s1 = _parseMinutes(_gioBatDauCtrl.text)!;
    final e1 = _parseMinutes(_gioKetThucCtrl.text)! + (_quaDem ? 1440 : 0);
    final currentCode = widget.khungCa?.ma.toUpperCase();

    for (final other in widget.danhSachKhungCaHienCo) {
      if (!other.dangApDung) continue;
      if (currentCode != null && other.ma.toUpperCase() == currentCode) {
        continue;
      }
      final s2 = _parseMinutes(other.gioBatDau);
      final e2Raw = _parseMinutes(other.gioKetThuc);
      if (s2 == null || e2Raw == null) continue;
      final e2 = e2Raw + (other.quaDem ? 1440 : 0);
      if (s1 < e2 && s2 < e1) {
        return other;
      }
    }
    return null;
  }

  void _luu() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_loiMocGio != null) {
      setState(() {});
      return;
    }
    if (_khungCaBiTrung != null) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(
      DuLieuLuuKhungCa(
        ma: _maCtrl.text.trim().toUpperCase().replaceAll(' ', '_'),
        tenCa: _tenCtrl.text.trim(),
        gioBatDau: _gioBatDauCtrl.text.trim(),
        gioKetThuc: _gioKetThucCtrl.text.trim(),
        quaDem: _quaDem,
        nghiGiuaCaPhut: int.tryParse(_nghiPhutCtrl.text.trim()) ?? 0,
        dinhBienPhaChe: _phaChe,
        dinhBienThuNgan: _thuNgan,
        dinhBienPhucVu: _phucVu,
        dangApDung: _dangApDung,
        ghiChuBanGiao: _ghiChuCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loiGio = _loiMocGio;
    final caTrung = _khungCaBiTrung;

    return Dialog(
      backgroundColor: AppColors.daylightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.mossPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _laChinhSua
                                  ? 'Chỉnh sửa khung ca'
                                  : 'Tạo khung ca làm việc mới',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            if (_laChinhSua) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.mossSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '#${widget.khungCa!.ma}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mossDeep,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cập nhật thông tin khung ca mẫu, định biên nhân sự và trạng thái áp dụng',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoCols = constraints.maxWidth >= 640;
                      final col1 = _buildCol1(loiGio, caTrung);
                      final col2 = _buildCol2();
                      if (isTwoCols) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: col1),
                            const SizedBox(width: 20),
                            Expanded(child: col2),
                          ],
                        );
                      }
                      return Column(
                        children: [col1, const SizedBox(height: 18), col2],
                      );
                    },
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: AppColors.borderSoft),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.daylightSubtle,
                      foregroundColor: AppColors.inkSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Hủy bỏ'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('modal_khung_ca_btn_luu'),
                    onPressed: (loiGio != null || caTrung != null)
                        ? null
                        : _luu,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mossPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _laChinhSua ? 'Lưu thay đổi' : 'Lưu khung ca',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCol1(String? loiGio, KhungCaMau? caTrung) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '1. THÔNG TIN KHUNG CA & THỜI GIAN',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.mossPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Mã khung ca ${_laChinhSua ? "(Cố định)" : "*"}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _maCtrl,
          readOnly: _laChinhSua,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mã khung ca.' : null,
          decoration: _inputDeco(
            hint: 'VD: CA_DEM',
            readOnly: _laChinhSua,
            prefix: _laChinhSua ? Icons.lock_outline_rounded : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Mã khung ca cố định để bảo toàn tham chiếu hóa đơn (DonHang.MaKhungCa).',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            color: AppColors.inkMuted,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tên khung ca *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _tenCtrl,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập tên khung ca.'
              : null,
          decoration: _inputDeco(hint: 'VD: Ca Sáng · Mở quán'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giờ bắt đầu *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _gioBatDauCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDeco(
                      hint: '07:00',
                      prefix: Icons.schedule_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giờ kết thúc *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _gioKetThucCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: _inputDeco(
                      hint: '11:00',
                      prefix: Icons.history_toggle_off_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppColors.mossPrimary,
          value: _quaDem,
          onChanged: (v) => setState(() => _quaDem = v ?? false),
          title: Text(
            'Ca kết thúc vào ngày hôm sau (Qua đêm)',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
          ),
        ),
        if (loiGio != null) ...[
          const SizedBox(height: 6),
          _alertBox(isError: true, title: 'Sai lệch mốc thời gian', body: loiGio),
        ],
        if (caTrung != null) ...[
          const SizedBox(height: 6),
          _alertBox(
            isError: false,
            title: 'Cảnh báo xung đột khung giờ',
            body:
                'Giờ ca bị trùng với [${caTrung.tenCa}: ${caTrung.gioBatDau} - ${caTrung.gioKetThuc}]. Vui lòng điều chỉnh để không chồng chéo.',
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Nghỉ giữa ca (Phút)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nghiPhutCtrl,
          keyboardType: TextInputType.number,
          decoration: _inputDeco(hint: 'Ví dụ: 15 hoặc 30'),
        ),
      ],
    );
  }

  Widget _buildCol2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '2. ĐỊNH BIÊN NHÂN SỰ & TRẠNG THÁI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: AppColors.mossPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.daylightSubtle,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Định biên nhân sự tối thiểu (Số người)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _quotaRow(
                label: 'Pha chế (Barista)',
                value: _phaChe,
                onChanged: (v) => setState(() => _phaChe = v),
              ),
              const SizedBox(height: 8),
              _quotaRow(
                label: 'Thu ngân (Cashier)',
                value: _thuNgan,
                onChanged: (v) => setState(() => _thuNgan = v),
              ),
              const SizedBox(height: 8),
              _quotaRow(
                label: 'Phục vụ (Floor)',
                value: _phucVu,
                onChanged: (v) => setState(() => _phucVu = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Trạng thái áp dụng *',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<bool>(
          isExpanded: true,
          initialValue: _dangApDung,
          decoration: _inputDeco(hint: 'Chọn trạng thái'),
          items: const [
            DropdownMenuItem(value: true, child: Text('Đang áp dụng')),
            DropdownMenuItem(value: false, child: Text('Ngừng sử dụng')),
          ],
          onChanged: (v) => setState(() => _dangApDung = v ?? true),
        ),
        const SizedBox(height: 14),
        Text(
          'Ghi chú bàn giao',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _ghiChuCtrl,
          maxLines: 3,
          decoration: _inputDeco(
            hint: 'Ghi chú công việc bàn giao giữa ca...',
          ),
        ),
      ],
    );
  }

  Widget _quotaRow({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.mossPrimary,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _alertBox({
    required bool isError,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isError ? AppColors.dangerBg : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? AppColors.dangerBorder : const Color(0xFFFFB77D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
            size: 18,
            color: isError ? AppColors.danger : const Color(0xFF904D00),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isError ? AppColors.danger : const Color(0xFF6E3900),
                  ),
                ),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({
    required String hint,
    bool readOnly = false,
    IconData? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: readOnly ? AppColors.daylightSubtle : Colors.white,
      prefixIcon: prefix != null
          ? Icon(prefix, size: 18, color: AppColors.inkMuted)
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: AppColors.mossPrimary, width: 1.5),
      ),
    );
  }
}
