import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../dieu_khien/dieu_khien_phan_ca.dart';
import '../../mo_hinh/du_lieu_phan_ca.dart';

/// Màn 28 · Tab Khung ca (Danh mục khung ca mẫu + Quy chuẩn nghiệp vụ)
class TabKhungCa extends StatelessWidget {
  final DieuKhienPhanCa dieuKhien;
  final VoidCallback onThemKhungCa;
  final ValueChanged<KhungCaMau> onSuaKhungCa;
  final ValueChanged<KhungCaMau> onXoaHoacNgungKhungCa;

  const TabKhungCa({
    super.key,
    required this.dieuKhien,
    required this.onThemKhungCa,
    required this.onSuaKhungCa,
    required this.onXoaHoacNgungKhungCa,
  });

  @override
  Widget build(BuildContext context) {
    final ds = dieuKhien.danhSachKhungCaHienThi;
    final headerStyle = GoogleFonts.plusJakartaSans(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: AppColors.inkSecondary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: dieuKhien.oTimKiemKhungCa,
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên khung ca, mã ca...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      filled: true,
                      fillColor: AppColors.daylightSurface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: dieuKhien.locTrangThaiKhungCa,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.daylightSurface,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text('Tất cả trạng thái'),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('Đang áp dụng'),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Ngừng sử dụng'),
                      ),
                    ],
                    onChanged: (v) =>
                        dieuKhien.datLocTrangThaiKhungCa(v ?? 'all'),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              key: const Key('phan_ca_btn_them_khung_ca'),
              onPressed: dieuKhien.dangThaoTac ? null : onThemKhungCa,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mossPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: Text(
                'Thêm khung ca',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Table Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.daylightSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > 920
                      ? constraints.maxWidth
                      : 920.0;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: width,
                      child: Column(
                        children: [
                          Container(
                            color: AppColors.daylightSubtle,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'MÃ & TÊN KHUNG CA',
                                    style: headerStyle,
                                  ),
                                ),
                                SizedBox(
                                  width: 155,
                                  child: Text('KHUNG GIỜ', style: headerStyle),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    'NGHỈ GIỮA CA',
                                    style: headerStyle,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'ĐỊNH BIÊN THEO VỊ TRÍ',
                                    style: headerStyle,
                                  ),
                                ),
                                SizedBox(
                                  width: 135,
                                  child: Text('TRẠNG THÁI', style: headerStyle),
                                ),
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    'THAO TÁC',
                                    textAlign: TextAlign.right,
                                    style: headerStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (dieuKhien.dangTaiKhungCa)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.mossPrimary,
                                ),
                              ),
                            )
                          else if (ds.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 40,
                                    color: AppColors.inkMuted,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Chưa có khung ca nào phù hợp',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...ds.map((k) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
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
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            k.tenCa,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.inkPrimary,
                                            ),
                                          ),
                                          Text(
                                            k.ma,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.mossMid,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 155,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${k.gioBatDau} — ${k.gioKetThuc}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            '${k.thoiLuongGio}h${k.quaDem ? " (Qua đêm)" : ""}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: AppColors.inkMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 110,
                                      child: Text(
                                        k.nghiGiuaCaPhut > 0
                                            ? '${k.nghiGiuaCaPhut} phút'
                                            : 'Không nghỉ',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'Pha chế: ${k.dinhBienPhaChe} · Thu ngân: ${k.dinhBienThuNgan} · Phục vụ: ${k.dinhBienPhucVu}',
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          color: AppColors.inkSecondary,
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
                                            color: k.dangApDung
                                                ? AppColors.mossSoft
                                                : AppColors.dangerBg,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            k.dangApDung
                                                ? 'Đang áp dụng'
                                                : 'Ngừng sử dụng',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: k.dangApDung
                                                  ? AppColors.mossDeep
                                                  : AppColors.danger,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: dieuKhien.dangThaoTac
                                                ? null
                                                : () => onSuaKhungCa(k),
                                            style: TextButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              minimumSize: Size.zero,
                                            ),
                                            child: const Text('Sửa'),
                                          ),
                                          TextButton(
                                            onPressed: dieuKhien.dangThaoTac
                                                ? null
                                                : () =>
                                                      onXoaHoacNgungKhungCa(k),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.danger,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              minimumSize: Size.zero,
                                            ),
                                            child: Text(
                                              k.daCoLichSu ? 'Ngừng' : 'Xóa',
                                            ),
                                          ),
                                        ],
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Text(
                  'Hiển thị ${ds.length} trên tổng số ${dieuKhien.tongKhungCa} khung ca',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quy chuẩn nghiệp vụ (Màn 28)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.daylightSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.policy_outlined,
                color: AppColors.mossPrimary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Quy chuẩn nghiệp vụ: Khung ca là mẫu giờ dùng lại; ca trên lịch là lần làm việc cụ thể. Chỉ cho phép xóa khung ca chưa từng được dùng trong hóa đơn hoặc lịch trực; khung đã phát sinh lịch sẽ tự chuyển sang trạng thái Ngừng sử dụng để bảo toàn dữ liệu.',
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
  }
}
