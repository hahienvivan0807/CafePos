import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../nen_tang/giao_dien/bang_mau.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../dich_vu/dich_vu_nhan_vien.dart';
import '../dieu_khien/dieu_khien_nhan_vien.dart';
import '../mo_hinh/ho_so_nhan_vien.dart';
import 'thanh_phan/hop_thoai_sua_nhan_vien.dart';
import 'thanh_phan/hop_thoai_them_nhan_vien.dart';

/// Màn 24 · Quản lý nhân viên kết nối thật với Backend CRUD (/api/manager/staff)
class ManQuanLyNhanVien extends StatefulWidget {
  final PosAuthApiClient apiClient;
  final String currentManagerId;
  final bool isDesktop;

  const ManQuanLyNhanVien({
    super.key,
    required this.apiClient,
    required this.currentManagerId,
    required this.isDesktop,
  });

  @override
  State<ManQuanLyNhanVien> createState() => _ManQuanLyNhanVienState();
}

class _ManQuanLyNhanVienState extends State<ManQuanLyNhanVien> {
  late final DieuKhienNhanVien _dieuKhien;

  @override
  void initState() {
    super.initState();
    _dieuKhien = DieuKhienNhanVien(
      dichVu: DichVuNhanVien(apiClient: widget.apiClient),
    )..taiDanhSach();
  }

  @override
  void dispose() {
    _dieuKhien.dispose();
    super.dispose();
  }

  Future<void> _moHopThoaiThemNhanVien() async {
    final duLieu = await showDialog<DuLieuThemNhanVien>(
      context: context,
      barrierColor: const Color(0xFF263143).withValues(alpha: 0.40),
      builder: (_) => const HopThoaiThemNhanVien(),
    );

    if (duLieu == null || !mounted) return;
    final ketQua = await _dieuKhien.themMoi(duLieu);
    if (!mounted) return;
    _hienThongBao(ketQua.message, laLoi: !ketQua.isSuccess);
  }

  Future<void> _moHopThoaiSuaNhanVien(HoSoNhanVien nhanVien) async {
    final duLieu = await showDialog<DuLieuSuaNhanVien>(
      context: context,
      barrierColor: const Color(0xFF263143).withValues(alpha: 0.40),
      builder: (_) => HopThoaiSuaNhanVien(
        nhanVien: nhanVien,
        onResetPassword: (matKhauMoi, xacNhanMatKhau) =>
            _dieuKhien.datLaiMatKhau(
              staffUserId: nhanVien.id,
              matKhauMoi: matKhauMoi,
              xacNhanMatKhau: xacNhanMatKhau,
            ),
      ),
    );

    if (duLieu == null || !mounted) return;
    final ketQua = await _dieuKhien.capNhat(
      staffUserId: nhanVien.id,
      duLieu: duLieu,
    );
    if (!mounted) return;
    _hienThongBao(ketQua.message, laLoi: !ketQua.isSuccess);
  }

