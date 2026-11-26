import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../dieu_khien/dieu_khien_bao_cao.dart';
import '../../mo_hinh/du_lieu_bao_cao.dart';

/// Tab 2 · Dự báo (Daylight AI) bám sát giao diện Stitch
class TabDuBaoAi extends StatelessWidget {
  final DieuKhienBaoCao dieuKhien;
  final bool isDesktop;
  final VoidCallback onChonKhoangNgay;

  const TabDuBaoAi({
    super.key,
    required this.dieuKhien,
    required this.isDesktop,
    required this.onChonKhoangNgay,
  });

  static const Color _amberForecast = Color(0xFFFE932C);

  String _formatVnd(int amount) {
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

  String _formatShortDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (dieuKhien.dangTaiDuBao && dieuKhien.duBao == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.mossPrimary),
        ),
      );
    }

    if (dieuKhien.loiDuBao != null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.dangerBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dieuKhien.loiDuBao!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ),
            TextButton(
              onPressed: dieuKhien.taiDuBao,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final db = dieuKhien.duBao;
    if (db == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Date Range Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.mossPrimary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Khoảng dữ liệu huấn luyện: ${_formatShortDate(dieuKhien.tuNgayDuBao)} — ${_formatShortDate(dieuKhien.denNgayDuBao)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: onChonKhoangNgay,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.inkPrimary,
                      side: const BorderSide(color: AppColors.borderSoft),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_today_rounded, size: 15),
                    label: const Text('Chọn khoảng ngày'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: dieuKhien.dangTaiDuBao
                        ? null
                        : dieuKhien.taiDuBao,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mossPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Cập nhật'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Main Bento Grid: Area Chart (8) + Data Readiness Card (4)
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: _buildForecastChartCard(db)),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: _buildReadinessStatusCard(db)),
            ],
          )
        else ...[
          _buildForecastChartCard(db),
          const SizedBox(height: 16),
          _buildReadinessStatusCard(db),
        ],

        const SizedBox(height: 18),

        // Ingredient & Shift Suggestions Card
        _buildSuggestionsCard(db),
      ],
    );
  }

  Widget _buildForecastChartCard(DuBaoDaylightAi db) {
    final maxRevenue = db.chuoiDuLieu.fold<int>(
      100000,
      (prev, pt) => math.max(
        prev,
        math.max(pt.doanhThuThucTeVnd ?? 0, pt.doanhThuDuBaoVnd ?? 0),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAYLIGHT AI FORECAST',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: AppColors.mossMid,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Xu hướng doanh thu & sản lượng',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.daylightSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.mossPrimary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Thực tế',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Container(
                      width: 18,
                      height: 3,
                      decoration: BoxDecoration(
                        color: _amberForecast,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dự báo (7 ngày tới)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 240,
            child: Row(
              children: [
                // Y-axis labels
                SizedBox(
                  width: 68,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _yLabel(_formatCompactVnd(maxRevenue)),
                      _yLabel(_formatCompactVnd((maxRevenue * 0.66).round())),
                      _yLabel(_formatCompactVnd((maxRevenue * 0.33).round())),
                      _yLabel('0đ'),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                    decoration: BoxDecoration(
                      color: AppColors.daylightSubtle.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: CustomPaint(
                      painter: _ForecastAreaChartPainter(
                        points: db.chuoiDuLieu,
                        maxValue: maxRevenue.toDouble(),
                        actualColor: AppColors.mossPrimary,
                        forecastColor: _amberForecast,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (db.chuoiDuLieu.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 78),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _pickAxisLabels(db.chuoiDuLieu)
                    .map(
                      (lbl) => Text(
                        lbl,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _pickAxisLabels(List<DiemDuBao> list) {
    if (list.length <= 6) {
      return list.map((e) => e.nhanNgay).toList();
    }
    final step = (list.length - 1) / 5;
    return List.generate(
      6,
      (i) => list[(i * step).round().clamp(0, list.length - 1)].nhanNgay,
    );
  }

  String _formatCompactVnd(int v) {
    if (v >= 1000000) {
      return '${(v / 1000000).toStringAsFixed(1)}tr';
    }
    if (v >= 1000) {
      return '${(v / 1000).round()}k';
    }
    return '$vđ';
  }

  Widget _yLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.inkMuted,
      ),
    );
  }

  Widget _buildReadinessStatusCard(DuBaoDaylightAi db) {
    final ready = db.duDuLieu;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ready ? AppColors.mossMid : AppColors.borderSoft,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ready ? AppColors.mossSoft : const Color(0xFFFFECCE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: ready ? AppColors.mossPrimary : _amberForecast,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TRẠNG THÁI DỮ LIỆU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: ready
                            ? AppColors.mossDeep
                            : const Color(0xFF6E3900),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                ready
                    ? Icons.verified_rounded
                    : Icons.hourglass_empty_rounded,
                size: 20,
                color: ready ? AppColors.mossPrimary : AppColors.inkMuted,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            db.tieuDeTrangThai,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            db.moTaTrangThai,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.inkSecondary,
              height: 1.45,
            ),
          ),
          if (ready) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.mossSoft.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DỰ BÁO DOANH THU 7 NGÀY TỚI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mossDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatVnd(db.doanhThuDuBao7NgayVnd),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mossPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Xu hướng: ${db.xuHuongPhanTram >= 0 ? '+' : ''}${db.xuHuongPhanTram.toStringAsFixed(1)}% · Cao điểm: ${db.khungGioCaoDiem}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Độ phủ dữ liệu lịch sử',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                    Text(
                      '${db.soNgayLichSu}/${db.soNgayToiThieu} ngày (${db.doPhuPhanTram.toStringAsFixed(0)}%)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mossPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: (db.doPhuPhanTram / 100.0).clamp(0.0, 1.0),
                    backgroundColor: AppColors.borderSoft,
                    color: ready ? AppColors.mossPrimary : _amberForecast,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(DuBaoDaylightAi db) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.mossSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 20,
                      color: AppColors.mossDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gợi ý nhập nguyên liệu & vận hành',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                      Text(
                        'Tính toán tự động dựa trên sản lượng đơn dự báo 7 ngày tới',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: db.duDuLieu
                      ? AppColors.mossSoft
                      : AppColors.daylightSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  db.duDuLieu ? 'Đã kích hoạt AI' : 'Đang chờ đủ dữ liệu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: db.duDuLieu
                        ? AppColors.mossDeep
                        : AppColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!db.duDuLieu || db.goiYNguyenLieu.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.daylightSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Chưa đủ dữ liệu lịch sử để đề xuất định mức nhập nguyên liệu. Hãy chọn khoảng thời gian có tối thiểu ${db.soNgayToiThieu} ngày giao dịch.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.inkSecondary,
                ),
              ),
            )
          else
            Column(
              children: db.goiYNguyenLieu.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.daylightSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.ten,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            Text(
                              item.danhMuc,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.tonKhoHienTai,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.dinhMucGoiY,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.mossPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Text(
                          item.mucUuTien,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _ForecastAreaChartPainter extends CustomPainter {
  final List<DiemDuBao> points;
  final double maxValue;
  final Color actualColor;
  final Color forecastColor;

  const _ForecastAreaChartPainter({
    required this.points,
    required this.maxValue,
    required this.actualColor,
    required this.forecastColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFDDE3DE)
      ..strokeWidth = 1;

    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.length < 2 || maxValue <= 0) return;

    final dx = size.width / (points.length - 1);
    final actualOffsets = <Offset>[];
    final forecastOffsets = <Offset>[];

    for (var i = 0; i < points.length; i++) {
      final x = i * dx;
      final pt = points[i];
      if (pt.doanhThuThucTeVnd != null) {
        final y =
            size.height - (pt.doanhThuThucTeVnd! / maxValue) * size.height;
        actualOffsets.add(Offset(x, y.clamp(4.0, size.height)));
      }
      if (pt.doanhThuDuBaoVnd != null) {
        final y =
            size.height - (pt.doanhThuDuBaoVnd! / maxValue) * size.height;
        forecastOffsets.add(Offset(x, y.clamp(4.0, size.height)));
      }
    }

    _drawSeries(
      canvas: canvas,
      size: size,
      offsets: actualOffsets,
      color: actualColor,
      dashed: false,
    );
    _drawSeries(
      canvas: canvas,
      size: size,
      offsets: forecastOffsets,
      color: forecastColor,
      dashed: true,
    );
  }

  void _drawSeries({
    required Canvas canvas,
    required Size size,
    required List<Offset> offsets,
    required Color color,
    required bool dashed,
  }) {
    if (offsets.length < 2) return;

    final areaPath = Path()..moveTo(offsets.first.dx, size.height);
    for (final o in offsets) {
      areaPath.lineTo(o.dx, o.dy);
    }
    areaPath
      ..lineTo(offsets.last.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (!dashed) {
      final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        linePath.lineTo(offsets[i].dx, offsets[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    } else {
      for (var i = 0; i < offsets.length - 1; i++) {
        _drawDashedSegment(canvas, offsets[i], offsets[i + 1], linePaint);
      }
    }

    final dotPaint = Paint()..color = color;
    for (final o in offsets) {
      canvas.drawCircle(o, 3.2, dotPaint);
    }
  }

  void _drawDashedSegment(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashLen = 6.0;
    const gapLen = 5.0;
    final total = (p2 - p1).distance;
    if (total <= 0) return;
    final dir = (p2 - p1) / total;
    double drawn = 0;
    while (drawn < total) {
      final end = math.min(drawn + dashLen, total);
      canvas.drawLine(p1 + dir * drawn, p1 + dir * end, paint);
      drawn += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _ForecastAreaChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.maxValue != maxValue;
}
