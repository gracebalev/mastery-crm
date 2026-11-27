import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/utils/csv_file_io.dart';
import '../domain/contact_repository.dart';
import '../domain/entities.dart';
import 'contact_controller.dart';
import 'contact_dialog.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key, required this.repository});
  final ContactRepository repository;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  late final ContactController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ContactController(widget.repository);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _Sidebar(),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: constraints.maxWidth < 1080
                        ? 1080
                        : constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: _content(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() => Padding(
    padding: const EdgeInsets.fromLTRB(40, 34, 40, 30),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contacts',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Manage the people who receive your Mastery campaigns',
                    style: TextStyle(color: mutedInk),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  showContactDialog(context: context, controller: _controller),
              child: const Text('Add contact'),
            ),
          ],
        ),
        const SizedBox(height: 26),
        _toolbar(),
        if (_controller.filtersVisible) ...[
          const SizedBox(height: 10),
          _filters(),
        ],
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              '${_controller.companies.length} companies · ${_controller.contacts.length} contacts',
              style: const TextStyle(color: mutedInk),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFEFE8FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Grouped by company',
                style: TextStyle(color: brandPurple, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: _controller.visibleGroups.isEmpty
              ? _emptyState()
              : ListView.separated(
                  itemCount: _controller.visibleGroups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _CompanyCard(
                    group: _controller.visibleGroups[index],
                    controller: _controller,
                    onAdd: (company) => showContactDialog(
                      context: context,
                      controller: _controller,
                      initialCompany: company,
                    ),
                    onEdit: (contact) => showContactDialog(
                      context: context,
                      controller: _controller,
                      contact: contact,
                    ),
                    onDelete: _confirmDelete,
                  ),
                ),
        ),
      ],
    ),
  );

  Widget _toolbar() => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: borderColor),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 330,
          child: TextField(
            onChanged: _controller.setGlobalSearch,
            decoration: const InputDecoration(
              hintText: 'Search companies or contacts',
              prefixIcon: Icon(Icons.search, size: 19),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Color(0xFFF7F6F9),
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: _controller.toggleFilters,
          icon: const Icon(Icons.tune, size: 17),
          label: const Text('Filters'),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _importCsv,
          icon: const Icon(Icons.upload_file, size: 18),
          label: const Text('Import CSV'),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: _exportCsv,
          icon: const Icon(Icons.download, size: 18),
          label: const Text('Export CSV'),
        ),
        const SizedBox(width: 12),
        Text(
          '${_controller.contacts.length} contacts',
          style: const TextStyle(color: mutedInk, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _filters() {
    const labels = [
      'Company',
      'Contact',
      'Role',
      'Event / Source',
      'LinkedIn',
      'Segment',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextField(
                    onChanged: (value) =>
                        _controller.setColumnFilter(label, value),
                    decoration: InputDecoration(
                      labelText: label,
                      hintText: '3+ characters',
                      isDense: true,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.people_outline, size: 52, color: mutedInk),
        const SizedBox(height: 14),
        Text(
          _controller.contacts.isEmpty
              ? 'Your contact list is empty'
              : 'No contacts match these filters',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 7),
        Text(
          _controller.contacts.isEmpty
              ? 'Import a CSV file or add the first contact.'
              : 'Try changing the search or column filters.',
          style: const TextStyle(color: mutedInk),
        ),
        if (_controller.contacts.isEmpty) ...[
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _importCsv,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import CSV'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => showContactDialog(
                  context: context,
                  controller: _controller,
                ),
                child: const Text('Add contact'),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Future<void> _importCsv() async {
    final source = await pickCsvFile();
    if (!mounted || source == null) return;
    final result = _controller.importCsv(source);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV import complete'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.imported} imported · ${result.skipped} skipped'),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Skipped rows',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Text(result.errors.join('\n')),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _exportCsv() {
    downloadCsvFile('mastery-contacts.csv', _controller.exportCsv());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('CSV export downloaded.')));
  }

  Future<void> _confirmDelete(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete contact?'),
        content: Text(
          '${contact.fullName} will be removed. The company will remain in the directory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) _controller.deleteContact(contact);
  }
}

class _CompanyCard extends StatefulWidget {
  const _CompanyCard({
    required this.group,
    required this.controller,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });
  final CompanyContactGroup group;
  final ContactController controller;
  final ValueChanged<Company> onAdd;
  final ValueChanged<Contact> onEdit;
  final ValueChanged<Contact> onDelete;

  @override
  State<_CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<_CompanyCard> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) {
    final company = widget.group.company;
    final contacts = widget.group.contacts;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: mutedInk,
                  ),
                  const SizedBox(width: 10),
                  _CompanyAvatar(name: company.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if (company.domain != null)
                          Text(
                            company.domain!,
                            style: const TextStyle(
                              color: mutedInk,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 110,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3F8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${contacts.length} ${contacts.length == 1 ? 'contact' : 'contacts'}',
                      style: const TextStyle(fontSize: 12, color: mutedInk),
                    ),
                  ),
                  const SizedBox(width: 14),
                  OutlinedButton.icon(
                    onPressed: () => widget.onAdd(company),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add contact'),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            const _ContactHeader(),
            if (contacts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No contacts in this company.',
                  style: TextStyle(color: mutedInk),
                ),
              )
            else
              ...contacts.map(
                (contact) => _ContactRow(
                  contact: contact,
                  onEdit: widget.onEdit,
                  onDelete: widget.onDelete,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ContactHeader extends StatelessWidget {
  const _ContactHeader();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF7F6F9),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    child: const Row(
      children: [
        Expanded(flex: 3, child: Text('CONTACT', style: _headerStyle)),
        Expanded(flex: 2, child: Text('ROLE', style: _headerStyle)),
        Expanded(flex: 3, child: Text('EVENT / SOURCE', style: _headerStyle)),
        Expanded(flex: 3, child: Text('LINKEDIN', style: _headerStyle)),
        Expanded(flex: 2, child: Text('SEGMENT', style: _headerStyle)),
        SizedBox(width: 42),
      ],
    ),
  );
  static const _headerStyle = TextStyle(
    fontSize: 10,
    color: Color(0xFF948E9E),
    fontWeight: FontWeight.w600,
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });
  final Contact contact;
  final ValueChanged<Contact> onEdit;
  final ValueChanged<Contact> onDelete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    decoration: const BoxDecoration(
      border: Border(top: BorderSide(color: borderColor)),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFFEFE8FF),
                child: Text(
                  _initials(contact.fullName),
                  style: const TextStyle(
                    color: brandPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      contact.primaryEmail.address,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: mutedInk, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(contact.role ?? '—', overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 3,
          child: Text(contact.source ?? '—', overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          flex: 3,
          child: Text(
            contact.linkedinUrl ?? '—',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: contact.linkedinUrl == null ? mutedInk : brandPurple,
              decoration: contact.linkedinUrl == null
                  ? null
                  : TextDecoration.underline,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: contact.segments.isEmpty
              ? const Text('—', style: TextStyle(color: mutedInk))
              : Tooltip(
                  message: contact.segments.join(', '),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFE8FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      contact.segments.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: brandPurple, fontSize: 12),
                    ),
                  ),
                ),
        ),
        SizedBox(
          width: 42,
          child: PopupMenuButton<String>(
            tooltip: 'Contact actions',
            onSelected: (value) =>
                value == 'edit' ? onEdit(contact) : onDelete(contact),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ],
    ),
  );

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((item) => item.isNotEmpty)
      .take(2)
      .map((item) => item[0].toUpperCase())
      .join();
}

class _CompanyAvatar extends StatelessWidget {
  const _CompanyAvatar({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFF261950),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      name
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((word) => word.isEmpty ? '' : word[0].toUpperCase())
          .join(),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    ),
  );
}

class _Sidebar extends StatelessWidget {
  const _Sidebar();
  @override
  Widget build(BuildContext context) => Container(
    width: 232,
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brandPurple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'M',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mastery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                Text(
                  'EMAIL STUDIO',
                  style: TextStyle(
                    fontSize: 9,
                    color: brandPurple,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 34),
        const Text(
          'WORKSPACE',
          style: TextStyle(
            color: mutedInk,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const _NavItem(icon: Icons.home_outlined, label: 'Overview'),
        const _NavItem(
          icon: Icons.radio_button_checked,
          label: 'Contacts',
          selected: true,
        ),
        const _NavItem(icon: Icons.calendar_today_outlined, label: 'Events'),
        const _NavItem(icon: Icons.diamond_outlined, label: 'Templates'),
        const _NavItem(icon: Icons.north_east, label: 'Campaigns'),
        const _NavItem(
          icon: Icons.auto_awesome_outlined,
          label: 'Brand settings',
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE8FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly sends',
                style: TextStyle(color: brandPurple, fontSize: 11),
              ),
              SizedBox(height: 8),
              Text('0 / 10,000', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0,
                minHeight: 5,
                borderRadius: BorderRadius.all(Radius.circular(5)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFFF3D6),
              child: Text('AM', style: TextStyle(fontSize: 11, color: ink)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mastery Admin',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'admin@mastery.pl',
                    style: TextStyle(fontSize: 10, color: mutedInk),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final bool selected;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
    decoration: BoxDecoration(
      color: selected ? const Color(0xFFF4EFFF) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, size: 17, color: selected ? brandPurple : mutedInk),
        const SizedBox(width: 11),
        Text(
          label,
          style: TextStyle(
            color: selected ? ink : mutedInk,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}
