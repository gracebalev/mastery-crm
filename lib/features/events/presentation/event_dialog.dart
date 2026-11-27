import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/event.dart';
import 'event_controller.dart';

Future<bool> showEventDialog({
  required BuildContext context,
  required EventController controller,
  MasteryEvent? event,
}) async =>
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _EventDialog(controller: controller, event: event),
    ) ??
    false;

class _EventDialog extends StatefulWidget {
  const _EventDialog({required this.controller, this.event});
  final EventController controller;
  final MasteryEvent? event;

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _website;
  late final TextEditingController _notes;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.event?.name ?? '');
    _location = TextEditingController(text: widget.event?.location ?? '');
    _website = TextEditingController(text: widget.event?.websiteUrl ?? '');
    _notes = TextEditingController(text: widget.event?.notes ?? '');
    _startDate = widget.event?.startDate;
    _endDate = widget.event?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _website.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: SizedBox(
      width: 560,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.event == null ? 'New event' : 'Edit event',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Save the event where contacts were discovered.',
                style: TextStyle(color: mutedInk),
              ),
              const SizedBox(height: 22),
              _label('EVENT NAME', required: true),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  hintText: 'e.g. Warsaw Growth Summit',
                ),
                validator: (value) => value?.trim().isEmpty ?? true
                    ? 'Event name is required.'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('START DATE'),
                        InkWell(
                          onTap: _pickStartDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(
                              _startDate == null
                                  ? 'Optional'
                                  : _formatDate(_startDate!),
                              style: TextStyle(
                                color: _startDate == null
                                    ? placeholderInk
                                    : ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('END DATE'),
                        InkWell(
                          onTap: _pickEndDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                            ),
                            child: Text(
                              _endDate == null
                                  ? 'Optional'
                                  : _formatDate(_endDate!),
                              style: TextStyle(
                                color: _endDate == null ? placeholderInk : ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _field('LOCATION', _location, 'e.g. Warsaw'),
              const SizedBox(height: 16),
              _field('WEBSITE URL', _website, 'https://event.example.com'),
              const SizedBox(height: 16),
              _label('NOTES'),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'What made this event relevant?',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving...' : 'Save event'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field(String label, TextEditingController controller, String hint) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );

  Widget _label(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      required ? '$text *' : text,
      style: const TextStyle(
        color: mutedInk,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        _startDate = selected;
        if (_endDate != null && _endDate!.isBefore(selected)) {
          _endDate = selected;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _endDate = selected);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startDate != null &&
        _endDate != null &&
        _endDate!.isBefore(_startDate!)) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.save(
        EventFormValue(
          name: _name.text,
          startDate: _startDate,
          endDate: _endDate,
          location: _location.text,
          websiteUrl: _website.text,
          notes: _notes.text,
        ),
        existing: widget.event,
      );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
