
import 'package:flutter/material.dart';

import 'form_field_container.dart';

class DateTimeInput extends StatelessWidget {
  final String title;
  final bool required;
  final DateTime? value;
  final DateTime? minDate;
  final DateTime maxDate;
  final String? errorText;
  final ValueChanged<DateTime> onChanged;

  const DateTimeInput({
    super.key,
    required this.title,
    required this.maxDate,
    required this.onChanged,
    this.required = false,
    this.value,
    this.minDate,
    this.errorText,
  });

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _selectDateTime(BuildContext context) async {
    final now = DateTime.now();
    final today = _dateOnly(now);
    final lastDate = _dateOnly(maxDate);

    var firstDate = today;

    if (minDate != null &&
        _dateOnly(minDate!).isAfter(firstDate)) {
      firstDate = _dateOnly(minDate!);
    }

    if (firstDate.isAfter(lastDate)) return;

    var initialDate = _dateOnly(value ?? firstDate);

    if (initialDate.isBefore(firstDate)) {
      initialDate = firstDate;
    } else if (initialDate.isAfter(lastDate)) {
      initialDate = lastDate;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: value != null
          ? TimeOfDay.fromDateTime(value!)
          : TimeOfDay.now(),
    );

    if (time == null) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    onChanged(selected);
  }

  String _formatDateTime(DateTime value) {
    String twoDigits(int number) =>
        number.toString().padLeft(2, '0');

    return '${value.year}-${twoDigits(value.month)}-'
        '${twoDigits(value.day)} '
        '${twoDigits(value.hour)}:${twoDigits(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return FormFieldContainer(
      title: title,
      required: required,
      errorText: errorText,
      child: InkWell(
        onTap: () => _selectDateTime(context),
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.calendar_month),
            suffixIcon: Icon(Icons.chevron_right),
          ),
          child: Text(
            value == null
                ? 'Select date and time'
                : _formatDateTime(value!),
          ),
        ),
      ),
    );
  }
}

class SelectableInput extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const SelectableInput({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.chevron_right),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
