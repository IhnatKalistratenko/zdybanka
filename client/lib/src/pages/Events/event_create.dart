import 'dart:math';

import 'package:client/src/pages/Events/choose_tags.dart';
import 'package:client/src/widgets/AppTextInput.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_selector/BottomSheet/multi_selector_bottom_sheet_field.dart';
import 'package:flutter_multi_selector/Utils/multi_selector_item.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

import 'choose_location.dart';

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final TextEditingController _eventNameController = TextEditingController();
  final TextEditingController _eventDescriptionController =
      TextEditingController();
  DateTime? startDate;
  DateTime? endDate;
  PickedData? location;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create new event")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppFormInput(
                inputHintText: "Enter name of the event",
                maxLength: 50,
                title: NecessaryInputTitle(title: "Event name"),
                controller: _eventNameController,
              ),
              SizedBox(height: 5),
              AppFormInput(
                keyboardType: TextInputType.multiline,
                inputHintText: "Enter description",
                maxLength: 1000,
                maxLines: 4,
                title: NecessaryInputTitle(title: "Event description"),
                controller: _eventDescriptionController,
              ),
              SizedBox(height: 5),
              DateTimeInput(
                onDateTimeChange: (DateTime date) {
                  // ToDo: do something with date
                },
                title: NecessaryInputTitle(title: "Start time")
              ),
              SizedBox(height: 10,),
              DateTimeInput(
                onDateTimeChange: (DateTime date) {
                  // ToDo: do something with date
                },
                title: NecessaryInputTitle(title: "End time",)
              ),
              SizedBox(height: 10,),
              LocationInput(
                title: NecessaryInputTitle(title: "Address"),
                onTap: () async {
                  final result = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChooseLocationPage()));
                  setState(() {
                    location = result;
                  });
                },
                address: location?.address,
              ),
              SizedBox(height: 10,),
              MaxParticipantsInput(
                title: NecessaryInputTitle(title: "Max participants"),
                onChanged: (int? value) {
                  print(value);
                },
              ),
              SizedBox(height: 10,),
              TagInput(
                title: Text("Tags", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChooseTagsPage()));
                },
              ),

              SizedBox(height: 10,),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("Create"),
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10))),
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 0, vertical: 20))
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class NecessaryInputTitle extends StatelessWidget {
  final String title;
  const NecessaryInputTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: title),
          TextSpan(
            style: TextStyle(color: Colors.red[400]),
            text: " *",
          ),
        ],
      ),
    );
  }
}

class _DateTimeInputState extends State<DateTimeInput> {
  DateTime? _selectedDateTime;

  DateTime _concatDateTimeWithTimeOfDay(DateTime date, TimeOfDay time) {
    return date.add(Duration(hours: time.hour, minutes: time.minute));
  }

  Future<DateTime?> _selectDate() {
    return showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
  }

  Future<TimeOfDay?> _selectTime() {
    return showTimePicker(context: context, initialTime: TimeOfDay.now());
  }

  String _convertDateTimeToString(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}";
  }

  Future<void> _getDateTime() async {
    DateTime? date = await _selectDate();
    if (date == null) {
      return;
    }
    TimeOfDay? time = await _selectTime();
    if (time == null) {
      return;
    }
    DateTime dateTime = _concatDateTimeWithTimeOfDay(date, time);
    widget.onDateTimeChange(dateTime);

    setState(() {
      _selectedDateTime = dateTime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.title,
        SizedBox(height: 5),
        InkWell(
            onTap: _getDateTime,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.calendar_month),
              suffixIcon: Icon(Icons.chevron_right),
            ),
            child: Text(
              _selectedDateTime == null ? "Select date" : _convertDateTimeToString(_selectedDateTime!),
              style: TextStyle(
              ),
            ),
          ),
        )
      ],
    );
  }
}

class DateTimeInput extends StatefulWidget {
  final Widget title;
  final Function(DateTime) onDateTimeChange;

  const DateTimeInput({
    super.key,
    required this.title,
    required this.onDateTimeChange,
  });

  @override
  State<DateTimeInput> createState() => _DateTimeInputState();
}

class LocationInput extends StatelessWidget {
  final String? address;
  final VoidCallback onTap;
  final Widget title;
  const LocationInput({super.key, required this.onTap, this.address, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        SizedBox(height: 5,),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
              suffixIcon: Icon(Icons.chevron_right),
            ),
            child: Text(
              address ?? "Choose location on map",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class TagInput extends StatelessWidget {
  final Widget title;
  final VoidCallback onTap;
  final items = [MultiSelectorItem<int>(1, "Option One")];
  TagInput({super.key, required this.title, required this.onTap});


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        SizedBox(height: 5,),
        MultiSelectorBottomSheetField(items: items,
        onConfirm: (items) {
          print(items);
        },)
      ],
    );
  }
}

class MaxParticipantsInput extends StatelessWidget {
  final int? maxParticipants;
  final ValueChanged<int?> onChanged;
  final Widget title;

  const MaxParticipantsInput({
    super.key,
    required this.onChanged,
    required this.title,
    this.maxParticipants,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 5),
        TextFormField(
          initialValue: maxParticipants?.toString(),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.people_outline),
            hintText: 'Enter maximum participants',
          ),
          onChanged: (value) {
            final number = int.tryParse(value);
            onChanged(number);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Enter maximum participants';
            }

            final number = int.tryParse(value);

            if (number == null || number < 1) {
              return 'Enter a number greater than 0';
            }

            return null;
          },
        ),
      ],
    );
  }
}


