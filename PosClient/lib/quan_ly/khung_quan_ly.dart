import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dung_chung/dang_nhap/giao_dien/thanh_phan/bieu_tuong_ca_phe.dart';
import '../dung_chung/dang_nhap/mo_hinh/phien_dang_nhap.dart';
import '../dung_chung/dich_vu_ban/giao_dien/hop_thoai_mo_ban.dart';
import '../dung_chung/dich_vu_ban/mo_hinh/du_lieu_ban.dart';
import '../nen_tang/giao_dien/bang_mau.dart';
import '../nen_tang/mang/cong_api.dart';
import 'bao_cao/giao_dien/man_bao_cao_va_du_bao.dart';
import 'nhan_vien/giao_dien/man_quan_ly_nhan_vien.dart';
import 'phan_ca/giao_dien/man_phan_ca_va_gio_lam.dart';

/// Không gian Quản lý (Manager Shell) theo hệ thiết kế Daylight & Moss Green
/// - Bám các màn đã chốt ở Stitch (4907969291961553465)
/// - Manager đi thẳng vào giao diện Quản lý sau đăng nhập hoặc khôi phục phiên,
///   thao tác dịch vụ/bàn không phụ thuộc ca làm việc.
/// - Chỉ nối dữ liệu thật từ API sẵn có; hiển thị trạng thái trống/chưa tích hợp ở nơi chưa có dữ liệu.
class ManagerShellScreen extends StatefulWidget {
  final PosAuthApiClient apiClient;
  final AuthSessionModel session;
  final int initialSectionIndex;
  final ValueChanged<int>? onSectionChanged;
  final ValueChanged<AuthSessionModel> onSessionUpdated;
  final void Function({String? reason}) onLoggedOut;

  const ManagerShellScreen({
    super.key,
    required this.apiClient,
    required this.session,
    this.initialSectionIndex = 0,
    this.onSectionChanged,
    required this.onSessionUpdated,
    required this.onLoggedOut,
  });

  @override
  State<ManagerShellScreen> createState() => _ManagerShellScreenState();
}

class _ManagerShellScreenState extends State<ManagerShellScreen> {
  late int _selectedSectionIndex;
  final TextEditingController _searchController = TextEditingController();

  DashboardOverviewModel? _overview;
  bool _isLoadingOverview = true;
  bool _isActionInProgress = false;
  bool _isLoggingOut = false;
  String? _errorMessage;

