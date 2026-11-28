import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../nen_tang/giao_dien/bang_mau.dart';
import '../../nen_tang/mang/cong_api.dart';

/// Hộp thoại Thanh toán VietQR & Tiền mặt cho một đơn hàng.
/// - Tự sinh/cập nhật mã VietQR theo số tiền còn phải thu (hỗ trợ kịch bản gọi thêm món đổi QR).
/// - Tự động kiểm tra biến động thanh toán mỗi 3 giây khi đang chờ quét QR.
/// - Kèm thanh Giả lập Webhook (Dev) để test đủ 3 kịch bản B07: đủ tiền, quét nhầm QR cũ gây thu dư, và chống trùng giao dịch.
class HopThoaiThanhToanVietQr extends StatefulWidget {
  const HopThoaiThanhToanVietQr({
    super.key,
    required this.apiClient,
    required this.orderId,
    required this.orderLabel,
    required this.onPaymentUpdated,
  });

  final PosAuthApiClient apiClient;
  final int orderId;
  final String orderLabel;
  final VoidCallback onPaymentUpdated;

  @override
  State<HopThoaiThanhToanVietQr> createState() =>
      _HopThoaiThanhToanVietQrState();
}

class _HopThoaiThanhToanVietQrState extends State<HopThoaiThanhToanVietQr> {
  Map<String, dynamic>? _state;
  bool _isLoading = true;
  bool _isBusy = false;
  String? _error;
  String? _bannerMsg;
  bool _bannerIsWarn = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initAndGenerateQr();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_isBusy && _state?['orderStatus'] != 'paid') {
        _refreshState(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initAndGenerateQr() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await widget.apiClient.generateOrderVietQrRaw(widget.orderId);
    if (!mounted) return;
    if (res.isSuccess && res.data != null) {
      setState(() {
        _state = res.data;
        _isLoading = false;
        _bannerMsg = res.message;
        _bannerIsWarn = false;
      });
      widget.onPaymentUpdated();
    } else {
      // Nếu đơn đã thanh toán hoặc không thể tạo QR mới, vẫn tải trạng thái hiện tại để xem
      final fallback = await widget.apiClient.getOrderPaymentStateRaw(
        widget.orderId,
      );
      if (!mounted) return;
      setState(() {
        _state = fallback.data;
        _isLoading = false;
        _error = fallback.isSuccess ? null : res.message;
      });
    }
  }

  Future<void> _refreshState({bool silent = false}) async {
    final res = await widget.apiClient.getOrderPaymentStateRaw(widget.orderId);
    if (!mounted) return;
    if (res.isSuccess && res.data != null) {
      final prevStatus = _state?['orderStatus'];
      final newStatus = res.data!['orderStatus'];
      setState(() {
        _state = res.data;
        if (!silent) _error = null;
      });
      if (prevStatus != newStatus) {
        widget.onPaymentUpdated();
      }
    }
  }

  Future<void> _regenerateQr() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    final res = await widget.apiClient.generateOrderVietQrRaw(widget.orderId);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (res.isSuccess && res.data != null) {
        _state = res.data;
        _bannerMsg = res.message;
        _bannerIsWarn = false;
      } else {
        _error = res.message;
      }
    });
    widget.onPaymentUpdated();
  }

  Future<void> _recordCash() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });
    final res = await widget.apiClient.recordCashPaymentRaw(widget.orderId);
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (res.isSuccess && res.data != null) {
        _state = res.data;
        _bannerMsg = res.message;
        _bannerIsWarn = false;
      } else {
        _error = res.message;
      }
    });
    widget.onPaymentUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final st = _state;
    final orderTotal = (st?['orderTotalVnd'] as num?)?.toInt() ?? 0;
    final totalPaid = (st?['totalPaidVnd'] as num?)?.toInt() ?? 0;
    final remaining = (st?['remainingVnd'] as num?)?.toInt() ?? 0;
    final overpaid = (st?['overpaidVnd'] as num?)?.toInt() ?? 0;
    final isPaid = st?['orderStatus'] == 'paid';
    final activeQr = st?['activeQr'] as Map<String, dynamic>?;
    final txs = (st?['transactions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 740),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF133021),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: Color(0xFFC9EBD3),
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thanh toán VietQR · ${st?['orderCode'] ?? widget.orderLabel}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${st?['tableName'] ?? ''} · Tự động cập nhật khi ngân hàng báo tiền về',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: const Color(0xFFC9EBD3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.mossMid,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFDAD6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _error!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF93000A),
                                ),
                              ),
                            ),
                          if (_bannerMsg != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _bannerIsWarn
                                    ? const Color(0xFFFFF4E5)
                                    : const Color(0xFFE6F4EA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _bannerIsWarn
                                      ? const Color(0xFFF59E0B)
                                      : const Color(0xFF16A34A),
                                ),
                              ),
                              child: Text(
                                _bannerMsg!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _bannerIsWarn
                                      ? const Color(0xFF92400E)
                                      : const Color(0xFF133021),
                                ),
                              ),
                            ),

                          // 4 số liệu tóm tắt
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _metricBox('Tổng hóa đơn', _formatVnd(orderTotal)),
                              _metricBox(
                                'Đã thu',
                                _formatVnd(totalPaid),
                                color: const Color(0xFF059669),
                              ),
                              _metricBox(
                                'Còn phải thu',
                                _formatVnd(remaining),
                                color: remaining > 0
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF059669),
                              ),
                              if (overpaid > 0)
                                _metricBox(
                                  'Thu dư (Đối soát)',
                                  _formatVnd(overpaid),
                                  color: const Color(0xFFDC2626),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Khu vực QR + Thông tin chuyển khoản
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Ảnh VietQR
                              Container(
                                width: 250,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F7FA),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.borderSoft,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    if (isPaid)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 42,
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.verified_rounded,
                                              size: 62,
                                              color: Color(0xFF16A34A),
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'ĐÃ THANH TOÁN ĐỦ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF133021),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (activeQr != null) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          '${widget.apiClient.baseUrl}/api/payments/qr-image/${activeQr['id']}',
                                          width: 215,
                                          height: 255,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) => Container(
                                            height: 200,
                                            alignment: Alignment.center,
                                            child: const Text(
                                              'Không tải được ảnh VietQR\n(kiểm tra kết nối mạng)',
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nội dung CK: ${activeQr['referenceCode']}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF133021),
                                        ),
                                      ),
                                    ] else
                                      const Padding(
                                        padding: EdgeInsets.all(24),
                                        child: Text('Chưa có mã QR đang chờ.'),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Thông tin & thao tác
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (activeQr != null) ...[
                                      _infoTile(
                                        'Ngân hàng nhận',
                                        '${activeQr['bankId']} · ${activeQr['accountNo']}',
                                      ),
                                      _infoTile(
                                        'Chủ tài khoản',
                                        (activeQr['accountName'] ?? '')
                                            .toString(),
                                      ),
                                      _infoTile(
                                        'Nội dung chuyển khoản',
                                        (activeQr['referenceCode'] ?? '')
                                            .toString(),
                                      ),
                                      const SizedBox(height: 12),
                                    ],

                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (!isPaid)
                                          ElevatedButton.icon(
                                            onPressed: _isBusy
                                                ? null
                                                : _recordCash,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF133021,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.payments_rounded,
                                              size: 17,
                                            ),
                                            label: const Text(
                                              'Thu tiền mặt đủ',
                                            ),
                                          ),
                                        if (!isPaid)
                                          OutlinedButton.icon(
                                            onPressed: _isBusy
                                                ? null
                                                : _regenerateQr,
                                            icon: const Icon(
                                              Icons.qr_code_rounded,
                                              size: 17,
                                            ),
                                            label: const Text(
                                              'Cập nhật mã QR',
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (!isPaid) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F3F7),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
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
                                            Expanded(
                                              child: Text(
                                                'Đang chờ khách quét mã chuyển khoản — hệ thống sẽ tự xác nhận ngay khi tiền về.',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors
                                                          .inkSecondary,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (txs.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Text(
                              'Giao dịch đã nhận (${txs.length})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...txs.map((t) {
                              final flagged = t['needsReconciliation'] == true;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: flagged
                                      ? const Color(0xFFFFF1F0)
                                      : const Color(0xFFF4F3F7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      t['method'] == 'cash'
                                          ? Icons.payments_outlined
                                          : Icons.qr_code_2_rounded,
                                      size: 18,
                                      color: flagged
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFF133021),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${t['method'] == 'cash' ? 'Tiền mặt tại quầy' : 'Chuyển khoản (${t['gateway'] ?? 'VietQR'})'} · ${t['matchedReferenceCode'] ?? ''}${flagged ? ' · Thu dư cần kiểm tra' : ''}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatVnd(
                                        (t['amountVnd'] as num?)?.toInt() ?? 0,
                                      ),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF133021),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value, {Color? color}) {
    return Container(
      width: 178,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F3F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppColors.inkSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.inkPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
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
