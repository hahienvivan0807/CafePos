import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../mo_hinh/ho_so_nhan_vien.dart';

/// Modal 26 · Chỉnh sửa nhân viên (bám sát thiết kế Google Stitch)
/// - Header kèm nhãn "Hồ sơ trạm máy POS" + tiêu đề "Chỉnh sửa nhân viên"
/// - Nhóm 1: 1. THÔNG TIN NHÂN VIÊN (Mã nhân viên chỉ đọc có icon khóa, Họ và tên *, Số điện thoại *)
/// - Nhóm 2: 2. TÀI KHOẢN POS (Tên đăng nhập chỉ đọc có icon khóa, Vai trò *, Trạng thái *)
/// - Nhóm 3: 3. ĐẶT LẠI MẬT KHẨU (Mật khẩu mới, Xác nhận mật khẩu mới & nút đổi ngay)
/// - Hộp ghi chú tự động điền từ hệ thống & 2 nút Hủy bỏ / Lưu thay đổi
class HopThoaiSuaNhanVien extends StatefulWidget {
  final HoSoNhanVien? nhanVien;
  final Future<ApiResult<bool>> Function(
    String matKhauMoi,
    String xacNhanMatKhau,
  )?
  onResetPassword;

  const HopThoaiSuaNhanVien({super.key, this.nhanVien, this.onResetPassword});

  @override
  State<HopThoaiSuaNhanVien> createState() => _HopThoaiSuaNhanVienState();
}

