import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../nen_tang/giao_dien/bang_mau.dart';
import '../../../nen_tang/mang/cong_api.dart';
import '../mo_hinh/du_lieu_ban.dart';

/// Modal phục vụ Mở bàn mới & Ghi món từ dữ liệu thật pos."Ban", pos."DanhMucMon", pos."Mon"
class OpenTableOrderModal extends StatefulWidget {
  final PosAuthApiClient apiClient;
  final List<TableCardModel> tables;
  final List<MenuCategoryModel> categories;
  final List<MenuItemModel> menuItems;
  final TableCardModel? initialTable;

  const OpenTableOrderModal({
    super.key,
    required this.apiClient,
    required this.tables,
    required this.categories,
    required this.menuItems,
    this.initialTable,
  });

  @override
  State<OpenTableOrderModal> createState() => _OpenTableOrderModalState();
}

class _OpenTableOrderModalState extends State<OpenTableOrderModal> {
  late int? _selectedTableId;
  int? _selectedCategoryId;
  final Map<int, int> _quantities = {};
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedTableId =
        widget.initialTable?.tableId ??
        (widget.tables.isNotEmpty ? widget.tables.first.tableId : null);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  TableCardModel? get _selectedTable {
    if (_selectedTableId == null) return null;
    for (final t in widget.tables) {
      if (t.tableId == _selectedTableId) return t;
    }
    return null;
  }

  List<MenuItemModel> get _filteredMenuItems {
    if (_selectedCategoryId == null) return widget.menuItems;
    return widget.menuItems
        .where((m) => m.categoryId == _selectedCategoryId)
        .toList();
  }

  int get _totalSelectedItems =>
      _quantities.values.fold(0, (sum, q) => sum + q);

  int get _totalSelectedVnd {
    int sum = 0;
    for (final entry in _quantities.entries) {
      final item = widget.menuItems.where((m) => m.id == entry.key).firstOrNull;
      if (item != null && entry.value > 0) {
        sum += item.priceVnd * entry.value;
      }
    }
    return sum;
  }

  void _updateQuantity(int menuItemId, int delta) {
    setState(() {
      final current = _quantities[menuItemId] ?? 0;
      final next = current + delta;
      if (next <= 0) {
        _quantities.remove(menuItemId);
      } else {
        _quantities[menuItemId] = next;
      }
    });
  }

  Future<void> _submitOrder() async {
    final table = _selectedTable;
    if (table == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final noteText = _noteController.text.trim();
    final items = _quantities.entries
        .where((e) => e.value > 0)
        .map(
          (e) => OrderItemInputModel(
            menuItemId: e.key,
            quantity: e.value,
            note: noteText.isEmpty ? null : noteText,
          ),
        )
        .toList();

    final result = await widget.apiClient.openTableOrAddItems(
      tableId: table.tableId,
      items: items,
      orderId: table.sessionDetail?.activeUnpaidOrderId,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.message;
      });
      return;
    }

    Navigator.of(context).pop(result.data);
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

  @override
  Widget build(BuildContext context) {
    final selectedTable = _selectedTable;
    final isTableEmpty =
        selectedTable == null || selectedTable.visualStatus == 'EMPTY';

    return Dialog(
      backgroundColor: AppColors.daylightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
                      Icons.restaurant_menu_rounded,
                      color: AppColors.mossMid,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTableEmpty
                              ? 'Mở bàn & Ghi món mới'
                              : 'Ghi thêm món vào lượt bàn ${selectedTable.tableCode}',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                        Text(
                          'Dữ liệu thực đơn lấy trực tiếp từ PostgreSQL (pos.Ban, pos.DanhMucMon, pos.Mon)',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            color: AppColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.borderSoft),
              const SizedBox(height: 16),

              // Chọn bàn
              Text(
                'Chọn bàn phục vụ',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkLabel,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.tables.map((t) {
                  final isSelected = t.tableId == _selectedTableId;
                  return ChoiceChip(
                    label: Text('${t.tableCode} · ${t.tableName} (${t.badgeText})'),
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
                    onSelected: _isSubmitting
                        ? null
                        : (_) => setState(() => _selectedTableId = t.tableId),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Bộ lọc danh mục
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text('Tất cả (${widget.menuItems.length})'),
                      selected: _selectedCategoryId == null,
                      selectedColor: AppColors.mossMid,
                      checkmarkColor: Colors.white,
                      labelStyle: GoogleFonts.beVietnamPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _selectedCategoryId == null
                            ? AppColors.warmCreamText
                            : AppColors.inkPrimary,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategoryId = null),
                    ),
                    const SizedBox(width: 8),
                    ...widget.categories.map((cat) {
                      final selected = _selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${cat.name} (${cat.itemCount})'),
                          selected: selected,
                          selectedColor: AppColors.mossMid,
                          checkmarkColor: Colors.white,
                          labelStyle: GoogleFonts.beVietnamPro(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.warmCreamText
                                : AppColors.inkPrimary,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategoryId = cat.id),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Danh sách món
              Expanded(
                child: _filteredMenuItems.isEmpty
                    ? Center(
                        child: Text(
                          'Chưa có món nào trong danh mục này.',
                          style: GoogleFonts.beVietnamPro(
                            color: AppColors.inkMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredMenuItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _filteredMenuItems[index];
                          final qty = _quantities[item.id] ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: qty > 0
                                  ? AppColors.mossSoft
                                  : AppColors.daylightSubtle,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: qty > 0
                                    ? AppColors.mossMid
                                    : AppColors.borderSoft,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.inkPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${item.categoryName} · Mã: ${item.code}',
                                        style: GoogleFonts.beVietnamPro(
                                          fontSize: 12,
                                          color: AppColors.inkSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatVnd(item.priceVnd),
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.mossMid,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                IconButton(
                                  onPressed: qty > 0 && !_isSubmitting
                                      ? () => _updateQuantity(item.id, -1)
                                      : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: 26,
                                  child: Text(
                                    '$qty',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: !_isSubmitting
                                      ? () => _updateQuantity(item.id, 1)
                                      : null,
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                    color: AppColors.mossMid,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                enabled: !_isSubmitting,
                style: GoogleFonts.beVietnamPro(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Ghi chú món (VD: ít đá, giảm ngọt...)',
                  filled: true,
                  fillColor: AppColors.inputFill,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderSoft),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.danger,
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giỏ tạm: $_totalSelectedItems món',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12.5,
                          color: AppColors.inkSecondary,
                        ),
                      ),
                      Text(
                        'Tạm tính: ${_formatVnd(_totalSelectedVnd)}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkPrimary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: (_isSubmitting || selectedTable == null)
                        ? null
                        : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mossMid,
                      foregroundColor: AppColors.warmCreamText,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(
                      _totalSelectedItems > 0
                          ? 'Xác nhận ghi món (${_formatVnd(_totalSelectedVnd)})'
                          : (isTableEmpty ? 'Chỉ mở bàn' : 'Cập nhật bàn'),
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
  }
}
