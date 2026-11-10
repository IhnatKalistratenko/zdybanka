import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';
import 'package:flutter_multi_selector/flutter_multi_selector.dart';

import '../../models/create_event_request.dart';
import '../../models/event.dart';
import '../../models/event_tag.dart';
import '../../services/event_service.dart';
import '../../services/tag_service.dart';
import '../../widgets/event_form_inputs.dart';
import '../../widgets/form_field_container.dart';
import 'choose_location.dart';

class EditEventPage extends StatefulWidget {
  final String eventId;

  const EditEventPage({super.key, required this.eventId});

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _eventService = EventService();
  final _tagService = TagService();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _address;
  double? _latitude;
  double? _longitude;
  List<EventTag> _availableTags = [];
  List<EventTag> _selectedTags = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;
  String? _startDateError;
  String? _endDateError;
  String? _locationError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadEventAndTags();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<void> _loadEventAndTags() async {
    try {
      final results = await Future.wait<dynamic>([
        _eventService.getEventById(widget.eventId),
        _tagService.getTags(),
      ]);
      final event = results[0] as Event;
      final tags = results[1] as List<EventTag>;
      if (!mounted) return;

      setState(() {
        _eventNameController.text = event.name;
        _eventDescriptionController.text = event.description;
        _maxParticipantsController.text = event.maxParticipants.toString();
        _startDate = event.startTime.toLocal();
        _endDate = event.endTime.toLocal();
        _address = event.address;
        _latitude = event.latitude;
        _longitude = event.longitude;
        _availableTags = tags;
        _selectedTags = tags
            .where((tag) => event.tags.any((eventTag) => eventTag.id == tag.id))
            .toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isLoading = false;
      });
    }
  }

  DateTime get _latestAllowedDate =>
      DateTime.now().add(const Duration(days: 365));

  String? _validateStartDate() {
    if (_startDate == null) return 'Select the start date and time';
    if (!_startDate!.isAfter(DateTime.now())) {
      return 'Start time must be in the future';
    }
    if (_startDate!.isAfter(_latestAllowedDate)) {
      return 'Start time cannot be more than 365 days ahead';
    }
    return null;
  }

  String? _validateEndDate() {
    if (_endDate == null) return 'Select the end date and time';
    if (_startDate != null && !_endDate!.isAfter(_startDate!)) {
      return 'End time must be after start time';
    }
    if (_endDate!.isAfter(_latestAllowedDate)) {
      return 'End time cannot be more than 365 days ahead';
    }
    return null;
  }

  Future<void> _chooseLocation() async {
    final result = await Navigator.of(context).push<PickedData>(
      MaterialPageRoute(builder: (_) => const ChooseLocationPage()),
    );
    if (!mounted || result == null) return;
    setState(() {
      _address = result.address;
      _latitude = result.latLong.latitude;
      _longitude = result.latLong.longitude;
      _locationError = null;
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    final formIsValid = _formKey.currentState!.validate();
    final startError = _validateStartDate();
    final endError = _validateEndDate();
    final locationError =
        _address == null || _latitude == null || _longitude == null
        ? 'Choose the event location on the map'
        : null;
    setState(() {
      _startDateError = startError;
      _endDateError = endError;
      _locationError = locationError;
    });
    if (!formIsValid ||
        startError != null ||
        endError != null ||
        locationError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });
    try {
      await _eventService.updateEvent(
        widget.eventId,
        CreateEventRequest(
          name: _eventNameController.text.trim(),
          description: _eventDescriptionController.text.trim(),
          startTime: _startDate!,
          endTime: _endDate!,
          address: _address!,
          latitude: _latitude!,
          longitude: _longitude!,
          maxParticipants: int.parse(_maxParticipantsController.text),
          tagIds: _selectedTags.map((tag) => tag.id).toList(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event updated successfully')),
      );
      Navigator.of(context).pop();
    } on EventServiceException catch (error) {
      if (mounted) setState(() => _submitError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _submitError = 'Could not update the event. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit event',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 26),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Could not load event: $_loadError'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _loadError = null;
                          });
                          _loadEventAndTags();
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
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
                            if (name.isEmpty) return 'Enter event name';
                            if (name.length < 3)
                              return 'Name must contain at least 3 characters';
                            if (name.length > 50)
                              return 'Name cannot exceed 50 characters';
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
                            if (description.isEmpty)
                              return 'Enter event description';
                            if (description.length > 1000)
                              return 'Description cannot exceed 1000 characters';
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
                        onChanged: (date) => setState(() {
                          _startDate = date;
                          _startDateError = null;
                          _endDateError = null;
                          _submitError = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      DateTimeInput(
                        title: 'End time',
                        required: true,
                        value: _endDate,
                        errorText: _endDateError,
                        minDate: _startDate,
                        maxDate: _latestAllowedDate,
                        onChanged: (date) => setState(() {
                          _endDate = date;
                          _endDateError = null;
                          _submitError = null;
                        }),
                      ),
                      const SizedBox(height: 12),
                      FormFieldContainer(
                        title: 'Address',
                        required: true,
                        errorText: _locationError,
                        child: SelectableInput(
                          icon: Icons.location_on_outlined,
                          text: _address ?? 'Choose location on map',
                          onTap: _chooseLocation,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FormFieldContainer(
                        title: 'Max participants',
                        required: true,
                        child: TextFormField(
                          controller: _maxParticipantsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people_outline),
                            hintText: 'Enter maximum participants',
                          ),
                          validator: (value) {
                            final number = int.tryParse(value ?? '');
                            if (number == null || number < 1)
                              return 'Enter a valid positive integer';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      FormFieldContainer(
                        title: 'Tags',
                        child: MultiSelectorBottomSheetField<EventTag>(
                          items: _availableTags
                              .map(
                                (tag) =>
                                    MultiSelectorItem<EventTag>(tag, tag.name),
                              )
                              .toList(),
                          initialValue: _selectedTags,
                          onConfirm: (tags) =>
                              setState(() => _selectedTags = tags),
                        ),
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
                              : const Text('Save changes'),
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
