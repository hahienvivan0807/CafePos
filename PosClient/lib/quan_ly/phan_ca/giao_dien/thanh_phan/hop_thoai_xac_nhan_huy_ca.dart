import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';

/// Màn 31 · Modal Xác nhận xóa / hủy ca hoặc ngừng sử dụng khung ca (kèm Lý do bắt buộc)
class HopThoaiXacNhanHuyCa extends StatefulWidget {
  final String doiTuong;
  final String trangThaiHienTai;
  final List<String> nhanSuAnhHuong;
  final bool batBuocLyDo;
  final String nhanNutXacNhan;

  const HopThoaiXacNhanHuyCa({
    super.key,
    required this.doiTuong,
    required this.trangThaiHienTai,
    required this.nhanSuAnhHuong,
    this.batBuocLyDo = true,
    this.nhanNutXacNhan = 'Xác nhận hủy / Ngừng sử dụng',
  });

  @override
  State<HopThoaiXacNhanHuyCa> createState() => _HopThoaiXacNhanHuyCaState();
}

class _HopThoaiXacNhanHuyCaState extends State<HopThoaiXacNhanHuyCa> {
  final TextEditingController _lyDoCtrl = TextEditingController();
  String? _loi;

  @override
  void dispose() {
    _lyDoCtrl.dispose();
    super.dispose();
  }

  void _xacNhan() {
    final lyDo = _lyDoCtrl.text.trim();
    if (widget.batBuocLyDo && lyDo.length < 5) {
      setState(() {
        _loi = 'Vui lòng nhập lý do tối thiểu 5 ký tự để lưu vết kiểm toán.';
      });
      return;
    }
    Navigator.of(context).pop(lyDo);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.daylightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECCE),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFF904D00),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xác nhận thay đổi lịch / Khung ca',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vui lòng xác nhận hành động đối với ca làm việc hoặc khung ca đã chọn.',
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.daylightSubtle,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Đối tượng', widget.doiTuong),
                    const SizedBox(height: 6),
                    _row('Trạng thái hiện tại', widget.trangThaiHienTai),
                    if (widget.nhanSuAnhHuong.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Nhân sự liên quan:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.nhanSuAnhHuong
                            .map(
                              (n) => Chip(
                                label: Text(
                                  n,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Lý do hủy / thay đổi ${widget.batBuocLyDo ? "*" : "(tùy chọn)"}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _lyDoCtrl,
                maxLines: 3,
                maxLength: 250,
                onChanged: (_) {
                  if (_loi != null) setState(() => _loi = null);
                },
                decoration: InputDecoration(
                  hintText:
                      'Nhập lý do chi tiết để lưu vết kiểm toán và thông báo nhân viên...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSoft),
                  ),
                ),
              ),
              if (_loi != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _loi!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Quay lại / Giữ nguyên'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _xacNhan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(widget.nhanNutXacNhan),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.inkSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
