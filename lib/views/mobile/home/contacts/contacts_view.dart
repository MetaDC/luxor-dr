import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../controllers/auth_ctrl.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/meeting_per_model.dart';
import '../../../../models/patient_model.dart';
import '../../../../utils/app_theme.dart';
import 'contact_detail_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared contact data class (used by detail view too)
// ─────────────────────────────────────────────────────────────────────────────

class ContactEntry {
  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isPatient;

  const ContactEntry({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isPatient,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get typeColor => isPatient ? DrColors.primary : DrColors.accent;
  String get typeLabel => isPatient ? 'Patient' : 'Contact';
}

// ─────────────────────────────────────────────────────────────────────────────
// ContactsView
// ─────────────────────────────────────────────────────────────────────────────

enum _ContactTab { all, patients, contacts }

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  _ContactTab _tab = _ContactTab.all;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ContactEntry> _build(
    List<PatientModel> patients,
    List<MeetingPersonModel> meetingPersons,
  ) => [
    ...patients.map(
      (p) => ContactEntry(
        id: p.docId,
        name: p.name,
        email: p.email,
        phone: p.phone,
        isPatient: true,
      ),
    ),
    ...meetingPersons.map(
      (m) => ContactEntry(
        id: m.docId,
        name: m.name,
        email: m.email,
        phone: m.phone,
        isPatient: false,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DrColors.background,
      body: SafeArea(
        child: GetBuilder<HomeCtrl>(
          builder: (ctrl) {
            final doctorId = AuthCtrl.to.currentDoctor?.docId ?? '';

            final patients = ctrl.patients
                .where((p) => p.doctorId == doctorId)
                .toList();
            final meetingPersons = ctrl.meetingPersons
                .where((m) => m.doctorId == doctorId)
                .toList();

            final all = _build(patients, meetingPersons);

            final visible = all.where((c) {
              final matchTab =
                  _tab == _ContactTab.all ||
                  (_tab == _ContactTab.patients && c.isPatient) ||
                  (_tab == _ContactTab.contacts && !c.isPatient);
              final matchSearch =
                  _query.isEmpty ||
                  c.name.toLowerCase().contains(_query) ||
                  c.email.toLowerCase().contains(_query) ||
                  c.phone.contains(_query);
              return matchTab && matchSearch;
            }).toList()..sort((a, b) => a.name.compareTo(b.name));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: DrColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: DrColors.border),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 16,
                                color: DrColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contacts',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: DrColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${patients.length} patients · ${meetingPersons.length} contacts',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: DrColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Search ──────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: DrColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: DrColors.border),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: DrColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by name, email or phone…',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: DrColors.textTertiary,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: DrColors.textTertiary,
                              size: 20,
                            ),
                            suffixIcon: _query.isNotEmpty
                                ? GestureDetector(
                                    onTap: _searchCtrl.clear,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: DrColors.textTertiary,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Type tabs ───────────────────────────────────
                      Row(
                        children: [
                          _TypeTab(
                            label: 'All',
                            count: all.length,
                            active: _tab == _ContactTab.all,
                            onTap: () => setState(() => _tab = _ContactTab.all),
                          ),
                          const SizedBox(width: 8),
                          _TypeTab(
                            label: 'Patients',
                            count: patients.length,
                            active: _tab == _ContactTab.patients,
                            color: DrColors.primary,
                            onTap: () =>
                                setState(() => _tab = _ContactTab.patients),
                          ),
                          const SizedBox(width: 8),
                          _TypeTab(
                            label: 'Contacts',
                            count: meetingPersons.length,
                            active: _tab == _ContactTab.contacts,
                            color: DrColors.accent,
                            onTap: () =>
                                setState(() => _tab = _ContactTab.contacts),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── List ────────────────────────────────────────────
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyState(hasSearch: _query.isNotEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _ContactCard(
                            contact: visible[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ContactDetailView(contact: visible[i]),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TypeTab extends StatelessWidget {
  final String label;
  final int count;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
    this.color = DrColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final c = active ? color : DrColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.10) : DrColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : DrColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: active ? color.withValues(alpha: 0.15) : DrColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active ? color : DrColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final ContactEntry contact;
  final VoidCallback onTap;
  const _ContactCard({required this.contact, required this.onTap});

  Future<void> _call() async {
    if (contact.phone.isEmpty) return;

    launchUrlString("tel://91${contact.phone}");
    // final uri = Uri(scheme: 'tel', path: contact.phone);
    // if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DrColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Main row
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: contact.typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Center(
                        child: Text(
                          contact.initials,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: contact.typeColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: DrColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: contact.typeColor.withValues(
                                    alpha: 0.10,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  contact.typeLabel,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: contact.typeColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (contact.email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              contact.email,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: DrColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (contact.phone.isNotEmpty)
                            Text(
                              contact.phone,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: DrColors.textTertiary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: DrColors.textTertiary.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),

            // Action row
            if (contact.phone.isNotEmpty) ...[
              Divider(height: 1, color: DrColors.border),
              InkWell(
                onTap: _call,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 14,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: DrColors.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          size: 13,
                          color: DrColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Call ${contact.phone}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DrColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: DrColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 32,
              color: DrColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch ? 'No results found' : 'No contacts yet',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: DrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasSearch
                ? 'Try a different name, email or phone'
                : 'Patients and meeting contacts will appear here',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: DrColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
