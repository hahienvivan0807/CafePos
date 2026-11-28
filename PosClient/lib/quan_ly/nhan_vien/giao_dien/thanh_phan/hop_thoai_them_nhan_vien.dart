import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../mo_hinh/ho_so_nhan_vien.dart';

/// Modal 25 · Thêm nhân viên (bám sát thiết kế Google Stitch)
/// - Nhóm 1: 1. THÔNG TIN NHÂN VIÊN (Mã nhân viên tùy chọn, Họ và tên *, Số điện thoại *)
/// - Nhóm 2: 2. TÀI KHOẢN POS (Tên đăng nhập *, Vai trò *, Trạng thái *)
/// - Hộp ghi chú chính sách mật khẩu tạm & 2 nút Hủy bỏ / Thêm nhân viên
class HopThoaiThemNhanVien extends StatefulWidget {
  const HopThoaiThemNhanVien({super.key});

  @override
  State<HopThoaiThemNhanVien> createState() => _HopThoaiThemNhanVienState();
}

class _HopThoaiThemNhanVienState extends State<HopThoaiThemNhanVien> {
  final _formKey = GlobalKey<FormState>();
  final _maNhanVienCtrl = TextEditingController();
  final _hoTenCtrl = TextEditingController();
  final _soDienThoaiCtrl = TextEditingController();
  final _tenDangNhapCtrl = TextEditingController();
  final _matKhauCtrl = TextEditingController();
  bool _anMatKhau = true;

  String? _vaiTro;
  String? _trangThai;
  String? _thongBaoKiemTra;

  @override
  void dispose() {
    _maNhanVienCtrl.dispose();
    _hoTenCtrl.dispose();
    _soDienThoaiCtrl.dispose();
    _tenDangNhapCtrl.dispose();
    _matKhauCtrl.dispose();
    super.dispose();
  }

