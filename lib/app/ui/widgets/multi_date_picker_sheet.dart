import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../utils/constants/app_colors.dart';
import 'custom_buttons.dart';

class MultiDatePickerSheet extends StatefulWidget {
  final String title;
  final List<DateTime> initialDates;

  const MultiDatePickerSheet({
    super.key,
    required this.title,
    required this.initialDates,
  });

  static Future<List<DateTime>?> show(
    BuildContext context, {
    String title = 'Select Dates',
    List<DateTime> initialDates = const [],
  }) {
    return showModalBottomSheet<List<DateTime>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MultiDatePickerSheet(
        title: title,
        initialDates: initialDates,
      ),
    );
  }

  @override
  State<MultiDatePickerSheet> createState() => _MultiDatePickerSheetState();
}

class _MultiDatePickerSheetState extends State<MultiDatePickerSheet> {
  late DateTime _focusedDay;
  final Set<DateTime> _selectedDates = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    for (var date in widget.initialDates) {
      _selectedDates.add(_normalizeDate(date));
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
            focusedDay: _focusedDay,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(color: AppColors.primary),
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            selectedDayPredicate: (day) {
              final normDay = _normalizeDate(day);
              return _selectedDates.any((d) => _isSameDay(d, normDay));
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
                final normDay = _normalizeDate(selectedDay);
                if (_selectedDates.any((d) => _isSameDay(d, normDay))) {
                  _selectedDates.removeWhere((d) => _isSameDay(d, normDay));
                } else {
                  _selectedDates.add(normDay);
                }
              });
            },
          ),
          const SizedBox(height: 20),
          // Selected dates summary
          if (_selectedDates.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedDates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = _selectedDates.elementAt(index);
                  return Chip(
                    label: Text(
                      DateFormat('dd MMM').format(date),
                      style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary),
                    ),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide.none,
                    deleteIconColor: AppColors.primary,
                    onDeleted: () {
                      setState(() {
                        _selectedDates.remove(date);
                      });
                    },
                  );
                },
              ),
            ),
          if (_selectedDates.isEmpty)
            Text(
              'Select at least 1 date',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.error,
              ),
            ),
          const SizedBox(height: 24),
          // Confirm button
          AppButton(
            title: 'Confirm ${_selectedDates.length} Date(s)',
            onPressed: _selectedDates.isEmpty
                ? null
                : () {
                    final sortedDates = _selectedDates.toList()..sort();
                    Navigator.pop(context, sortedDates);
                  },
          ),
        ],
      ),
    );
  }
}