  final String _selectedArea = 'ALL';
  String _selectedStatusFilter = 'ALL';
  int? _selectedTableId;

  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex = widget.initialSectionIndex;
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _loadManagerOverview();
  }

  @override
  void didUpdateWidget(covariant ManagerShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSectionIndex != oldWidget.initialSectionIndex &&
        widget.initialSectionIndex != _selectedSectionIndex) {
      setState(() {
        _selectedSectionIndex = widget.initialSectionIndex;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _selectSection(int index) {
    setState(() {
      _selectedSectionIndex = index;
    });
    widget.onSectionChanged?.call(index);
  }

  Future<void> _loadManagerOverview({int? focusTableId}) async {
    setState(() {
      _isLoadingOverview = true;
      _errorMessage = null;
    });

    final result = await widget.apiClient.getManagerOverview();
    if (!mounted) return;

    if (!result.isSuccess || result.data == null) {
      if (result.statusCode == 401 || result.statusCode == 403) {
        final isHttpToHttps =
            Uri.base.scheme == 'http' &&
            widget.apiClient.baseUrl.startsWith('https://');
        final reason = isHttpToHttps
            ? 'Trình duyệt không gửi được Cookie xác thực (401) vì bạn đang mở qua HTTP (${Uri.base.origin}). Vui lòng mở trực tiếp bằng HTTPS tại ${widget.apiClient.baseUrl}.'
            : (result.message.isNotEmpty
                  ? result.message
                  : 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.');
        widget.onLoggedOut(reason: reason);
        return;
      }
      setState(() {
        _isLoadingOverview = false;
        _errorMessage = result.message;
      });
      return;
    }

    final data = result.data!;
    int? nextSelectedTableId = focusTableId ?? _selectedTableId;
    if (nextSelectedTableId == null ||
        !data.tables.any((t) => t.tableId == nextSelectedTableId)) {
      final firstOccupied = data.tables
          .where((t) => t.visualStatus != 'EMPTY')
          .firstOrNull;
      nextSelectedTableId =
          firstOccupied?.tableId ?? data.tables.firstOrNull?.tableId;
    }

    setState(() {
      _overview = data;
      _selectedTableId = nextSelectedTableId;
      _isLoadingOverview = false;
    });
  }

  TableCardModel? get _selectedTableCard {
    final ov = _overview;
    if (ov == null || _selectedTableId == null) return null;
    for (final t in ov.tables) {
      if (t.tableId == _selectedTableId) return t;
    }
    return null;
  }

  List<TableCardModel> get _filteredTables {
    final ov = _overview;
    if (ov == null) return const [];
    final q = _searchController.text.trim().toLowerCase();

    return ov.tables.where((t) {
      if (_selectedArea != 'ALL' && t.areaName != _selectedArea) {
        return false;
      }
      if (_selectedStatusFilter == 'EMPTY' && t.visualStatus != 'EMPTY') {
        return false;
      }
      if (_selectedStatusFilter == 'OCCUPIED' && t.visualStatus == 'EMPTY') {
        return false;
      }
      if (_selectedStatusFilter == 'AWAITING_QR' &&
          t.visualStatus != 'AWAITING_QR') {
        return false;
      }
      if (q.isNotEmpty) {
        final matchCode = t.tableCode.toLowerCase().contains(q);
        final matchName = t.tableName.toLowerCase().contains(q);
        final matchArea = t.areaName.toLowerCase().contains(q);
        if (!matchCode && !matchName && !matchArea) return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openTableOrderModal({TableCardModel? initialTable}) async {
    final ov = _overview;
    if (ov == null || _isActionInProgress) return;

    final updated = await showDialog<TableCardModel>(
      context: context,
      builder: (context) => OpenTableOrderModal(
        apiClient: widget.apiClient,
        tables: ov.tables,
        categories: ov.categories,
        menuItems: ov.menuItems,
        initialTable: initialTable ?? _selectedTableCard,
      ),
    );

    if (updated != null && mounted) {
      _showToast('Đã cập nhật bàn ${updated.tableCode} thành công.');
      await _loadManagerOverview(focusTableId: updated.tableId);
    }
  }

  Future<void> _handleRequestVietQr(TableCardModel table) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    final result = await widget.apiClient.requestVietQr(
      tableId: table.tableId,
      orderId: table.sessionDetail?.activeUnpaidOrderId,
    );

    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    if (!result.isSuccess) {
      _showToast(result.message, isError: true);
      return;
    }

    _showToast(result.message);
    await _loadManagerOverview(focusTableId: table.tableId);
  }

  Future<void> _handleConfirmPaid(TableCardModel table) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    final result = await widget.apiClient.confirmVietQrPaid(
      tableId: table.tableId,
      orderId: table.sessionDetail?.activeUnpaidOrderId,
    );

    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    if (!result.isSuccess) {
      _showToast(result.message, isError: true);
      return;
    }

    _showToast(result.message);
    await _loadManagerOverview(focusTableId: table.tableId);
  }

  Future<void> _handleCloseTable(TableCardModel table) async {
    if (_isActionInProgress) return;
    setState(() => _isActionInProgress = true);

    final result = await widget.apiClient.closeTableSession(
      tableId: table.tableId,
    );

    if (!mounted) return;
    setState(() => _isActionInProgress = false);

    if (!result.isSuccess) {
      _showToast(result.message, isError: true);
      return;
    }

    _showToast(result.message);
    await _loadManagerOverview(focusTableId: table.tableId);
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);

    await widget.apiClient.logout();
    if (!mounted) return;

    setState(() => _isLoggingOut = false);
    widget.onLoggedOut();
  }

  Future<void> _showProfileModal() async {
    final nameCtrl = TextEditingController(text: widget.session.user.fullName);
    final phoneCtrl = TextEditingController(
      text: widget.session.user.phoneNumber ?? '',
    );
    bool isSaving = false;
    String? modalError;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              backgroundColor: AppColors.daylightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.mossSoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.manage_accounts_rounded,
                              color: AppColors.mossMid,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hồ sơ Quản lý',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                Text(
                                  'Tài khoản: ${widget.session.user.username} · Role: ${widget.session.user.roles.join(", ")}',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 12,
                                    color: AppColors.inkSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Họ và tên hiển thị',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkLabel,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.borderSoft,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Số điện thoại liên hệ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkLabel,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: phoneCtrl,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          hintText: 'Nhập số điện thoại liên hệ',
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppColors.borderSoft,
                            ),
                          ),
                        ),
                      ),
                      if (modalError != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          modalError!,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.of(ctx).pop(),
                            child: Text(
                              'Đóng',
                              style: GoogleFonts.beVietnamPro(
                                color: AppColors.inkSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (nameCtrl.text.trim().isEmpty) {
                                      setModalState(() {
                                        modalError =
                                            'Họ và tên không được để trống.';
                                      });
                                      return;
                                    }
                                    setModalState(() {
                                      isSaving = true;
                                      modalError = null;
                                    });
                                    final res = await widget.apiClient
                                        .updateProfile(
                                          fullName: nameCtrl.text.trim(),
                                          phoneNumber: phoneCtrl.text.trim(),
                                        );
                                    if (!ctx.mounted) return;
                                    if (!res.isSuccess || res.data == null) {
                                      setModalState(() {
                                        isSaving = false;
                                        modalError = res.message;
                                      });
                                      return;
                                    }
                                    widget.onSessionUpdated(
                                      widget.session.copyWith(user: res.data),
                                    );
                                    Navigator.of(ctx).pop();
                                    _showToast('Đã cập nhật hồ sơ quản lý.');
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.mossMid,
                              foregroundColor: AppColors.warmCreamText,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              isSaving ? 'Đang lưu...' : 'Lưu hồ sơ',
                              style: GoogleFonts.beVietnamPro(
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
          },
        );
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        width: 440,
        backgroundColor: isError ? AppColors.danger : AppColors.mossDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          message,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  static String _formatVnd(int amount) {
    final raw = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final posFromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.daylightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1020;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) _buildSidebar(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTopHeader(isDesktop: isDesktop),
                      if (!isDesktop) _buildMobileNavStrip(),
                      Expanded(
                        child: _buildActiveSectionBody(isDesktop: isDesktop),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 264,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.mossMid,
            AppColors.mossPrimary,
            AppColors.mossDeep,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Row(
              children: [
                const CoffeeLogoBadge(size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PinVuTru Cafe',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warmCreamText,
                        ),
                      ),
                      Text(
                        'KHÔNG GIAN QUẢN LÝ',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.7,
                          color: AppColors.warmSandMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mossBorderLight),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: AppColors.emeraldDot,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quyền Manager · Không phụ thuộc ca làm',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmCreamText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'ĐIỀU HƯỚNG QUẢN TRỊ',
              style: GoogleFonts.beVietnamPro(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.warmSandMuted,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSidebarItem(
                  index: 0,
                  keyName: 'nav_manager_overview',
                  icon: Icons.dashboard_customize_rounded,
                  label: 'Tổng quan quản lý',
                  badge: 'Live DB',
                ),
                _buildSidebarItem(
                  index: 1,
                  keyName: 'nav_manager_pos_floor',
                  icon: Icons.table_restaurant_rounded,
                  label: 'Điểm vào POS / Sơ đồ bàn',
                  badge: '${_overview?.totalTables ?? 0} bàn',
                ),
                _buildSidebarItem(
                  index: 2,
                  keyName: 'nav_manager_staff',
                  icon: Icons.badge_outlined,
                  label: 'Quản lý nhân viên',
                ),
                _buildSidebarItem(
                  index: 6,
                  keyName: 'nav_manager_shift_schedule',
                  icon: Icons.work_history_rounded,
                  label: 'Phân ca & Giờ làm',
                  badge: '4 ca',
                ),
                _buildSidebarItem(
                  index: 3,
                  keyName: 'nav_manager_reconciliation',
                  icon: Icons.fact_check_outlined,
                  label: 'Đối soát & Duyệt hủy món',
                ),
                _buildSidebarItem(
                  index: 4,
                  keyName: 'nav_manager_reports',
                  icon: Icons.stacked_bar_chart_rounded,
                  label: 'Báo cáo & Dự báo',
                ),
                _buildSidebarItem(
                  index: 5,
                  keyName: 'nav_manager_ai',
                  icon: Icons.auto_awesome_rounded,
                  label: 'Trợ lý AI tiếng Việt',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.mossBorderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.emeraldDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'PostgreSQL 18 · cafe_pos',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warmCreamText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Schema: pos · Cookie HTTPS + Antiforgery CSRF',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      color: AppColors.warmSandMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required String keyName,
    required IconData icon,
    required String label,
    String? badge,
  }) {
    final isSelected = _selectedSectionIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        key: Key(keyName),
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectSection(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.daylightSurface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.mossDeep
                    : AppColors.warmCreamText,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.inkPrimary
                        : AppColors.warmCreamText,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.mossSoft
                        : Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.mossDeep
                          : AppColors.warmCreamText,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNavStrip() {
    const tabs = [
      (0, 'Tổng quan', Icons.dashboard_customize_rounded),
      (1, 'POS / Sơ đồ bàn', Icons.table_restaurant_rounded),
      (2, 'Nhân viên', Icons.badge_outlined),
      (3, 'Đối soát', Icons.fact_check_outlined),
      (4, 'Báo cáo', Icons.stacked_bar_chart_rounded),
      (5, 'Trợ lý AI', Icons.auto_awesome_rounded),
    ];

    return Container(
      color: AppColors.daylightSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((item) {
            final isSelected = _selectedSectionIndex == item.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(
                  item.$3,
                  size: 16,
                  color: isSelected
                      ? AppColors.warmCreamText
                      : AppColors.mossMid,
                ),
                label: Text(item.$2),
                selected: isSelected,
                selectedColor: AppColors.mossMid,
                backgroundColor: AppColors.daylightSubtle,
                labelStyle: GoogleFonts.beVietnamPro(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.warmCreamText
                      : AppColors.inkPrimary,
                ),
                onSelected: (_) => _selectSection(item.$1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopHeader({required bool isDesktop}) {
    final ov = _overview;
    final user = widget.session.user;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 14,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.daylightSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSoft, width: 1),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.mossSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.mossMid,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Quản lý trực tiếp · Không yêu cầu mở ca',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mossDeep,
                      ),
                    ),
                  ],
                ),
              ),
              if (ov != null) ...[
                _buildHeaderMetricPill(
                  label: 'Bàn trống',
                  count: ov.emptyTables,
                  color: const Color(0xFF059669),
                ),
                _buildHeaderMetricPill(
                  label: 'Đang có khách',
                  count: ov.occupiedTables,
                  color: const Color(0xFF475569),
                ),
                _buildHeaderMetricPill(
                  label: 'Chờ VietQR',
                  count: ov.awaitingQrTables,
                  color: const Color(0xFFD97706),
                ),
              ],
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.daylightSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.mossMid,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatClock(_now),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                key: const Key('manager_profile_button'),
                borderRadius: BorderRadius.circular(12),
                onTap: _showProfileModal,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.daylightSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.mossMid,
                        child: Text(
                          user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'M',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkPrimary,
                            ),
                          ),
                          Text(
                            '${user.title} (${user.roles.join(", ")})',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: AppColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('manager_logout_button'),
                onPressed: _isLoggingOut ? null : _handleLogout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.dangerBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: Text(
                  _isLoggingOut ? 'Đang thoát...' : 'Đăng xuất',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetricPill({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        '$label: $count',
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildActiveSectionBody({required bool isDesktop}) {
    if (_isLoadingOverview) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.mossMid),
            const SizedBox(height: 12),
            Text(
              'Đang đồng bộ dữ liệu thực từ PostgreSQL (cafe_pos)...',
              style: GoogleFonts.beVietnamPro(
                fontSize: 13.5,
                color: AppColors.inkSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.daylightSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.dangerBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(
                'Không thể tải dữ liệu Quản lý',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13.5,
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadManagerOverview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mossMid,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedSectionIndex) {
      case 0:
        return _buildManagerOverviewSection(isDesktop: isDesktop);
      case 1:
        return _buildPosFloorSection(isDesktop: isDesktop);
      case 2:
        return ManQuanLyNhanVien(
          apiClient: widget.apiClient,
          currentManagerId: widget.session.user.userId,
          isDesktop: isDesktop,
        );
      case 3:
        return _buildReconciliationSection();
      case 4:
        return ManBaoCaoVaDuBao(
          apiClient: widget.apiClient,
          isDesktop: isDesktop,
        );
      case 5:
        return _buildAiAssistantSection();
      case 6:
        return ManPhanCaVaGioLam(
          apiClient: widget.apiClient,
          isDesktop: isDesktop,
        );
      default:
        return _buildManagerOverviewSection(isDesktop: isDesktop);
    }
  }

  /// 1. Trang Tổng quan quản lý (nối dữ liệu thật từ /api/dashboard/manager-overview)
  Widget _buildManagerOverviewSection({required bool isDesktop}) {
    final ov = _overview!;
    int liveRevenuePaidVnd = 0;
    int liveRemainingVnd = 0;
    for (final t in ov.tables) {
      final sd = t.sessionDetail;
      if (sd != null) {
        liveRevenuePaidVnd += sd.paidAmountVnd;
        liveRemainingVnd += sd.remainingAmountVnd;
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner chào mừng Quản lý
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.daylightSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 14,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tổng quan Quản lý · ${widget.session.user.fullName}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dữ liệu bàn, lượt sử dụng và thực đơn đọc trực tiếp từ PostgreSQL (cafe_pos · schema pos). Quản lý thao tác trực tiếp không cần mở ca.',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13.5,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadManagerOverview,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mossMid,
                        side: const BorderSide(color: AppColors.mossMid),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        'Đồng bộ DB',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      key: const Key('quick_enter_pos_floor_button'),
                      onPressed: () => _selectSection(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mossMid,
                        foregroundColor: AppColors.warmCreamText,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.table_restaurant_rounded, size: 18),
                      label: Text(
                        'Vào Sơ đồ bàn / POS',
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Hàng thẻ chỉ số thực từ DB
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _buildStatCard(
                title: 'Tổng số bàn (pos.Ban)',
                value: '${ov.totalTables} bàn',
                subtitle:
                    'Trống: ${ov.emptyTables} · Có khách: ${ov.occupiedTables} · Chờ QR: ${ov.awaitingQrTables}',
                icon: Icons.table_bar_rounded,
                accentColor: AppColors.mossMid,
              ),
              _buildStatCard(
                title: 'Thực đơn đang mở bán (pos.Mon)',
                value: '${ov.menuItems.length} món',
                subtitle: '${ov.categories.length} nhóm danh mục trong DB',
                icon: Icons.local_cafe_rounded,
                accentColor: const Color(0xFF059669),
              ),
              _buildStatCard(
                title: 'Đã thu trên các lượt đang mở',
                value: _formatVnd(liveRevenuePaidVnd),
                subtitle: 'Còn phải thu: ${_formatVnd(liveRemainingVnd)}',
                icon: Icons.payments_outlined,
                accentColor: const Color(0xFFD97706),
              ),
              _buildStatCard(
                title: 'Đối soát & Trợ lý AI',
                value: 'Chưa tích hợp API',
                subtitle: 'Hiển thị trạng thái chờ tích hợp theo đúng phạm vi',
                icon: Icons.auto_awesome_outlined,
                accentColor: const Color(0xFF475569),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bảng thực đơn thật từ pos.DanhMucMon & pos.Mon + Sơ đồ bàn tóm tắt
          Wrap(
            spacing: 18,
            runSpacing: 18,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 560 : double.infinity,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.daylightSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Thực đơn & Giá bán hiện có (pos.Mon)',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mossSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Dữ liệu thật từ DB',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.mossDeep,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (ov.menuItems.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Bảng pos.Mon hiện chưa có món nào.',
                            style: GoogleFonts.beVietnamPro(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        )
                      else
                        ...ov.menuItems.map(
                          (m) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.daylightSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSoft),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.inkPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Danh mục: ${m.categoryName} · Mã: ${m.code}',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatVnd(m.priceVnd),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mossMid,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 560 : double.infinity,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.daylightSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Trạng thái bàn trực tiếp (pos.Ban)',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _openTableOrderModal(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Mở bàn / Ghi món'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (ov.tables.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Chưa có bàn nào trong pos.Ban.',
                            style: GoogleFonts.beVietnamPro(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        )
                      else
                        ...ov.tables.map(
                          (t) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.daylightSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderSoft),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      t.visualStatus,
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    t.tableCode,
                                    style: GoogleFonts.beVietnamPro(
                                      fontWeight: FontWeight.w800,
                                      color: _statusColor(t.visualStatus),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${t.tableName} · ${t.areaName}',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.inkPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${t.badgeText} · ${t.totalItemsCount} món',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatVnd(t.displayAmountVnd),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedTableId = t.tableId;
                                    });
                                    _selectSection(1);
                                  },
                                  child: const Text('Chi tiết'),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      width: 268,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.inkPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.beVietnamPro(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Điểm vào POS / Sơ đồ bàn cho Manager (thao tác mở bàn, ghi món, VietQR, trả bàn không phụ thuộc ca làm)
  Widget _buildPosFloorSection({required bool isDesktop}) {
    final ov = _overview!;
    final filtered = _filteredTables;
    final selectedTable = _selectedTableCard;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 20 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thanh công cụ tìm kiếm & mở bàn
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
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Tìm nhanh bàn (VD: T01, T02...)',
                      prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.borderSoft,
                        ),
                      ),
                    ),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip('ALL', 'Tất cả (${ov.totalTables})'),
                    _buildFilterChip('EMPTY', 'Trống (${ov.emptyTables})'),
                    _buildFilterChip(
                      'OCCUPIED',
                      'Có khách (${ov.occupiedTables})',
                    ),
                    _buildFilterChip(
                      'AWAITING_QR',
                      'Chờ VietQR (${ov.awaitingQrTables})',
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadManagerOverview,
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Làm mới'),
                    ),
                    ElevatedButton.icon(
                      key: const Key('pos_open_table_modal_button'),
                      onPressed: () => _openTableOrderModal(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mossMid,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
                      label: const Text('Mở bàn / Ghi món'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Lưới thẻ bàn + Panel chi tiết lượt bàn
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 7,
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Không có bàn nào khớp với bộ lọc hiện tại.',
                            style: GoogleFonts.beVietnamPro(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 260,
                                mainAxisExtent: 196,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            return _buildTableCard(filtered[index]);
                          },
                        ),
                ),
                if (isDesktop && selectedTable != null) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 360,
                    child: _buildTableSessionDetailPanel(selectedTable),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String code, String label) {
    final isSelected = _selectedStatusFilter == code;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.mossMid,
      backgroundColor: AppColors.daylightSubtle,
      labelStyle: GoogleFonts.beVietnamPro(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppColors.inkPrimary,
      ),
      onSelected: (_) => setState(() => _selectedStatusFilter = code),
    );
  }

  Color _statusColor(String visualStatus) {
    switch (visualStatus) {
      case 'EMPTY':
        return const Color(0xFF059669); // Emerald Mint
      case 'AWAITING_QR':
        return const Color(0xFFD97706); // Amber Daylight
      case 'ADD_ON':
        return const Color(0xFFEA580C); // Coral Terracotta
      default:
        return const Color(0xFF475569); // Clean Slate
    }
  }

  Widget _buildTableCard(TableCardModel table) {
    final isSelected = table.tableId == _selectedTableId;
    final accent = _statusColor(table.visualStatus);
    final isEmpty = table.visualStatus == 'EMPTY';

    return InkWell(
      key: Key('table_card_${table.tableCode}'),
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _selectedTableId = table.tableId);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.daylightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accent : accent.withValues(alpha: 0.45),
            width: isSelected ? 2.2 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isSelected ? 0.14 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    table.tableCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      table.badgeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              '${table.areaName} · ${table.tableName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                color: AppColors.inkSecondary,
              ),
            ),
            Center(
              child: Text(
                isEmpty ? 'Trống' : _formatVnd(table.displayAmountVnd),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isEmpty ? AppColors.inkMuted : AppColors.inkPrimary,
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty
                        ? 'Sẵn sàng đón khách'
                        : '${table.totalItemsCount} món · ${table.seatedMinutes ?? 1}p',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => _openTableOrderModal(initialTable: table),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(74, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    isEmpty ? '+ Mở bàn' : 'Chi tiết',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSessionDetailPanel(TableCardModel table) {
    final session = table.sessionDetail;
    final accent = _statusColor(table.visualStatus);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.daylightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: session == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_restaurant_outlined,
                  size: 46,
                  color: accent,
                ),
                const SizedBox(height: 12),
                Text(
                  'Bàn ${table.tableCode} (${table.tableName}) đang trống',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quản lý có thể mở lượt sử dụng bàn và ghi món trực tiếp mà không phụ thuộc vào ca làm.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openTableOrderModal(initialTable: table),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mossMid,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Mở bàn & Ghi món'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${table.tableCode} · Lượt #L-${session.sessionId}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        table.badgeText,
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã ngồi: ${session.seatedMinutes} phút · Số đơn: ${session.orders.length}',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AppColors.inkSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.borderSoft),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: session.orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = session.orders[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.daylightSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đơn ${order.displayLabel} (${order.status})',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkPrimary,
                                  ),
                                ),
                                Text(
                                  _formatVnd(order.totalAmountVnd),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.mossMid,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...order.lines.map(
                              (l) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${l.quantity}x ${l.itemName}',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12.5,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatVnd(l.lineTotalVnd),
                                      style: GoogleFonts.beVietnamPro(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amberPreviewBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amberPreviewBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cần thu còn lại:',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberPreviewInk,
                        ),
                      ),
                      Text(
                        _formatVnd(session.remainingAmountVnd),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amberPreviewInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (session.activeUnpaidOrderStatus == 'open' &&
                    session.remainingAmountVnd > 0)
                  ElevatedButton.icon(
                    onPressed: _isActionInProgress
                        ? null
                        : () => _handleRequestVietQr(table),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mossDeep,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Tạo mã VietQR'),
                  ),
                if (session.activeUnpaidOrderStatus == 'awaiting_payment')
                  ElevatedButton.icon(
                    onPressed: _isActionInProgress
                        ? null
                        : () => _handleConfirmPaid(table),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Xác nhận đã thu VietQR'),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isActionInProgress
                            ? null
                            : () => _openTableOrderModal(initialTable: table),
                        icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                        label: const Text('Ghi thêm món'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            (!_isActionInProgress && session.canCloseTable)
                            ? () => _handleCloseTable(table)
                            : null,
                        icon: const Icon(Icons.check_box_outlined, size: 16),
                        label: Text(
                          session.canCloseTable ? 'Trả bàn' : 'Trả bàn (Khóa)',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  /// 3. Màn Đối soát & Duyệt hủy món (hiển thị trạng thái trống / chưa tích hợp API theo đúng phạm vi)
  Widget _buildReconciliationSection() {
    return _buildPendingIntegrationSection(
      badge: 'Đối soát giao dịch & Duyệt hủy món',
      title: 'Đối soát VietQR, Thu dư & Duyệt yêu cầu hủy món',
      description:
          'Theo đặc tả PROJECT.md: các khoản thanh toán đến muộn sau khi đổi QR (ví dụ nhận cả 65.000đ và 90.000đ) và danh sách yêu cầu hủy món có lý do từ nhân viên sẽ hiển thị tại đây để Quản lý duyệt hoặc đối soát.',
      statusTitle: 'Chưa có giao dịch cần đối soát / Chưa tích hợp API đối soát ở bước này',
      statusDetail:
          'Trong phạm vi bước hiện tại, hệ thống giữ nguyên hợp đồng API hiện có và chưa bổ sung endpoint nghiệp vụ mới ngoài luồng đăng nhập & tổng quan sẵn có.',
      icon: Icons.fact_check_outlined,
    );
  }

  /// 5. Màn Trợ lý AI tiếng Việt (hiển thị trạng thái trống / chưa tích hợp API theo đúng phạm vi)
  Widget _buildAiAssistantSection() {
    return _buildPendingIntegrationSection(
      badge: 'Trợ lý AI Local · Qwen 2.5 + QLoRA',
      title: 'Trợ lý AI tiếng Việt (Tool Calling & Mini-Form xác nhận Human-in-the-Loop)',
      description:
          'Hỗ trợ hỏi số liệu kinh doanh bằng tiếng Việt và đề xuất bản nháp thao tác nghiệp vụ (ví dụ: "Thứ Bảy giảm bạc xỉu 10%") qua JSON values + field_meta để Quản lý xem và bấm Xác nhận.',
      statusTitle: 'Chưa kết nối runtime Ollama / vLLM ở giai đoạn này',
      statusDetail:
          'Khung giao diện Quản lý đã sẵn sàng. Luồng gọi model local và render Mini-Form sẽ được kích hoạt ở giai đoạn tích hợp AI.',
      icon: Icons.auto_awesome_rounded,
    );
  }

  Widget _buildPendingIntegrationSection({
    required String badge,
    required String title,
    required String description,
    required String statusTitle,
    required String statusDetail,
    required IconData icon,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.daylightSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.mossSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 30, color: AppColors.mossMid),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.daylightSubtle,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mossMid,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13.5,
                    color: AppColors.inkSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.amberPreviewBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.amberPreviewBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.amberPreviewInk,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusTitle,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.amberPreviewInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              statusDetail,
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 12.5,
                                color: AppColors.amberPreviewInk,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
