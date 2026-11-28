import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/entities.dart';
import 'contact_controller.dart';

Future<bool> showContactDialog({
  required BuildContext context,
  required ContactController controller,
  Contact? contact,
  Company? initialCompany,
  String? initialEventId,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ContactDialog(
      controller: controller,
      contact: contact,
      initialCompany: initialCompany,
      initialEventId: initialEventId,
    ),
  );
  return result ?? false;
}

class _ContactDialog extends StatefulWidget {
  const _ContactDialog({
    required this.controller,
    this.contact,
    this.initialCompany,
    this.initialEventId,
  });
  final ContactController controller;
  final Contact? contact;
  final Company? initialCompany;
  final String? initialEventId;

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _role;
  late final TextEditingController _sourceNote;
  late final TextEditingController _linkedin;
  final _segment = TextEditingController();
  final List<_EmailEditor> _emails = [];
  final List<String> _segments = [];
  String? _companyId;
  String? _primaryEmailId;
  String? _sourceEventId;
  bool _canReceiveCampaignEmails = false;
  bool _saving = false;
  String? _error;
  var _emailSequence = 0;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;
    final company = contact == null
        ? widget.initialCompany
        : widget.controller.companies
              .where((item) => item.id == contact.companyId)
              .firstOrNull;
    _name = TextEditingController(text: contact?.fullName ?? '');
    _company = TextEditingController(text: company?.name ?? '');
    _companyId = company?.id;
    _role = TextEditingController(text: contact?.role ?? '');
    _sourceNote = TextEditingController(text: contact?.sourceNote ?? '');
    _sourceEventId = contact?.sourceEventId ?? widget.initialEventId;
    _linkedin = TextEditingController(text: contact?.linkedinUrl ?? '');
    _segments.addAll(contact?.segments ?? const []);
    _canReceiveCampaignEmails = contact?.canReceiveCampaignEmails ?? false;
    if (contact == null) {
      final email = _newEmail();
      _emails.add(email);
      _primaryEmailId = email.id;
    } else {
      _emails.addAll(
        contact.emails.map(
          (email) => _EmailEditor(
            id: email.id,
            address: email.address,
            label: email.label ?? 'Work',
          ),
        ),
      );
      _primaryEmailId = contact.primaryEmailId;
    }
  }

  _EmailEditor _newEmail() => _EmailEditor(
    id: 'email_${DateTime.now().microsecondsSinceEpoch}_${_emailSequence++}',
    address: '',
    label: _emails.isEmpty ? 'Work' : '',
  );

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _role.dispose();
    _sourceNote.dispose();
    _linkedin.dispose();
    _segment.dispose();
    for (final email in _emails) {
      email.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 720,
        height: MediaQuery.sizeOf(context).height.clamp(600, 850).toDouble(),
        child: Column(
          children: [
            _header(),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _fieldLabel('FULL NAME', required: true),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(),
                      validator: _required,
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('COMPANY', required: true),
                    Autocomplete<Company>(
                      initialValue: TextEditingValue(text: _company.text),
                      displayStringForOption: (company) => company.name,
                      optionsBuilder: (value) {
                        final query = value.text.trim().toLowerCase();
                        if (query.isEmpty) return widget.controller.companies;
                        return widget.controller.companies.where(
                          (company) =>
                              company.name.toLowerCase().contains(query),
                        );
                      },
                      onSelected: (company) {
                        _companyId = company.id;
                        _company.text = company.name;
                      },
                      fieldViewBuilder:
                          (context, textController, focusNode, onSubmit) {
                            textController.addListener(() {
                              if (_company.text != textController.text) {
                                _company.text = textController.text;
                                if (widget.controller.companies
                                        .where((item) => item.id == _companyId)
                                        .firstOrNull
                                        ?.name !=
                                    textController.text) {
                                  _companyId = null;
                                }
                              }
                            });
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: const InputDecoration(),
                              validator: _required,
                            );
                          },
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(child: _fieldLabel('EMAIL ADDRESSES')),
                        TextButton.icon(
                          onPressed: _addEmail,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add email'),
                        ),
                      ],
                    ),
                    if (_emails.isNotEmpty) _emailColumnsHeader(),
                    if (_emails.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'No email yet. You can add one later.',
                          style: TextStyle(color: placeholderInk, fontSize: 12),
                        ),
                      ),
                    ..._emails.map(_emailRow),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _labeledField('ROLE IN COMPANY', _role),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('EVENT'),
                              DropdownButtonFormField<String>(
                                initialValue: _sourceEventId,
                                isExpanded: true,
                                items: [
                                  const DropdownMenuItem(
                                    value: '',
                                    child: Text('No event'),
                                  ),
                                  ...widget.controller.events.map(
                                    (event) => DropdownMenuItem(
                                      value: event.id,
                                      child: Text(
                                        event.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(
                                  () => _sourceEventId =
                                      value == null || value.isEmpty
                                      ? null
                                      : value,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('SOURCE NOTE'),
                    TextFormField(
                      controller: _sourceNote,
                      decoration: const InputDecoration(),
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('LINKEDIN URL'),
                    TextFormField(
                      controller: _linkedin,
                      decoration: const InputDecoration(),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        final uri = Uri.tryParse(text);
                        return uri != null &&
                                uri.hasScheme &&
                                uri.host.isNotEmpty
                            ? null
                            : 'Enter a complete URL.';
                      },
                    ),
                    const SizedBox(height: 18),
                    _fieldLabel('SEGMENTS'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._segments.map(
                          (segment) => InputChip(
                            label: Text(segment),
                            onDeleted: () =>
                                setState(() => _segments.remove(segment)),
                          ),
                        ),
                        SizedBox(
                          width: 250,
                          child: Autocomplete<String>(
                            optionsBuilder: (value) {
                              final query = value.text.trim().toLowerCase();
                              if (query.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return widget.controller.knownSegments.where(
                                (item) =>
                                    !_segments.contains(item) &&
                                    item.toLowerCase().contains(query),
                              );
                            },
                            onSelected: _addSegment,
                            fieldViewBuilder:
                                (context, textController, focusNode, onSubmit) {
                                  textController.addListener(
                                    () => _segment.text = textController.text,
                                  );
                                  return TextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    decoration: InputDecoration(
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () =>
                                            _addSegment(textController.text),
                                      ),
                                    ),
                                    onSubmitted: _addSegment,
                                  );
                                },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    CheckboxListTile(
                      value: _hasEnteredEmail && _canReceiveCampaignEmails,
                      onChanged: _hasEnteredEmail
                          ? (value) => setState(
                              () => _canReceiveCampaignEmails = value ?? false,
                            )
                          : null,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text('Include in email outreach'),
                      subtitle: Text(
                        _hasEnteredEmail
                            ? 'Uses the selected primary email.'
                            : 'Add an email before enabling outreach.',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving
                          ? 'Saving...'
                          : widget.contact == null
                          ? 'Add contact'
                          : 'Save changes',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(24, 20, 16, 18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.contact == null ? 'Add contact' : 'Edit contact',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.contact == null
                    ? 'Create a person in your Mastery contact list'
                    : 'Update contact details and email addresses',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );

  Widget _emailRow(_EmailEditor email) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final primaryButton = IconButton(
          tooltip: 'Make primary',
          onPressed: () => setState(() => _primaryEmailId = email.id),
          icon: Icon(
            email.id == _primaryEmailId
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: email.id == _primaryEmailId ? brandPurple : mutedInk,
          ),
        );
        final addressField = TextFormField(
          controller: email.address,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(),
          validator: (value) {
            final text = normalizeEmail(value ?? '');
            if (text.isEmpty) return null;
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                ? null
                : 'Enter a valid email.';
          },
        );
        final labelField = TextFormField(
          controller: email.label,
          decoration: const InputDecoration(),
        );
        final deleteButton = IconButton(
          tooltip: 'Delete email',
          onPressed: () => _removeEmail(email),
          icon: const Icon(Icons.delete_outline),
        );
        if (constraints.maxWidth < 500) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  primaryButton,
                  Expanded(child: addressField),
                  deleteButton,
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 48, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_emailColumnLabel('LABEL'), labelField],
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            primaryButton,
            Expanded(flex: 3, child: addressField),
            const SizedBox(width: 10),
            Expanded(child: labelField),
            deleteButton,
          ],
        );
      },
    ),
  );

  Widget _emailColumnsHeader() => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 500) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: Center(child: _emailColumnLabel('PRIMARY')),
              ),
              Expanded(child: _emailColumnLabel('EMAIL')),
              const SizedBox(width: 48),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Center(child: _emailColumnLabel('PRIMARY')),
            ),
            Expanded(flex: 3, child: _emailColumnLabel('EMAIL')),
            const SizedBox(width: 10),
            Expanded(child: _emailColumnLabel('LABEL')),
            const SizedBox(width: 48),
          ],
        ),
      );
    },
  );

  Widget _emailColumnLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: mutedInk,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );

  Widget _labeledField(String label, TextEditingController controller) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label),
          TextFormField(
            controller: controller,
            decoration: const InputDecoration(),
          ),
        ],
      );

  Widget _fieldLabel(String text, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: const TextStyle(
              color: mutedInk,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    ),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  bool get _hasEnteredEmail =>
      _emails.any((email) => email.address.text.trim().isNotEmpty);

  void _addEmail() => setState(() {
    final email = _newEmail();
    _emails.add(email);
    _primaryEmailId ??= email.id;
  });
  void _removeEmail(_EmailEditor email) => setState(() {
    final wasPrimary = email.id == _primaryEmailId;
    _emails.remove(email);
    email.dispose();
    if (wasPrimary) _primaryEmailId = _emails.firstOrNull?.id;
    if (_emails.isEmpty) _canReceiveCampaignEmails = false;
  });

  void _addSegment(String value) {
    final segment = value.trim();
    if (segment.isEmpty ||
        _segments.any((item) => item.toLowerCase() == segment.toLowerCase())) {
      return;
    }
    setState(() {
      _segments.add(segment);
      _segment.clear();
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final enteredEmails = _emails
        .where((email) => email.address.text.trim().isNotEmpty)
        .toList();
    final primaryEmailId =
        enteredEmails.any((email) => email.id == _primaryEmailId)
        ? _primaryEmailId
        : enteredEmails.firstOrNull?.id;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.saveContact(
        ContactFormValue(
          companyId: _companyId,
          companyName: _company.text,
          fullName: _name.text,
          emails: enteredEmails
              .map(
                (email) => ContactEmailValue(
                  id: email.id,
                  address: email.address.text,
                  label: email.label.text,
                ),
              )
              .toList(),
          primaryEmailId: primaryEmailId,
          role: _role.text,
          linkedinUrl: _linkedin.text,
          sourceEventId: _sourceEventId,
          sourceNote: _sourceNote.text,
          segments: _segments,
          canReceiveCampaignEmails:
              primaryEmailId != null && _canReceiveCampaignEmails,
        ),
        existing: widget.contact,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on StateError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EmailEditor {
  _EmailEditor({
    required this.id,
    required String address,
    required String label,
  }) : address = TextEditingController(text: address),
       label = TextEditingController(text: label);
  final String id;
  final TextEditingController address;
  final TextEditingController label;
  void dispose() {
    address.dispose();
    label.dispose();
  }
}