class _HopThoaiSuaNhanVienState extends State<HopThoaiSuaNhanVien> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _maNhanVienCtrl;
  late final TextEditingController _hoTenCtrl;
  late final TextEditingController _soDienThoaiCtrl;
  late final TextEditingController _tenDangNhapCtrl;
  final TextEditingController _matKhauMoiCtrl = TextEditingController();
  final TextEditingController _xacNhanMatKhauCtrl = TextEditingController();

  String? _vaiTro;
  String? _trangThai;
  String? _thongBaoKiemTra;

  bool _hienFormDatLaiMatKhau = false;
  bool _anMatKhauMoi = true;
  bool _anXacNhanMatKhau = true;
  bool _dangDatLaiMatKhau = false;
  String? _thongBaoMatKhau;
  bool _loiMatKhau = false;

  @override
  void initState() {
    super.initState();
    final nv = widget.nhanVien;
    _maNhanVienCtrl = TextEditingController(text: nv?.maNhanVien ?? '');
    _hoTenCtrl = TextEditingController(text: nv?.hoTen ?? '');
    _soDienThoaiCtrl = TextEditingController(text: nv?.soDienThoai ?? '');
    _tenDangNhapCtrl = TextEditingController(text: nv?.tenDangNhap ?? '');
    _vaiTro = nv?.vaiTro;
    _trangThai = nv?.trangThai;
  }

  @override
  void dispose() {
    _maNhanVienCtrl.dispose();
    _hoTenCtrl.dispose();
    _soDienThoaiCtrl.dispose();
    _tenDangNhapCtrl.dispose();
    _matKhauMoiCtrl.dispose();
    _xacNhanMatKhauCtrl.dispose();
    super.dispose();
  }

  Future<void> _xuLyDatLaiMatKhau() async {
    if (_dangDatLaiMatKhau || widget.onResetPassword == null) return;

    final matKhauMoi = _matKhauMoiCtrl.text;
    final xacNhan = _xacNhanMatKhauCtrl.text;

    if (matKhauMoi.isEmpty) {
      setState(() {
        _loiMatKhau = true;
        _thongBaoMatKhau = 'Vui lòng nhập mật khẩu mới.';
      });
      return;
    }

    if (matKhauMoi.length < 6 || !RegExp(r'\d').hasMatch(matKhauMoi)) {
      setState(() {
        _loiMatKhau = true;
        _thongBaoMatKhau =
            'Mật khẩu mới phải có tối thiểu 6 ký tự và chứa ít nhất 1 chữ số.';
      });
      return;
    }

    if (matKhauMoi != xacNhan) {
      setState(() {
        _loiMatKhau = true;
        _thongBaoMatKhau = 'Mật khẩu xác nhận không khớp với mật khẩu mới.';
      });
      return;
    }

    setState(() {
      _dangDatLaiMatKhau = true;
      _thongBaoMatKhau = null;
      _loiMatKhau = false;
    });

    final ketQua = await widget.onResetPassword!(matKhauMoi, xacNhan);
    if (!mounted) return;

    setState(() {
      _dangDatLaiMatKhau = false;
      _loiMatKhau = !ketQua.isSuccess;
      _thongBaoMatKhau = ketQua.message;
      if (ketQua.isSuccess) {
        _matKhauMoiCtrl.clear();
        _xacNhanMatKhauCtrl.clear();
      }
    });
  }

  void _xuLyLuuThayDoi() {
    final hopLeForm = _formKey.currentState?.validate() ?? false;
    if (!hopLeForm || _vaiTro == null || _trangThai == null) {
      setState(() {
        if (_vaiTro == null || _trangThai == null) {
          _thongBaoKiemTra =
              'Vui lòng chọn đầy đủ Vai trò và Trạng thái tài khoản POS.';
        } else {
          _thongBaoKiemTra = null;
        }
      });
      return;
    }

    Navigator.of(context).pop(
      DuLieuSuaNhanVien(
        hoTen: _hoTenCtrl.text.trim(),
        soDienThoai: _soDienThoaiCtrl.text.trim(),
        vaiTro: _vaiTro!,
        trangThai: _trangThai!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.daylightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 672, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Section (Screen 26)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.mossPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'HỒ SƠ TRẠM MÁY POS',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chỉnh sửa nhân viên',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cập nhật thông tin hồ sơ và quyền hạn tài khoản POS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('modal_sua_nv_dong'),
                    tooltip: 'Đóng cửa sổ',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderSoft),

              // Form Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isTwoCols = constraints.maxWidth >= 520;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Group 1: 1. THÔNG TIN NHÂN VIÊN
                            _buildSectionHeader(
                              left: '1. THÔNG TIN NHÂN VIÊN',
                              right: 'Thông tin cơ bản',
                            ),
                            const SizedBox(height: 14),

                            // Mã nhân viên (Read-only)
                            _buildReadOnlyField(
                              label: 'Mã nhân viên',
                              subLabel: '(Cố định hệ thống)',
                              hint: 'Mã nhân viên (chỉ đọc)...',
                              controller: _maNhanVienCtrl,
                            ),
                            const SizedBox(height: 14),

                            if (isTwoCols)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildHoTenField()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildSoDienThoaiField()),
                                ],
                              )
                            else ...[
                              _buildHoTenField(),
                              const SizedBox(height: 14),
                              _buildSoDienThoaiField(),
                            ],

                            const SizedBox(height: 22),

                            // Group 2: 2. TÀI KHOẢN POS
                            _buildSectionHeader(
                              left: '2. TÀI KHOẢN POS',
                              right: 'Phân quyền đăng nhập',
                            ),
                            const SizedBox(height: 14),

                            // Tên đăng nhập (Read-only)
                            _buildReadOnlyField(
                              label: 'Tên đăng nhập',
                              subLabel: '(Chỉ đọc)',
                              hint: 'Tên đăng nhập POS (chỉ đọc)...',
                              controller: _tenDangNhapCtrl,
                            ),
                            const SizedBox(height: 14),

                            if (isTwoCols)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildVaiTroDropdown()),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildTrangThaiDropdown()),
                                ],
                              )
                            else ...[
                              _buildVaiTroDropdown(),
                              const SizedBox(height: 14),
                              _buildTrangThaiDropdown(),
                            ],

                            if (_thongBaoKiemTra != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                _thongBaoKiemTra!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],

                            if (widget.onResetPassword != null) ...[
                              const SizedBox(height: 18),
                              if (!_hienFormDatLaiMatKhau) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: OutlinedButton.icon(
                                    key: const Key(
                                      'modal_sua_nv_mo_dat_lai_mk',
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _hienFormDatLaiMatKhau = true;
                                        _thongBaoMatKhau = null;
                                        _loiMatKhau = false;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.mossPrimary,
                                      side: const BorderSide(
                                        color: AppColors.mossPrimary,
                                        width: 1.2,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.lock_reset_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      'Đặt lại mật khẩu',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_thongBaoMatKhau != null &&
                                    !_loiMatKhau) ...[
                                  const SizedBox(height: 10),
                                  _buildPasswordStatusBanner(),
                                ],
                              ] else ...[
                                _buildSectionHeader(
                                  left: '3. ĐẶT LẠI MẬT KHẨU',
                                  right: 'Áp dụng lập tức',
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.daylightSubtle,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.borderSoft,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (isTwoCols)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: _buildMatKhauMoiField(),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child:
                                                  _buildXacNhanMatKhauField(),
                                            ),
                                          ],
                                        )
                                      else ...[
                                        _buildMatKhauMoiField(),
                                        const SizedBox(height: 14),
                                        _buildXacNhanMatKhauField(),
                                      ],
                                      if (_thongBaoMatKhau != null) ...[
                                        const SizedBox(height: 12),
                                        _buildPasswordStatusBanner(),
                                      ],
                                      const SizedBox(height: 12),
                                      Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          Text(
                                            'Tối thiểu 6 ký tự và có ít nhất 1 chữ số.',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: AppColors.inkMuted,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextButton(
                                                key: const Key(
                                                  'modal_sua_nv_dong_dat_lai_mk',
                                                ),
                                                onPressed: _dangDatLaiMatKhau
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          _hienFormDatLaiMatKhau =
                                                              false;
                                                          _matKhauMoiCtrl
                                                              .clear();
                                                          _xacNhanMatKhauCtrl
                                                              .clear();
                                                          if (_loiMatKhau) {
                                                            _thongBaoMatKhau =
                                                                null;
                                                            _loiMatKhau = false;
                                                          }
                                                        });
                                                      },
                                                child: Text(
                                                  'Thu gọn',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: AppColors
                                                            .inkSecondary,
                                                      ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton.icon(
                                                key: const Key(
                                                  'modal_sua_nv_dat_lai_mk',
                                                ),
                                                onPressed: _dangDatLaiMatKhau
                                                    ? null
                                                    : _xuLyDatLaiMatKhau,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      AppColors.mossPrimary,
                                                  foregroundColor: Colors.white,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                ),
                                                icon: _dangDatLaiMatKhau
                                                    ? const SizedBox(
                                                        width: 15,
                                                        height: 15,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : const Icon(
                                                        Icons
                                                            .lock_reset_rounded,
                                                        size: 18,
                                                      ),
                                                label: Text(
                                                  _dangDatLaiMatKhau
                                                      ? 'Đang đổi...'
                                                      : 'Đổi mật khẩu ngay',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],

                            const SizedBox(height: 18),

                            // Subtle Info Callout Box (Screen 26)
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.daylightSubtle,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.borderSoft),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.mossPrimary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Dữ liệu hồ sơ nhân sự sẽ được tự động điền từ hệ thống khi mở xem, giữ nguyên bố cục không dịch chuyển.',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        color: AppColors.inkSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 16),

              // Modal Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('modal_sua_nv_huy'),
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.daylightSubtle,
                      foregroundColor: AppColors.inkSecondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Hủy bỏ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    key: const Key('modal_sua_nv_luu'),
                    onPressed: _xuLyLuuThayDoi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mossPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      'Lưu thay đổi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String left, required String right}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              left,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: AppColors.mossPrimary,
              ),
            ),
            Text(
              right,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.borderSoft),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String subLabel,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              subLabel,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.inkSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.inkMuted,
            ),
            suffixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.inkMuted,
            ),
            filled: true,
            fillColor: AppColors.daylightSubtle,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSoft),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderSoft),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(width: 4),
        const Text(
          '*',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  InputDecoration _editableDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        color: AppColors.inkMuted,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.mossPrimary, width: 1.6),
      ),
    );
  }

  Widget _buildHoTenField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredLabel('Họ và tên'),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('sua_nv_ho_ten'),
          controller: _hoTenCtrl,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên.' : null,
          decoration: _editableDecoration('Nhập họ và tên...'),
        ),
      ],
    );
  }

  Widget _buildSoDienThoaiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredLabel('Số điện thoại'),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('sua_nv_sdt'),
          controller: _soDienThoaiCtrl,
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập số điện thoại di động.'
              : null,
          decoration: _editableDecoration('Nhập số điện thoại di động...'),
        ),
      ],
    );
  }

  Widget _buildVaiTroDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredLabel('Vai trò'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('sua_nv_vai_tro'),
          isExpanded: true,
          initialValue: _vaiTro,
          hint: Text(
            'Chọn vai trò',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.inkMuted,
            ),
          ),
          decoration: _editableDecoration('Chọn vai trò'),
          items: const [
            DropdownMenuItem(value: 'nhan-vien', child: Text('Nhân viên')),
            DropdownMenuItem(value: 'quan-ly', child: Text('Quản lý')),
          ],
          onChanged: (v) => setState(() {
            _vaiTro = v;
            _thongBaoKiemTra = null;
          }),
        ),
      ],
    );
  }

  Widget _buildTrangThaiDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequiredLabel('Trạng thái'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('sua_nv_trang_thai'),
          isExpanded: true,
          initialValue: _trangThai,
          hint: Text(
            'Chọn trạng thái',
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: AppColors.inkMuted,
            ),
          ),
          decoration: _editableDecoration('Chọn trạng thái'),
          items: const [
            DropdownMenuItem(
              value: 'dang-hoat-dong',
              child: Text('Đang hoạt động'),
            ),
            DropdownMenuItem(value: 'da-khoa', child: Text('Đã khóa')),
          ],
          onChanged: (v) => setState(() {
            _trangThai = v;
            _thongBaoKiemTra = null;
          }),
        ),
      ],
    );
  }

  Widget _buildPasswordStatusBanner() {
    return Container(
      key: const Key('sua_nv_thong_bao_mat_khau'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _loiMatKhau ? AppColors.dangerBg : AppColors.mossSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _loiMatKhau ? AppColors.dangerBorder : AppColors.mossMid,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _loiMatKhau
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 17,
            color: _loiMatKhau ? AppColors.danger : AppColors.mossDeep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _thongBaoMatKhau!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _loiMatKhau ? AppColors.danger : AppColors.mossDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatKhauMoiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mật khẩu mới',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('sua_nv_mat_khau_moi'),
          controller: _matKhauMoiCtrl,
          obscureText: _anMatKhauMoi,
          enabled: !_dangDatLaiMatKhau,
          onChanged: (_) {
            if (_thongBaoMatKhau != null) {
              setState(() => _thongBaoMatKhau = null);
            }
          },
          decoration: _editableDecoration('Nhập mật khẩu mới...').copyWith(
            suffixIcon: IconButton(
              tooltip: _anMatKhauMoi ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () => setState(() => _anMatKhauMoi = !_anMatKhauMoi),
              icon: Icon(
                _anMatKhauMoi
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildXacNhanMatKhauField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xác nhận mật khẩu mới',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: const Key('sua_nv_xac_nhan_mat_khau'),
          controller: _xacNhanMatKhauCtrl,
          obscureText: _anXacNhanMatKhau,
          enabled: !_dangDatLaiMatKhau,
          onSubmitted: (_) => _xuLyDatLaiMatKhau(),
          onChanged: (_) {
            if (_thongBaoMatKhau != null) {
              setState(() => _thongBaoMatKhau = null);
            }
          },
          decoration: _editableDecoration('Nhập lại mật khẩu mới...').copyWith(
            suffixIcon: IconButton(
              tooltip: _anXacNhanMatKhau ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () =>
                  setState(() => _anXacNhanMatKhau = !_anXacNhanMatKhau),
              icon: Icon(
                _anXacNhanMatKhau
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
