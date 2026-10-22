import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import '../../models/create_event_request.dart';
import '../../models/event_tag.dart';
import '../../services/event_service.dart';
import '../../widgets/event_form_inputs.dart';
import '../../widgets/form_field_container.dart';
import 'choose_location.dart';
import 'package:flutter_multi_selector/flutter_multi_selector.dart';

class CreateEventPage extends StatefulWidget {
  final EventService eventService;

  const CreateEventPage({
    super.key,
    required this.eventService,
  });

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();

  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  PickedData? _location;
  int? _maxParticipants;

  List<EventTag> _selectedTags = [];

  String? _startDateError;
  String? _endDateError;
  String? _locationError;
  String? _submitError;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  DateTime get _now => DateTime.now();

  DateTime get _latestAllowedDate =>
      _now.add(const Duration(days: 365));

  String? _validateStartDate()
  {
    if (_startDate == null) {
      return 'Select the start date and time';
    } else if (!_startDate!.isAfter(_now)) {
      return 'Start time must be in the future';
    } else if (_startDate!.isAfter(_latestAllowedDate)) {
      return 'Start time cannot be more than 365 days ahead';
    }

    return null;
  }

  String? _validateEndDate()
  {
    if (_endDate == null) {
      return 'Select the end date and time';
    } else if (_startDate != null &&
        !_endDate!.isAfter(_startDate!)) {
      return 'End time must be after start time';
    } else if (_endDate!.isAfter(_latestAllowedDate)) {
      return 'End time cannot be more than 365 days ahead';
    }

    return null;
  }

  String? _validateLocation()
  {
    if (_location == null) {
      return 'Choose the event location on the map';
    }

    return null;
  }

  bool _validateNonTextFields() {
    String? startError;
    String? endError;
    String? locationError;

    startError = _validateStartDate();
    endError = _validateEndDate();
    locationError = _validateLocation();

    setState(() {
      _startDateError = startError;
      _endDateError = endError;
      _locationError = locationError;
    });

    return startError == null &&
        endError == null &&
        locationError == null;
  }

  Future<void> _chooseLocation() async {
    final result = await Navigator.of(context).push<PickedData>(
      MaterialPageRoute(
        builder: (_) => ChooseLocationPage(),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _location = result;
      _locationError = null;
      _submitError = null;
    });
  }

  Future<void> _chooseTags(List<EventTag> tags) async {
    setState(() {
      _selectedTags = tags;
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    final formIsValid = _formKey.currentState!.validate();
    final otherFieldsAreValid = _validateNonTextFields();

    if (!formIsValid || !otherFieldsAreValid) {
      return;
    }

    final location = _location!;
    final start = _startDate!;
    final end = _endDate!;
    final maxParticipants = _maxParticipants!;

    // Перевір структуру PickedData у встановленій версії пакета.
    // Зазвичай координати доступні через location.latLong.
    final request = CreateEventRequest(
      name: _eventNameController.text.trim(),
      description: _eventDescriptionController.text.trim(),
      startTime: start,
      endTime: end,
      address: location.address,
      latitude: location.latLong.latitude,
      longitude: location.latLong.longitude,
      maxParticipants: maxParticipants,
      tagIds: _selectedTags.map((tag) => tag.id).toList(),
    );

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await widget.eventService.createEvent(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event created successfully'),
        ),
      );

      Navigator.of(context).pop(true);
    } on EventServiceException catch (error) {
      if (!mounted) return;

      setState(() {
        _submitError = error.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _submitError =
        'Could not create the event. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create new event',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 26,
        )),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FormFieldContainer(
                  title: 'Event name',
                  required: true,
                  child: TextFormField(
                    controller: _eventNameController,
                    maxLength: 50,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter name of the event',
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';

                      if (name.isEmpty) {
                        return 'Enter event name';
                      }

                      if (name.length < 3) {
                        return 'Name must contain at least 3 characters';
                      }

                      if (name.length > 50) {
                        return 'Name cannot exceed 50 characters';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                FormFieldContainer(
                  title: 'Event description',
                  required: true,
                  child: TextFormField(
                    controller: _eventDescriptionController,
                    maxLength: 1000,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter description',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) {
                      final description = value?.trim() ?? '';

                      if (description.isEmpty) {
                        return 'Enter event description';
                      }

                      if (description.length > 1000) {
                        return 'Description cannot exceed 1000 characters';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                DateTimeInput(
                  title: 'Start time',
                  required: true,
                  value: _startDate,
                  errorText: _startDateError,
                  maxDate: _latestAllowedDate,
                  onChanged: (date) {
                    setState(() {
                      _startDate = date;
                      _startDateError = null;
                      _endDateError = null;
                      _submitError = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                DateTimeInput(
                  title: 'End time',
                  required: true,
                  value: _endDate,
                  errorText: _endDateError,
                  minDate: _startDate,
                  maxDate: _latestAllowedDate,
                  onChanged: (date) {
                    setState(() {
                      _endDate = date;
                      _endDateError = null;
                      _submitError = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                FormFieldContainer(
                  title: 'Address',
                  required: true,
                  errorText: _locationError,
                  child: SelectableInput(
                    icon: Icons.location_on_outlined,
                    text: _location?.address ??
                        'Choose location on map',
                    onTap: _chooseLocation,
                  ),
                ),
                const SizedBox(height: 12),

                FormFieldContainer(
                  title: 'Max participants',
                  required: true,
                  child: TextFormField(
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
                      setState(() {
                        _maxParticipants = int.tryParse(value);
                        _submitError = null;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter maximum participants';
                      }

                      final number = int.tryParse(value);

                      if (number == null || number < 1) {
                        return 'Enter a valid positive integer';
                      }

                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                FormFieldContainer(
                  title: 'Tags',
                  child: MultiSelectorBottomSheetField<EventTag>(
                    items: [],
                    onConfirm: _chooseTags,
                  )
                ),
                const SizedBox(height: 16),

                if (_submitError != null) ...[
                  Text(
                    _submitError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Create'),
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
