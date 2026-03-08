import 'package:flutter/material.dart';
import 'package:wedding_farm_booking/app/utils/constants/app_colors.dart';

class CustomDropdown extends StatefulWidget {
  const CustomDropdown({
    super.key,
    required this.list,
    required this.onSelect,
    this.initialValue,
    this.title,
  });

  final List<String> list;
  final Function(String value) onSelect;
  final String? initialValue;
  final String? title;

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showSelectionSheet,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedValue ?? (widget.title ?? 'Select'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedValue == null ? AppColors.grey : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ListView.builder(
        itemCount: widget.list.length,
        shrinkWrap: true,
        itemBuilder: (ctx, index) {
          final item = widget.list[index];
          final isSelected = selectedValue == item;
          return ListTile(
            title: Text(item),
            trailing: isSelected ? Icon(Icons.check_circle, color: AppColors.primary) : null,
            onTap: () {
              setState(() => selectedValue = item);
              widget.onSelect(item);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }
}
