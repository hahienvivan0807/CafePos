import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../dieu_khien/dieu_khien_phan_ca.dart';
import '../../mo_hinh/du_lieu_phan_ca.dart';

/// Màn 32 · Tab Lịch phân ca (Ma trận 7 ngày x các khung ca đang áp dụng)
class TabLichPhanCa extends StatelessWidget {
  final DieuKhienPhanCa dieuKhien;
  final void Function(DateTime ngay, KhungCaMau khungCa) onMoPhanCong;
  final VoidCallback onCongBoTuan;
  final VoidCallback onSaoChepTuanTruoc;

  const TabLichPhanCa({
    super.key,
    required this.dieuKhien,
    required this.onMoPhanCong,
    required this.onCongBoTuan,
    required this.onSaoChepTuanTruoc,
  });

  static const _tenThu = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _fmtDdMm(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _fmtFull(DateTime d) => '${_fmtDdMm(d)}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final lich = dieuKhien.lichTuan;
    final dauTuan = dieuKhien.ngayDauTuan;
    final cuoiTuan = dauTuan.add(const Duration(days: 6));
    final cacNgay = List.generate(7, (i) => dauTuan.add(Duration(days: i)));
    final khungCaList = lich?.khungCa ?? const <KhungCaMau>[];
    final nhanVienList = lich?.nhanVienSanSang ?? const <NhanVienSanSang>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Control Ribbon
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.daylightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              // Week nav
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.daylightSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Tuần trước',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => dieuKhien.chuyenTuan(-1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        TextButton(
                          onPressed: () => dieuKhien.chuyenTuan(0),
                          child: const Text('Tuần này'),
                        ),
                        IconButton(
                          tooltip: 'Tuần sau',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => dieuKhien.chuyenTuan(1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.daylightSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'T2 ${_fmtFull(dauTuan)} — CN ${_fmtFull(cuoiTuan)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: dieuKhien.locNhanVienId,
                      decoration: _filterDeco(),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Tất cả nhân viên'),
                        ),
                        ...nhanVienList.map(
                          (nv) => DropdownMenuItem(
                            value: nv.id,
                            child: Text(
                              nv.hoTen,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) => dieuKhien.datLocNhanVien(v ?? ''),
                    ),
                  ),
                  SizedBox(
                    width: 155,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: dieuKhien.locViTri,
                      decoration: _filterDeco(),
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Tất cả vị trí')),
                        DropdownMenuItem(value: 'PhaChe', child: Text('Pha chế')),
                        DropdownMenuItem(
                          value: 'ThuNgan',
                          child: Text('Thu ngân'),
                        ),
                        DropdownMenuItem(value: 'PhucVu', child: Text('Phục vụ')),
                        DropdownMenuItem(
                          value: 'TruongCa',
                          child: Text('Trưởng ca'),
                        ),
                      ],
                      onChanged: (v) => dieuKhien.datLocViTri(v ?? ''),
                    ),
                  ),
                ],
              ),

              // Actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: dieuKhien.dangThaoTac
                        ? null
                        : onSaoChepTuanTruoc,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkPrimary,
                      side: const BorderSide(color: AppColors.borderSoft),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(Icons.content_copy_rounded, size: 16),
                    label: const Text('Sao chép tuần trước'),
                  ),
                  ElevatedButton.icon(
                    key: const Key('phan_ca_btn_cong_bo'),
                    onPressed: dieuKhien.dangThaoTac ? null : onCongBoTuan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mossPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(Icons.publish_rounded, size: 17),
                    label: const Text('Công bố lịch'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Matrix Card
        if (dieuKhien.dangTaiLich && lich == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 56),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.mossPrimary),
            ),
          )
        else if (dieuKhien.loiLich != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              dieuKhien.loiLich!,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.daylightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final matrixWidth = constraints.maxWidth > 1120
                    ? constraints.maxWidth
                    : 1120.0;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: matrixWidth,
                    child: Column(
                      children: [
                        // Header Row
                        Container(
                          color: AppColors.daylightSubtle,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    'KHUNG CA ÁP DỤNG',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.mossPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              ...List.generate(7, (i) {
                                final isWeekend = i >= 5;
                                return Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${_tenThu[i]} · ${_fmtDdMm(cacNgay[i])}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: isWeekend
                                              ? AppColors.mossPrimary
                                              : AppColors.inkPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.borderSoft),

                        // Rows per shift template
                        ...khungCaList.map((ca) {
                          return Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.borderSoft,
                                  width: 0.8,
                                ),
                              ),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Shift Label Col
                                  Container(
                                    width: 200,
                                    padding: const EdgeInsets.all(14),
                                    color: AppColors.daylightSubtle.withValues(
                                      alpha: 0.45,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          ca.tenCa,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.inkPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${ca.gioBatDau} — ${ca.gioKetThuc}',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.mossPrimary,
                                          ),
                                        ),
                                        Text(
                                          '${ca.thoiLuongGio}h · Cần ${ca.tongDinhBien} người',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            color: AppColors.inkMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 7 Day Cells
                                  ...List.generate(7, (dIdx) {
                                    final day = cacNgay[dIdx];
                                    final assigned = dieuKhien.phanCongChoO(
                                      day,
                                      ca.ma,
                                    );
                                    final duNguoi =
                                        assigned.length >= ca.tongDinhBien;

                                    return Expanded(
                                      child: InkWell(
                                        onTap: () => onMoPhanCong(day, ca),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: dIdx >= 5
                                                ? AppColors.daylightSubtle
                                                      .withValues(alpha: 0.35)
                                                : Colors.white,
                                            border: const Border(
                                              left: BorderSide(
                                                color: AppColors.borderSoft,
                                                width: 0.6,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Định biên',
                                                        style:
                                                            GoogleFonts.plusJakartaSans(
                                                              fontSize: 10.5,
                                                              color: AppColors
                                                                  .inkMuted,
                                                            ),
                                                      ),
                                                      Text(
                                                        '${assigned.length}/${ca.tongDinhBien}',
                                                        style:
                                                            GoogleFonts.plusJakartaSans(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: duNguoi
                                                                  ? AppColors
                                                                        .mossDeep
                                                                  : AppColors
                                                                        .danger,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  if (assigned.isNotEmpty)
                                                    ...assigned.take(3).map((
                                                      pc,
                                                    ) {
                                                      return Container(
                                                        margin:
                                                            const EdgeInsets.only(
                                                              bottom: 4,
                                                            ),
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 7,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: pc.trangThaiTuan ==
                                                                  'DaCongBo'
                                                              ? AppColors
                                                                    .mossSoft
                                                              : AppColors
                                                                    .daylightSubtle,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                7,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          '${pc.tenNhanVien} · ${pc.nhanViTri}',
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              GoogleFonts.plusJakartaSans(
                                                                fontSize: 10.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: AppColors
                                                                    .inkPrimary,
                                                              ),
                                                        ),
                                                      );
                                                    }),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 5,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      AppColors.daylightSubtle,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '+ Gán ca',
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: AppColors
                                                              .mossPrimary,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 16),

        // Bottom Summary Bar (Màn 32)
        if (lich != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.daylightSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Tổng giờ dự kiến tuần: ${lich.tongGioTuan}h',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mossPrimary,
                      ),
                    ),
                    Text(
                      'Ca thiếu định biên: ${lich.soCaThieuNhanSu}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: lich.soCaThieuNhanSu > 0
                            ? AppColors.danger
                            : AppColors.mossDeep,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lich.trangThaiTuan == 'DaCongBo'
                        ? AppColors.mossSoft
                        : const Color(0xFFFFECCE),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    lich.trangThaiTuan == 'DaCongBo'
                        ? 'Đã công bố lịch tuần'
                        : 'Bản nháp tuần (Chưa phát hành)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: lich.trangThaiTuan == 'DaCongBo'
                          ? AppColors.mossDeep
                          : const Color(0xFF904D00),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _filterDeco() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.daylightSubtle,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: BorderSide.none,
      ),
    );
  }
}