  Future<void> _xacNhanXoaNhanVien(HoSoNhanVien nhanVien) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.daylightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Xác nhận xóa nhân viên',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.inkPrimary,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa tài khoản "${nhanVien.hoTen}" (${nhanVien.tenDangNhap})? Nếu nhân viên đã có lịch sử ca làm hoặc đơn hàng, hệ thống sẽ tự động chuyển sang trạng thái Đã khóa để bảo toàn dữ liệu.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            color: AppColors.inkSecondary,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy bỏ'),
          ),
          ElevatedButton(
            key: const Key('xac_nhan_xoa_nv_btn'),
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );

    if (dongY != true || !mounted) return;
    final ketQua = await _dieuKhien.xoa(nhanVien.id);
    if (!mounted) return;
    _hienThongBao(ketQua.message, laLoi: !ketQua.isSuccess);
  }

  void _hienThongBao(String noiDung, {bool laLoi = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 480,
        backgroundColor: laLoi ? AppColors.danger : AppColors.mossDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          noiDung,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _dieuKhien,
      builder: (context, _) {
        final danhSach = _dieuKhien.danhSachHienThi;
        final tongSo = _dieuKhien.tongSoNhanSu;

        return SingleChildScrollView(
          padding: EdgeInsets.all(widget.isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 20),
              _buildFilterToolbar(),
              const SizedBox(height: 20),
              if (_dieuKhien.thongBaoLoi != null) ...[
                _buildErrorBanner(_dieuKhien.thongBaoLoi!),
                const SizedBox(height: 16),
              ],
              _buildTableCard(danhSach: danhSach, tongSo: tongSo),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: _dieuKhien.taiDanhSach,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý nhân viên',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Quản lý tài khoản đăng nhập, phân quyền vai trò và trạng thái truy cập của nhân viên.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildIconSquareButton(
              keyName: 'nv_btn_xuat_du_lieu',
              tooltip: 'Xuất dữ liệu danh sách',
              icon: Icons.download_rounded,
              onPressed: () => _hienThongBao(
                'Đang hiển thị ${_dieuKhien.danhSachHienThi.length} nhân sự từ database cafe_pos.',
              ),
            ),
            _buildIconSquareButton(
              keyName: 'nv_btn_lam_moi',
              tooltip: 'Làm mới bảng',
              icon: Icons.refresh_rounded,
              onPressed: _dieuKhien.lamMoi,
            ),
            ElevatedButton.icon(
              key: const Key('nv_btn_them_moi'),
              onPressed: _dieuKhien.dangThaoTac
                  ? null
                  : _moHopThoaiThemNhanVien,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mossPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'Thêm nhân viên',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconSquareButton({
    required String keyName,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          key: Key(keyName),
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Icon(icon, size: 20, color: AppColors.inkSecondary),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;

          final searchBox = TextField(
            key: const Key('nv_o_tim_kiem'),
            controller: _dieuKhien.oTimKiem,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.inkPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Tìm theo tên hoặc mã nhân viên',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.inkMuted,
              ),
              filled: true,
              fillColor: AppColors.daylightSubtle,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.mossPrimary,
                  width: 1.6,
                ),
              ),
            ),
          );

          final roleDropdown = _buildFilterDropdown(
            keyName: 'nv_loc_vai_tro',
            value: _dieuKhien.boLocVaiTro,
            items: const [
              DropdownMenuItem(value: '', child: Text('Tất cả vai trò')),
              DropdownMenuItem(value: 'nhan-vien', child: Text('Nhân viên')),
              DropdownMenuItem(value: 'quan-ly', child: Text('Quản lý')),
            ],
            onChanged: (v) => _dieuKhien.datBoLocVaiTro(v ?? ''),
          );

          final statusDropdown = _buildFilterDropdown(
            keyName: 'nv_loc_trang_thai',
            value: _dieuKhien.boLocTrangThai,
            items: const [
              DropdownMenuItem(value: '', child: Text('Tất cả trạng thái')),
              DropdownMenuItem(
                value: 'dang-hoat-dong',
                child: Text('Đang hoạt động'),
              ),
              DropdownMenuItem(value: 'da-khoa', child: Text('Đã khóa')),
            ],
            onChanged: (v) => _dieuKhien.datBoLocTrangThai(v ?? ''),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: searchBox),
                const SizedBox(width: 12),
                SizedBox(width: 190, child: roleDropdown),
                const SizedBox(width: 12),
                SizedBox(width: 195, child: statusDropdown),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchBox,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: roleDropdown),
                  const SizedBox(width: 10),
                  Expanded(child: statusDropdown),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String keyName,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.daylightSubtle,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: Key(keyName),
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: AppColors.inkMuted,
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: AppColors.inkPrimary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTableCard({
    required List<HoSoNhanVien> danhSach,
    required int tongSo,
  }) {
    final headerStyle = GoogleFonts.plusJakartaSans(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
      color: AppColors.inkSecondary,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth > 960
                  ? constraints.maxWidth
                  : 960.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        color: AppColors.daylightSubtle,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 115,
                              child: Text('MÃ NHÂN VIÊN', style: headerStyle),
                            ),
                            SizedBox(
                              width: 195,
                              child: Text('HỌ VÀ TÊN', style: headerStyle),
                            ),
                            SizedBox(
                              width: 145,
                              child: Text('TÊN ĐĂNG NHẬP', style: headerStyle),
                            ),
                            SizedBox(
                              width: 105,
                              child: Text('VAI TRÒ', style: headerStyle),
                            ),
                            SizedBox(
                              width: 135,
                              child: Text('TRẠNG THÁI', style: headerStyle),
                            ),
                            Expanded(
                              child: Text(
                                'THAO TÁC',
                                textAlign: TextAlign.right,
                                style: headerStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.borderSoft),

                      if (_dieuKhien.dangTai)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 56),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.mossMid,
                            ),
                          ),
                        )
                      else if (danhSach.isEmpty)
                        _buildEmptyState()
                      else
                        ...danhSach.map(_buildStaffRow),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(height: 1, color: AppColors.borderSoft),

          // Pagination Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Text(
                  'Hiển thị ${danhSach.length} trên tổng số $tongSo nhân sự',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.inkSecondary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPaginationButton(
                      label: 'Trước',
                      leadingIcon: Icons.chevron_left_rounded,
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.daylightSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${danhSach.isEmpty ? 0 : 1}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildPaginationButton(
                      label: 'Sau',
                      trailingIcon: Icons.chevron_right_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.daylightSubtle,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 34,
                  color: AppColors.inkMuted,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chưa có dữ liệu nhân viên để hiển thị',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Nhấn “+ Thêm nhân viên” để bắt đầu tạo hồ sơ và phân quyền tài khoản POS.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  color: AppColors.inkSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                key: const Key('nv_btn_them_ngay_empty'),
                onPressed: _moHopThoaiThemNhanVien,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mossPrimary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 42),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  'Thêm nhân viên ngay',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffRow(HoSoNhanVien nv) {
    final dangHoatDong = nv.trangThai == 'dang-hoat-dong';
    final laChinhMinh = nv.id == widget.currentManagerId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 0.7),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 115,
            child: Text(
              nv.maNhanVien,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 195,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nv.hoTen,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                ),
                if (nv.soDienThoai.isNotEmpty)
                  Text(
                    nv.soDienThoai,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 145,
            child: Text(
              nv.tenDangNhap,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                color: AppColors.inkSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 105,
            child: Text(
              nv.tenVaiTroHienThi,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: nv.vaiTro == 'quan-ly'
                    ? AppColors.mossDeep
                    : AppColors.inkSecondary,
              ),
            ),
          ),
          SizedBox(
            width: 135,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: dangHoatDong ? AppColors.mossSoft : AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  nv.tenTrangThaiHienThi,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: dangHoatDong ? AppColors.mossDeep : AppColors.danger,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  key: Key('nv_btn_sua_${nv.tenDangNhap}'),
                  onPressed: _dieuKhien.dangThaoTac
                      ? null
                      : () => _moHopThoaiSuaNhanVien(nv),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa'),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  key: Key('nv_btn_xoa_${nv.tenDangNhap}'),
                  onPressed: (_dieuKhien.dangThaoTac || laChinhMinh)
                      ? null
                      : () => _xacNhanXoaNhanVien(nv),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Xóa'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required String label,
    IconData? leadingIcon,
    IconData? trailingIcon,
  }) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.daylightSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 18,
              color: AppColors.inkMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted.withValues(alpha: 0.5),
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: 4),
            Icon(
              trailingIcon,
              size: 18,
              color: AppColors.inkMuted.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
  }
}
