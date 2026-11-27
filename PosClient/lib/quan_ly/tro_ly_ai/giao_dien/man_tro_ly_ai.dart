import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../nen_tang/giao_dien/bang_mau.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../dieu_khien/dieu_khien_tro_ly_ai.dart';
import '../mo_hinh/du_lieu_tro_ly_ai.dart';
import 'thanh_phan/the_mini_form_ai.dart';

/// Màn Trợ lý AI tiếng Việt (Daylight AI) kết nối Ollama local + Mini-Form xác nhận.
class ManTroLyAi extends StatefulWidget {
  const ManTroLyAi({
    super.key,
    required this.apiClient,
    required this.onToast,
  });

  final PosAuthApiClient apiClient;
  final void Function(String message, {bool isError}) onToast;

  @override
  State<ManTroLyAi> createState() => _ManTroLyAiState();
}

class _ManTroLyAiState extends State<ManTroLyAi> {
  late final DieuKhienTroLyAi _ctrl;
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  static const _quickPrompts = <String>[
    'Hỏi doanh thu hôm nay theo 4 ca',
    'Món bán chạy nhất 7 ngày qua',
    'Tuần này còn ca nào thiếu nhân sự không?',
    'Đề xuất giảm giá Bạc xỉu 10% cho Ca Chiều hôm nay',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = DieuKhienTroLyAi(apiClient: widget.apiClient);
    _ctrl.addListener(_onCtrlChanged);
    _ctrl.taiTrangThai();
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onCtrlChanged);
    _ctrl.dispose();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onCtrlChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _inputCtrl.text).trim();
    if (text.isEmpty || _ctrl.dangGui) return;
    _inputCtrl.clear();
    await _ctrl.guiCauHoi(text);
  }

  Future<void> _handleConfirm(String messageId) async {
    final summary = await _ctrl.xacNhanMiniForm(messageId);
    if (!mounted) return;
    if (summary != null) {
      widget.onToast(summary);
    } else if (_ctrl.loi != null) {
      widget.onToast(_ctrl.loi!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1020;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: _buildChatSection()),
              const SizedBox(width: 20),
              Expanded(flex: 4, child: _buildRightSidebar()),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildChatSection(),
            const SizedBox(height: 20),
            _buildRightSidebar(),
          ],
        );
      },
    );
  }

  Widget _buildChatSection() {
    final st = _ctrl.trangThai;
    final online = st?.ollamaTrucTuyen ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Daylight AI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: const Color(0xFFF4F3F7),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF133021),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Daylight AI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC9EBD3),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Trợ lý Quản lý',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF032112),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Phân tích vận hành, kiểm tra ca trực & đề xuất khuyến mãi theo thời gian thực',
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
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: online
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        online ? 'Sẵn sàng' : 'Tạm gián đoạn',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Gợi ý nhanh
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFF8F7FA),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'GỢI Ý NHANH:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                ..._quickPrompts.map(
                  (prompt) => ActionChip(
                    onPressed: _ctrl.dangGui ? null : () => _send(prompt),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.borderSoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    label: Text(
                      prompt,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Luồng hội thoại
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 420, maxHeight: 540),
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(20),
              itemCount: _ctrl.tinNhans.length + (_ctrl.dangGui ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == _ctrl.tinNhans.length) {
                  return _buildTypingIndicator();
                }
                final msg = _ctrl.tinNhans[index];
                return msg.isUser
                    ? _buildUserBubble(msg)
                    : _buildAssistantBubble(msg);
              },
            ),
          ),

          // Thanh nhập chat
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF4F3F7),
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderSoft),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 19,
                          color: AppColors.inkSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _inputCtrl,
                            enabled: !_ctrl.dangGui,
                            onSubmitted: (_) => _send(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.inkPrimary,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nhập câu hỏi cho Daylight AI...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _ctrl.dangGui ? null : () => _send(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF133021),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 17),
                    label: Text(
                      _ctrl.dangGui ? 'Đang hỏi...' : 'Gửi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(TinNhanTroLyAi msg) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: const BoxDecoration(
            color: Color(0xFF133021),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(6),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quản lý · ${_formatClock(msg.createdAt)}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC9EBD3),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                msg.content,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(TinNhanTroLyAi msg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          margin: const EdgeInsets.only(top: 2),
          decoration: const BoxDecoration(
            color: Color(0xFFC9EBD3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: Color(0xFF032112),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4F3F7),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Daylight AI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF133021),
                          ),
                        ),
                        if (msg.toolUsed != null && msg.toolUsed!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.borderSoft),
                            ),
                            child: Text(
                              _friendlyToolLabel(msg.toolUsed!),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mossMid,
                              ),
                            ),
                          ),
                        if (msg.latencyMs != null)
                          Text(
                            '· ${(msg.latencyMs! / 1000).toStringAsFixed(1)}s',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      msg.content,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.55,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (msg.miniFormDraft != null) ...[
                const SizedBox(height: 12),
                TheMiniFormAi(
                  draft: msg.miniFormDraft!,
                  dangXacNhan: _ctrl.dangXacNhanForm,
                  onChinhSua: () => _ctrl.batCheDoChinhSua(msg.id),
                  onCapNhatTruong: (k, v) =>
                      _ctrl.capNhatGiaTriTruong(msg.id, k, v),
                  onHuyBo: () => _ctrl.huyBoMiniForm(msg.id),
                  onXacNhan: () => _handleConfirm(msg.id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFC9EBD3),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: Color(0xFF032112),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F3F7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF133021),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI đang suy nghĩ...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightSidebar() {
    final st = _ctrl.trangThai;
    final ctx = st?.nguCanh;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card Ghi chú hệ thống
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF89F5E7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.dns_rounded,
                      size: 18,
                      color: Color(0xFF00201D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nguyên tắc hỗ trợ',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới trạng thái trợ lý',
                    onPressed: _ctrl.dangTaiTrangThai
                        ? null
                        : _ctrl.taiTrangThai,
                    icon: const Icon(Icons.refresh_rounded, size: 19),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F3F7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Daylight AI đọc trực tiếp số liệu bán hàng và lịch trực của quán. Mọi đề xuất thay đổi như giảm giá món hay phân ca chỉ có hiệu lực sau khi Quản lý kiểm tra và bấm Xác nhận.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'TRẠNG THÁI TRỢ LÝ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Phiên bản trợ lý',
                'Daylight AI · Quản lý quán',
              ),
              _buildInfoRow(
                'Tình trạng kết nối',
                st == null
                    ? 'Đang kiểm tra...'
                    : (st.ollamaTrucTuyen ? 'Đang trực tuyến' : 'Tạm gián đoạn'),
              ),
              if (_ctrl.doTreGanNhatMs != null)
                _buildInfoRow(
                  'Tốc độ phản hồi',
                  '${(_ctrl.doTreGanNhatMs! / 1000).toStringAsFixed(2)} giây',
                ),
              if (st != null && !st.ollamaTrucTuyen) ...[
                const SizedBox(height: 8),
                Text(
                  'Trợ lý AI hiện tạm gián đoạn. Vui lòng thử bấm làm mới sau giây lát.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Card Ngữ cảnh cửa hàng
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ngữ cảnh cửa hàng',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                  Text(
                    _ctrl.dangTaiTrangThai
                        ? 'Đang đồng bộ...'
                        : 'Cập nhật trực tiếp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mossMid,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiTile(
                      label: 'Doanh thu hôm nay',
                      value: ctx != null
                          ? _formatVnd(ctx.doanhThuHomNayVnd)
                          : '—',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildKpiTile(
                      label: 'Đơn chờ xử lý',
                      value: ctx != null ? '${ctx.donChoXuLy} đơn' : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildKpiTile(
                label: 'Ca thiếu người tuần này',
                value: ctx != null ? '${ctx.caThieuDinhBien} khung ca' : '—',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.inkSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTile({required String label, required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF133021),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyToolLabel(String toolName) {
    return switch (toolName) {
      'get_shift_revenue' => 'Báo cáo doanh thu ca',
      'get_top_products' => 'Thống kê món bán chạy',
      'get_weekly_shift_gaps' => 'Kiểm tra lịch trực',
      'draft_menu_promotion' => 'Đề xuất khuyến mãi',
      'draft_shift_assignment' => 'Đề xuất phân ca',
      _ => 'Tra cứu dữ liệu quán',
    };
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatVnd(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final posFromEnd = s.length - i;
      buf.write(s[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buf.write('.');
      }
    }
    return '${buf.toString()}đ';
  }
}