  void _xuLyXacNhan() {
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
      DuLieuThemNhanVien(
        maNhanVien: _maNhanVienCtrl.text.trim(),
        hoTen: _hoTenCtrl.text.trim(),
        soDienThoai: _soDienThoaiCtrl.text.trim(),
        tenDangNhap: _tenDangNhapCtrl.text.trim(),
        matKhau: _matKhauCtrl.text,
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
              // Modal Header
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
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.mossPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thêm nhân viên',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tạo hồ sơ nhân sự và phân quyền truy cập hệ thống POS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('modal_them_nv_dong'),
                    tooltip: 'Đóng hộp thoại',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderSoft),

              // Scrollable Form Body
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
                            // SECTION 1: THÔNG TIN NHÂN VIÊN
                            _buildSectionTitle(
                              icon: Icons.badge_outlined,
                              title: '1. THÔNG TIN NHÂN VIÊN',
                            ),
                            const SizedBox(height: 14),

                            if (isTwoCols)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildMaNhanVienField()),
                                  const SizedBox(width: 18),
                                  Expanded(child: _buildHoTenField()),
                                ],
                              )
                            else ...[
                              _buildMaNhanVienField(),
                              const SizedBox(height: 14),
                              _buildHoTenField(),
                            ],

                            const SizedBox(height: 14),
                            _buildSoDienThoaiField(),

                            const SizedBox(height: 22),

                            // SECTION 2: TÀI KHOẢN POS
                            _buildSectionTitle(
                              icon: Icons.lock_outline_rounded,
                              title: '2. TÀI KHOẢN POS',
                            ),
                            const SizedBox(height: 14),

                            if (isTwoCols)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildTenDangNhapField()),
                                  const SizedBox(width: 18),
                                  Expanded(child: _buildMatKhauField()),
                                ],
                              )
                            else ...[
                              _buildTenDangNhapField(),
                              const SizedBox(height: 14),
                              _buildMatKhauField(),
                            ],
                            const SizedBox(height: 14),

                            if (isTwoCols)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildVaiTroDropdown()),
                                  const SizedBox(width: 18),
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

                            const SizedBox(height: 18),

                            // Security & Policy Micro Note (theo Stitch)
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
                                      'Mật khẩu được mã hóa trên đường truyền HTTPS (TLS) và băm an toàn bằng PBKDF2-SHA512 trước khi lưu vào cơ sở dữ liệu — không bao giờ lưu dạng chữ thường.',
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

              // Modal Footer Actions (Canh phải ở cuối)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const Key('modal_them_nv_huy'),
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
                    key: const Key('modal_them_nv_xac_nhan'),
                    onPressed: _xuLyXacNhan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mossPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                    label: Text(
                      'Thêm nhân viên',
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

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.mossPrimary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: AppColors.mossPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.borderSoft),
      ],
    );
  }

  Widget _buildLabel(String text, {bool batBuoc = false, String? ghiChuPhai}) {
    return Row(
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ),
              if (batBuoc) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (ghiChuPhai != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              ghiChuPhai,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 13.5,
        color: AppColors.inkMuted,
      ),
      prefixIcon: Icon(icon, size: 18, color: AppColors.inkMuted),
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

  Widget _buildMaNhanVienField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Mã nhân viên', ghiChuPhai: 'Tự động nếu trống'),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('them_nv_ma'),
          controller: _maNhanVienCtrl,
          decoration: _inputDecoration(
            hint: 'Nhập mã nhân viên (để trống để tự sinh)...',
            icon: Icons.tag_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildHoTenField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Họ và tên', batBuoc: true),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('them_nv_ho_ten'),
          controller: _hoTenCtrl,
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ và tên.' : null,
          decoration: _inputDecoration(
            hint: 'Nhập họ và tên...',
            icon: Icons.person_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSoDienThoaiField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Số điện thoại', batBuoc: true),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('them_nv_sdt'),
          controller: _soDienThoaiCtrl,
          keyboardType: TextInputType.phone,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập số điện thoại di động.'
              : null,
          decoration: _inputDecoration(
            hint: 'Nhập số điện thoại di động...',
            icon: Icons.call_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMatKhauField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Mật khẩu', batBuoc: true),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('them_nv_mat_khau'),
          controller: _matKhauCtrl,
          obscureText: _anMatKhau,
          validator: (v) {
            final raw = v ?? '';
            if (raw.length < 6) {
              return 'Mật khẩu cần tối thiểu 6 ký tự.';
            }
            if (!RegExp(r'\d').hasMatch(raw)) {
              return 'Mật khẩu cần có ít nhất 1 chữ số.';
            }
            return null;
          },
          decoration: _inputDecoration(
            hint: 'Ít nhất 6 ký tự, có chữ số...',
            icon: Icons.key_outlined,
          ).copyWith(
            suffixIcon: IconButton(
              tooltip: _anMatKhau ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () => setState(() => _anMatKhau = !_anMatKhau),
              icon: Icon(
                _anMatKhau
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

  Widget _buildTenDangNhapField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tên đăng nhập', batBuoc: true),
        const SizedBox(height: 6),
        TextFormField(
          key: const Key('them_nv_ten_dang_nhap'),
          controller: _tenDangNhapCtrl,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập tên đăng nhập POS.'
              : null,
          decoration: _inputDecoration(
            hint: 'Nhập tên đăng nhập POS...',
            icon: Icons.alternate_email_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildVaiTroDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Vai trò', batBuoc: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('them_nv_vai_tro'),
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
          decoration: _inputDecoration(
            hint: 'Chọn vai trò',
            icon: Icons.manage_accounts_outlined,
          ),
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
        _buildLabel('Trạng thái', batBuoc: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: const Key('them_nv_trang_thai'),
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
          decoration: _inputDecoration(
            hint: 'Chọn trạng thái',
            icon: Icons.verified_user_outlined,
          ),
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
}
