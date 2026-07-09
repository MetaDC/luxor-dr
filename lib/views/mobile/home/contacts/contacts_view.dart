import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../../utils/firebase.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:luxor_dr/widgets/phone_input_field.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../controllers/home_ctrl.dart';
import '../../../../models/patient_model.dart';
import '../../../../utils/app_theme.dart';
import '../../../../utils/phone_helper.dart';
import '../../../../widgets/app_snackbar.dart';
import '../../../../widgets/app_text_field.dart';
import 'contact_detail_view.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared contact data class (used by detail view too)
// ─────────────────────────────────────────────────────────────────────────────

class ContactEntry {
  final String id;
  final String name;
  final String email;
  final String phone;

  const ContactEntry({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  String get initials {
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';
  }

  Color get typeColor => DrColors.primary;
  String get typeLabel => 'Contact';
}

// ─────────────────────────────────────────────────────────────────────────────
// ContactsView
// ─────────────────────────────────────────────────────────────────────────────

class ContactsView extends StatefulWidget {
  const ContactsView({super.key});

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
  _pageSubs = [];
  final List<List<PatientModel>> _pages = [];
  final List<DocumentSnapshot?> _pageBoundaryDocs = [];
  bool _loading = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadPage(0);
  }

  @override
  void dispose() {
    _cancelAllSubs();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final cleanVal = _searchCtrl.text.trim().toLowerCase();
    if (_query == cleanVal) return;
    setState(() {
      _query = cleanVal;
      _cancelAllSubs();
      _pages.clear();
      _pageBoundaryDocs.clear();
      _hasMore = true;
    });
    _loadPage(0);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore) {
        _loadPage(_pages.length);
      }
    }
  }

  void _loadPage(int pageIndex) {
    if (pageIndex < _pages.length) return;
    if (mounted) setState(() => _loading = true);

    Query<Map<String, dynamic>> query = FBFireStore.patients;
    if (_query.isEmpty) {
      query = query.orderBy('lowerName');
    } else {
      query = query
          .where('lowerName', isGreaterThanOrEqualTo: _query)
          .where('lowerName', isLessThanOrEqualTo: '$_query\uf8ff')
          .orderBy('lowerName');
    }

    if (pageIndex > 0 && _pageBoundaryDocs.length >= pageIndex) {
      final prevDoc = _pageBoundaryDocs[pageIndex - 1];
      if (prevDoc != null) {
        query = query.startAfterDocument(prevDoc);
      }
    }

    query = query.limit(_pageSize);

    final sub = query.snapshots().listen(
      (snapshot) {
        final items = snapshot.docs
            .map(PatientModel.fromQueryDocumentSnapshot)
            .toList();

        if (pageIndex < _pages.length) {
          _pages[pageIndex] = items;
        } else {
          _pages.add(items);
        }

        final boundaryDoc = snapshot.docs.isNotEmpty
            ? snapshot.docs.last
            : null;
        if (pageIndex < _pageBoundaryDocs.length) {
          _pageBoundaryDocs[pageIndex] = boundaryDoc;
        } else {
          _pageBoundaryDocs.add(boundaryDoc);
        }

        _hasMore = items.length == _pageSize;

        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() => _loading = false);
        }
      },
    );

    _pageSubs.add(sub);
  }

  void _cancelAllSubs() {
    for (final sub in _pageSubs) {
      sub.cancel();
    }
    _pageSubs.clear();
  }

  List<PatientModel> get _allLoadedPatients {
    final List<PatientModel> list = [];
    for (final pageItems in _pages) {
      list.addAll(pageItems);
    }
    return list;
  }

  List<ContactEntry> _build(List<PatientModel> patients) => patients
      .map(
        (p) => ContactEntry(
          id: p.docId,
          name: p.name,
          email: p.email,
          phone: p.phone,
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DrColors.background,
      appBar: AppBar(
        backgroundColor: DrColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'CONTACTS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const _CreateContactDialog(),
              );
            },
          ),
        ],
      ),
      body: GetBuilder<HomeCtrl>(
        builder: (ctrl) {
          final allPatients = _allLoadedPatients;
          final visible = _build(allPatients);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search ──────────────────────────────────────
                    SizedBox(
                      // decoration: BoxDecoration(
                      //   color: DrColors.surface,
                      //   borderRadius: BorderRadius.circular(12),
                      //   border: Border.all(
                      //     color: DrColors.border,
                      //     width: 0.5,
                      //   ),
                      // ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DrColors.border,
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DrColors.border,
                              width: 0.5,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DrColors.border,
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DrColors.border,
                              width: 0.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── List ────────────────────────────────────────────
              Expanded(
                child: visible.isEmpty && !_loading
                    ? _EmptyState(hasSearch: _query.isNotEmpty)
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 32),
                        itemCount: visible.length + (_hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          if (i == visible.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            );
                          }
                          return _ContactCard(
                            contact: visible[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ContactDetailView(contact: visible[i]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

// Type tabs removed as contacts are unified

class _ContactCard extends StatelessWidget {
  final ContactEntry contact;
  final VoidCallback onTap;
  const _ContactCard({required this.contact, required this.onTap});

  Future<void> _call() async {
    final phone = cleanPhoneNumber(contact.phone);
    if (phone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp() async {
    final cleaned = cleanPhoneNumber(contact.phone).replaceAll('+', '');
    if (cleaned.isEmpty) return;
    final urlString = 'https://wa.me/$cleaned';
    try {
      await launchUrlString(urlString, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Fallback or ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DrColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DrColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar (Modern Circle with soft accent color)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: contact.typeColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      contact.initials,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: contact.typeColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
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
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: DrColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (contact.phone.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 13,
                              color: DrColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              contact.phone,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: DrColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (contact.email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 13,
                              color: DrColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                contact.email,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: DrColors.textTertiary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Direct Call / WhatsApp or Chevron
                if (contact.phone.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _call();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: DrColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            size: 16,
                            color: DrColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _openWhatsApp();
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF25D366,
                            ).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/whatsapp.png',
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: DrColors.textTertiary.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
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
                : 'Contacts will appear here',
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

// ─────────────────────────────────────────────────────────────────────────────
// Create Contact Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _CreateContactDialog extends StatefulWidget {
  const _CreateContactDialog();

  @override
  State<_CreateContactDialog> createState() => _CreateContactDialogState();
}

class _CreateContactDialogState extends State<_CreateContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl;
  late String _dialCode;

  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _dialCode = '+91';
    _phoneCtrl = TextEditingController();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final fullPhone = '$_dialCode ${_phoneCtrl.text.trim()}';

    final p = await HomeCtrl.to.createPatient(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: fullPhone,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (p != null) {
      Navigator.pop(context);
      AppSnackbar.success(context, 'Contact created successfully.');
    } else {
      AppSnackbar.error(context, 'Failed to create contact.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Contact',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DrColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Full Name *',
                hint: 'Contact name',
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              PhoneInputField(
                controller: _phoneCtrl,
                selectedDialCode: _dialCode,
                onDialCodeChanged: (v) => setState(() => _dialCode = v),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final fullPhone = '$_dialCode ${v.trim()}';
                  if (!isValidPhoneNumber(fullPhone)) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Email',
                hint: 'contact@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null; // optional
                  if (!isValidEmail(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
