import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../nen_tang/giao_dien/bang_mau.dart';
import '../../mo_hinh/du_lieu_tro_ly_ai.dart';

class TheMiniFormAi extends StatelessWidget {
  const TheMiniFormAi({
    super.key,
    required this.draft,
    required this.dangXacNhan,
    required this.onChinhSua,
    required this.onCapNhatTruong,
    required this.onHuyBo,
    required this.onXacNhan,
  });

  final BanNhapMiniFormAi draft;
  final bool dangXacNhan;
  final VoidCallback onChinhSua;
  final void Function(String key, String value) onCapNhatTruong;
  final VoidCallback onHuyBo;
  final VoidCallback onXacNhan;

  @override
  Widget build(BuildContext context) {
    final isLocked =
        draft.status == 'confirmed' || draft.status == 'cancelled';
    final canEdit = !isLocked && !dangXacNhan;

    final (pillLabel, pillBg, pillFg) = switch (draft.status) {
      'editing' => (
        'Đang chỉnh sửa',
        const Color(0xFFC9EBD3),
        const Color(0xFF032112),
      ),
      'confirmed' => (
        'Đã xác nhận',
        const Color(0xFF133021),
        Colors.white,
      ),
      'cancelled' => (
        'Đã hủy bỏ',
        const Color(0xFFFFDAD6),
        const Color(0xFF93000A),
      ),
      _ => (
        'Chờ xác nhận',
        const Color(0xFFFFDCC3),
        const Color(0xFF2F1500),
      ),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEDF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                size: 22,
                color: Color(0xFF133021),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  draft.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pillLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: pillFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600
                  ? (draft.fields.length >= 4 ? 2 : 3)
                  : 1;
              final spacing = 12.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;

              return Wrap(
                spacing: spacing,
                runSpacing: 12,
                children: draft.fields.map((field) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildField(
                      context: context,
                      field: field,
                      enabled: canEdit,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          if (draft.resultMessage != null &&
              draft.resultMessage!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: draft.status == 'confirmed'
                    ? const Color(0xFFE6F4EA)
                    : const Color(0xFFFFF1F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                draft.resultMessage!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: draft.status == 'confirmed'
                      ? const Color(0xFF133021)
                      : const Color(0xFF93000A),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                height: 42,
                child: TextButton(
                  onPressed: isLocked || dangXacNhan ? null : onHuyBo,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFDCC3),
                    foregroundColor: const Color(0xFF6E3900),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: Text(
                    'Hủy bỏ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: isLocked || dangXacNhan ? null : onXacNhan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF133021),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  icon: dangXacNhan
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 17),
                  label: Text(
                    dangXacNhan ? 'Đang áp dụng...' : 'Xác nhận',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TruongMiniFormAi field,
    required bool enabled,
  }) {
    final hasSelectOptions =
        field.inputType == 'select' && field.options.isNotEmpty;
    final currentSelectValue = hasSelectOptions
        ? (field.options.contains(field.value)
              ? field.value
              : field.options.first)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.inkPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF4F3F7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? const Color(0xFF2A4736) : AppColors.borderSoft,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: hasSelectOptions
              ? DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentSelectValue,
                    isExpanded: true,
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkPrimary,
                    ),
                    onChanged: enabled
                        ? (v) {
                            if (v != null) onCapNhatTruong(field.key, v);
                          }
                        : null,
                    items: field.options
                        .map(
                          (opt) => DropdownMenuItem<String>(
                            value: opt,
                            child: Text(opt, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                  ),
                )
              : field.inputType == 'date'
              ? InkWell(
                  onTap: enabled
                      ? () async {
                          final initial =
                              DateTime.tryParse(field.value) ?? DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            final iso =
                                '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                            onCapNhatTruong(field.key, iso);
                          }
                        }
                      : null,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          field.value.isNotEmpty
                              ? field.value
                              : field.placeholder,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: Color(0xFF133021),
                      ),
                    ],
                  ),
                )
              : TextFormField(
                  key: ValueKey('${draft.draftId}_${field.key}'),
                  initialValue: field.value,
                  enabled: enabled,
                  keyboardType: field.inputType == 'number'
                      ? TextInputType.number
                      : TextInputType.text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkPrimary,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: field.placeholder,
                  ),
                  onChanged: (v) => onCapNhatTruong(field.key, v),
                ),
        ),
      ],
    );
  }
}
