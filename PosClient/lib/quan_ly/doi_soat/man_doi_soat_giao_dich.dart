import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nen_tang/giao_dien/bang_mau.dart';
import '../../nen_tang/mang/cong_api.dart';

/// Màn Đối soát giao dịch VietQR & Thu dư cho Quản lý.
class ManDoiSoatGiaoDich extends StatefulWidget {
  const ManDoiSoatGiaoDich({
    super.key,
    required this.apiClient,
    required this.onToast,
  });

  final PosAuthApiClient apiClient;
  final void Function(String message, {bool isError}) onToast;

  @override
  State<ManDoiSoatGiaoDich> createState() => _ManDoiSoatGiaoDichState();
}

class _ManDoiSoatGiaoDichState extends State<ManDoiSoatGiaoDich> {
  String _filter = 'all';
  bool _loading = true;
  String? _error;
  int _pendingCount = 0;
  int _resolvedCount = 0;
  int _pendingTotalVnd = 0;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await widget.apiClient.getReconciliationRaw(filter: _filter);
    if (!mounted) return;
    if (res.isSuccess && res.data != null) {
      final d = res.data!;
      setState(() {
        _loading = false;
        _pendingCount = (d['pendingCount'] as num?)?.toInt() ?? 0;
        _resolvedCount = (d['resolvedCount'] as num?)?.toInt() ?? 0;
        _pendingTotalVnd =
            (d['pendingOverpaidTotalVnd'] as num?)?.toInt() ?? 0;
        _items = (d['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
      });
    } else {
      setState(() {
        _loading = false;
        _error = res.message;
      });
    }
  }

  Future<void> _openResolveDialog(Map<String, dynamic> tx) async {
    final noteCtrl = TextEditingController(
      text: 'Đã hoàn tiền mặt cho khách tại quầy và đối chiếu sao kê.',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đã đối soát giao dịch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đơn ${tx['orderCode']} · Số tiền ${_formatVnd((tx['amountVnd'] as num?)?.toInt() ?? 0)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Ghi chú xử lý / hoàn tiền',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF133021),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hoàn tất đối soát'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final res = await widget.apiClient.resolveReconciliationRaw(
      (tx['id'] as num).toInt(),
      resolutionNote: noteCtrl.text.trim(),
    );
    if (!mounted) return;
    if (res.isSuccess) {
      widget.onToast(res.message);
      _load();
    } else {
      widget.onToast(res.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đối soát giao dịch VietQR & Thu dư',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Theo dõi tiền chuyển khoản, tiền mặt và xử lý các khoản khách chuyển dư hoặc chuyển nhầm mã QR cũ.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        color: AppColors.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Làm mới'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 KPI cards
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _kpiCard(
                'Giao dịch cần đối soát',
                '$_pendingCount giao dịch',
                Icons.warning_amber_rounded,
                const Color(0xFFD97706),
              ),
              _kpiCard(
                'Giá trị chờ xử lý',
                _formatVnd(_pendingTotalVnd),
                Icons.account_balance_wallet_outlined,
                const Color(0xFFDC2626),
              ),
              _kpiCard(
                'Đã hoàn tất đối soát',
                '$_resolvedCount giao dịch',
                Icons.verified_rounded,
                const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _filterChip('all', 'Tất cả giao dịch'),
              _filterChip('pending', 'Chờ đối soát ($_pendingCount)'),
              _filterChip('resolved', 'Đã xử lý ($_resolvedCount)'),
            ],
          ),
          const SizedBox(height: 14),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.mossMid),
              ),
            )
          else if (_error != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(_error!),
            )
          else if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    size: 42,
                    color: AppColors.mossMid,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Chưa có giao dịch thanh toán nào trong bộ lọc này',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hãy vào Sơ đồ bàn, mở đơn hàng và chọn Thanh toán để bắt đầu ghi nhận giao dịch.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.inkSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._items.map(_buildTxCard),
        ],
      ),
    );
  }

  Widget _buildTxCard(Map<String, dynamic> tx) {
    final needsRec = tx['needsReconciliation'] == true;
    final recStatus = (tx['reconciliationStatus'] ?? 'KhongCan').toString();
    final isPending = needsRec && recStatus == 'ChoXuLy';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? const Color(0xFFF59E0B) : AppColors.borderSoft,
          width: isPending ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFFFF4E5)
                  : const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tx['method'] == 'cash'
                  ? Icons.payments_outlined
                  : Icons.qr_code_2_rounded,
              color: isPending
                  ? const Color(0xFFD97706)
                  : const Color(0xFF133021),
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
                      'Đơn ${tx['orderCode']} · ${tx['tableName']}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.inkPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isPending
                            ? const Color(0xFFFFF4E5)
                            : recStatus == 'DaXuLy'
                            ? const Color(0xFFE6F4EA)
                            : const Color(0xFFF4F3F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isPending
                            ? 'Cần đối soát'
                            : recStatus == 'DaXuLy'
                            ? 'Đã đối soát'
                            : 'Hợp lệ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPending
                              ? const Color(0xFFB45309)
                              : const Color(0xFF133021),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Hình thức: ${tx['method'] == 'cash' ? 'Tiền mặt' : 'Chuyển khoản (${tx['gateway'] ?? 'VietQR'})'} · Mã giao dịch: ${tx['bankTransactionId'] ?? '—'} · Nội dung: ${tx['matchedReferenceCode'] ?? '—'}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppColors.inkSecondary,
                  ),
                ),
                if (tx['reconciliationNote'] != null &&
                    tx['reconciliationNote'].toString().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    tx['reconciliationNote'].toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isPending
                          ? const Color(0xFFB45309)
                          : AppColors.inkPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatVnd((tx['amountVnd'] as num?)?.toInt() ?? 0),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF133021),
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _openResolveDialog(tx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF133021),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  child: const Text('Xác nhận đã đối soát'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color accent) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.inkSecondary,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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

  Widget _filterChip(String code, String label) {
    final selected = _filter == code;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF133021),
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColors.inkPrimary,
      ),
      onSelected: (_) {
        setState(() => _filter = code);
        _load();
      },
    );
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
