import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class CountryCode {
  final String name;
  final String flag;
  final String dialCode;
  const CountryCode(this.name, this.flag, this.dialCode);
}

const kCountryCodes = [
  CountryCode('Afghanistan', '🇦🇫', '+93'),
  CountryCode('Albania', '🇦🇱', '+355'),
  CountryCode('Algeria', '🇩🇿', '+213'),
  CountryCode('Andorra', '🇦🇩', '+376'),
  CountryCode('Angola', '🇦🇴', '+244'),
  CountryCode('Antigua and Barbuda', '🇦🇬', '+1'),
  CountryCode('Argentina', '🇦🇷', '+54'),
  CountryCode('Armenia', '🇦🇲', '+374'),
  CountryCode('Australia', '🇦🇺', '+61'),
  CountryCode('Austria', '🇦🇹', '+43'),
  CountryCode('Azerbaijan', '🇦🇿', '+994'),
  CountryCode('Bahamas', '🇧🇸', '+1'),
  CountryCode('Bahrain', '🇧🇭', '+973'),
  CountryCode('Bangladesh', '🇧🇩', '+880'),
  CountryCode('Barbados', '🇧🇧', '+1'),
  CountryCode('Belarus', '🇧🇾', '+375'),
  CountryCode('Belgium', '🇧🇪', '+32'),
  CountryCode('Belize', '🇧🇿', '+501'),
  CountryCode('Benin', '🇧🇯', '+229'),
  CountryCode('Bhutan', '🇧🇹', '+975'),
  CountryCode('Bolivia', '🇧🇴', '+591'),
  CountryCode('Bosnia and Herzegovina', '🇧🇦', '+387'),
  CountryCode('Botswana', '🇧🇼', '+267'),
  CountryCode('Brazil', '🇧🇷', '+55'),
  CountryCode('Brunei', '🇧🇳', '+673'),
  CountryCode('Bulgaria', '🇧🇬', '+359'),
  CountryCode('Burkina Faso', '🇧🇫', '+226'),
  CountryCode('Burundi', '🇧🇮', '+257'),
  CountryCode('Cambodia', '🇰🇭', '+855'),
  CountryCode('Cameroon', '🇨🇲', '+237'),
  CountryCode('Canada', '🇨🇦', '+1'),
  CountryCode('Cape Verde', '🇨🇻', '+238'),
  CountryCode('Central African Republic', '🇨🇫', '+236'),
  CountryCode('Chad', '🇹🇩', '+235'),
  CountryCode('Chile', '🇨🇱', '+56'),
  CountryCode('China', '🇨🇳', '+86'),
  CountryCode('Colombia', '🇨🇴', '+57'),
  CountryCode('Comoros', '🇰🇲', '+269'),
  CountryCode('Congo', '🇨🇬', '+242'),
  CountryCode('Costa Rica', '🇨🇷', '+506'),
  CountryCode('Croatia', '🇭🇷', '+385'),
  CountryCode('Cuba', '🇨🇺', '+53'),
  CountryCode('Cyprus', '🇨🇾', '+357'),
  CountryCode('Czech Republic', '🇨🇿', '+420'),
  CountryCode('Denmark', '🇩🇰', '+45'),
  CountryCode('Djibouti', '🇩🇯', '+253'),
  CountryCode('Dominica', '🇩🇲', '+1'),
  CountryCode('Dominican Republic', '🇩🇴', '+1'),
  CountryCode('Ecuador', '🇪🇨', '+593'),
  CountryCode('Egypt', '🇪🇬', '+20'),
  CountryCode('El Salvador', '🇸🇻', '+503'),
  CountryCode('Estonia', '🇪🇪', '+372'),
  CountryCode('Eswatini', '🇸🇿', '+268'),
  CountryCode('Ethiopia', '🇪🇹', '+251'),
  CountryCode('Fiji', '🇫🇯', '+679'),
  CountryCode('Finland', '🇫🇮', '+358'),
  CountryCode('France', '🇫🇷', '+33'),
  CountryCode('Gabon', '🇬🇦', '+241'),
  CountryCode('Gambia', '🇬🇲', '+220'),
  CountryCode('Georgia', '🇬🇪', '+995'),
  CountryCode('Germany', '🇩🇪', '+49'),
  CountryCode('Ghana', '🇬🇭', '+233'),
  CountryCode('Greece', '🇬🇷', '+30'),
  CountryCode('Guatemala', '🇬🇹', '+502'),
  CountryCode('Guinea', '🇬🇳', '+224'),
  CountryCode('Guyana', '🇬🇾', '+592'),
  CountryCode('Haiti', '🇭🇹', '+509'),
  CountryCode('Honduras', '🇭🇳', '+504'),
  CountryCode('Hong Kong', '🇭🇰', '+852'),
  CountryCode('Hungary', '🇭🇺', '+36'),
  CountryCode('Iceland', '🇮🇸', '+354'),
  CountryCode('India', '🇮🇳', '+91'),
  CountryCode('Indonesia', '🇮🇩', '+62'),
  CountryCode('Iran', '🇮🇷', '+98'),
  CountryCode('Iraq', '🇮🇶', '+964'),
  CountryCode('Ireland', '🇮🇪', '+353'),
  CountryCode('Israel', '🇮🇱', '+972'),
  CountryCode('Italy', '🇮🇹', '+39'),
  CountryCode('Jamaica', '🇯🇲', '+1'),
  CountryCode('Japan', '🇯🇵', '+81'),
  CountryCode('Jordan', '🇯🇴', '+962'),
  CountryCode('Kazakhstan', '🇰🇿', '+7'),
  CountryCode('Kenya', '🇰🇪', '+254'),
  CountryCode('Kuwait', '🇰🇼', '+965'),
  CountryCode('Kyrgyzstan', '🇰🇬', '+996'),
  CountryCode('Laos', '🇱🇦', '+856'),
  CountryCode('Latvia', '🇱🇻', '+371'),
  CountryCode('Lebanon', '🇱🇧', '+961'),
  CountryCode('Lesotho', '🇱🇸', '+266'),
  CountryCode('Liberia', '🇱🇷', '+231'),
  CountryCode('Libya', '🇱🇾', '+218'),
  CountryCode('Lithuania', '🇱🇹', '+370'),
  CountryCode('Luxembourg', '🇱🇺', '+352'),
  CountryCode('Macau', '🇲🇴', '+853'),
  CountryCode('Madagascar', '🇲🇬', '+261'),
  CountryCode('Malaysia', '🇲🇾', '+60'),
  CountryCode('Maldives', '🇲🇻', '+960'),
  CountryCode('Mali', '🇲🇱', '+223'),
  CountryCode('Malta', '🇲🇹', '+356'),
  CountryCode('Mauritania', '🇲🇷', '+222'),
  CountryCode('Mauritius', '🇲🇺', '+230'),
  CountryCode('Mexico', '🇲🇽', '+52'),
  CountryCode('Moldova', '🇲🇩', '+373'),
  CountryCode('Monaco', '🇲🇨', '+377'),
  CountryCode('Mongolia', '🇲🇳', '+976'),
  CountryCode('Montenegro', '🇲🇪', '+382'),
  CountryCode('Morocco', '🇲🇦', '+212'),
  CountryCode('Mozambique', '🇲🇿', '+258'),
  CountryCode('Myanmar', '🇲🇲', '+95'),
  CountryCode('Namibia', '🇳🇦', '+264'),
  CountryCode('Nepal', '🇳🇵', '+977'),
  CountryCode('Netherlands', '🇳🇱', '+31'),
  CountryCode('New Zealand', '🇳🇿', '+64'),
  CountryCode('Nicaragua', '🇳🇮', '+505'),
  CountryCode('Niger', '🇳🇪', '+227'),
  CountryCode('Nigeria', '🇳🇬', '+234'),
  CountryCode('North Korea', '🇰🇵', '+850'),
  CountryCode('North Macedonia', '🇲🇰', '+389'),
  CountryCode('Norway', '🇳🇴', '+47'),
  CountryCode('Oman', '🇴🇲', '+968'),
  CountryCode('Pakistan', '🇵🇰', '+92'),
  CountryCode('Palestine', '🇵🇸', '+970'),
  CountryCode('Panama', '🇵🇦', '+507'),
  CountryCode('Papua New Guinea', '🇵🇬', '+675'),
  CountryCode('Paraguay', '🇵🇾', '+595'),
  CountryCode('Peru', '🇵🇪', '+51'),
  CountryCode('Philippines', '🇵🇭', '+63'),
  CountryCode('Poland', '🇵🇱', '+48'),
  CountryCode('Portugal', '🇵🇹', '+351'),
  CountryCode('Qatar', '🇶🇦', '+974'),
  CountryCode('Romania', '🇷🇴', '+40'),
  CountryCode('Russia', '🇷🇺', '+7'),
  CountryCode('Rwanda', '🇷🇼', '+250'),
  CountryCode('Saudi Arabia', '🇸🇦', '+966'),
  CountryCode('Senegal', '🇸🇳', '+221'),
  CountryCode('Serbia', '🇷🇸', '+381'),
  CountryCode('Seychelles', '🇸🇨', '+248'),
  CountryCode('Sierra Leone', '🇸🇱', '+232'),
  CountryCode('Singapore', '🇸🇬', '+65'),
  CountryCode('Slovakia', '🇸🇰', '+421'),
  CountryCode('Slovenia', '🇸🇮', '+386'),
  CountryCode('Somalia', '🇸🇴', '+252'),
  CountryCode('South Africa', '🇿🇦', '+27'),
  CountryCode('South Korea', '🇰🇷', '+82'),
  CountryCode('Spain', '🇪🇸', '+34'),
  CountryCode('Sri Lanka', '🇱🇰', '+94'),
  CountryCode('Sudan', '🇸🇩', '+249'),
  CountryCode('Sweden', '🇸🇪', '+46'),
  CountryCode('Switzerland', '🇨🇭', '+41'),
  CountryCode('Syria', '🇸🇾', '+963'),
  CountryCode('Taiwan', '🇹🇼', '+886'),
  CountryCode('Tajikistan', '🇹🇯', '+992'),
  CountryCode('Tanzania', '🇹🇿', '+255'),
  CountryCode('Thailand', '🇹🇭', '+66'),
  CountryCode('Tunisia', '🇹🇳', '+216'),
  CountryCode('Turkey', '🇹🇷', '+90'),
  CountryCode('Uganda', '🇺🇬', '+256'),
  CountryCode('Ukraine', '🇺🇦', '+380'),
  CountryCode('United Arab Emirates', '🇦🇪', '+971'),
  CountryCode('United Kingdom', '🇬🇧', '+44'),
  CountryCode('United States', '🇺🇸', '+1'),
  CountryCode('Uruguay', '🇺🇾', '+598'),
  CountryCode('Uzbekistan', '🇺🇿', '+998'),
  CountryCode('Venezuela', '🇻🇪', '+58'),
  CountryCode('Vietnam', '🇻🇳', '+84'),
  CountryCode('Yemen', '🇾🇪', '+967'),
  CountryCode('Zambia', '🇿🇲', '+260'),
  CountryCode('Zimbabwe', '🇿🇼', '+263'),
];

/// Splits a stored phone string (e.g. "+91 9876543210") into (dialCode, number).
/// Returns ('+91', original) if no match found.
(String, String) parseStoredPhone(String phone) {
  // Sort by dial code length descending to avoid "+1" matching before "+971"
  final sorted = [...kCountryCodes]
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
  for (final c in sorted) {
    if (phone.startsWith(c.dialCode)) {
      return (c.dialCode, phone.substring(c.dialCode.length).trim());
    }
  }
  return ('+91', phone);
}

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String selectedDialCode;
  final ValueChanged<String> onDialCodeChanged;
  final String? Function(String?)? validator;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.selectedDialCode,
    required this.onDialCodeChanged,
    this.validator,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _focused = _focusNode.hasFocus),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  CountryCode get _selected => kCountryCodes.firstWhere(
    (c) => c.dialCode == widget.selectedDialCode,
    orElse: () => kCountryCodes.first,
  );

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      isFocused: _focused,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        filled: true,
        fillColor: DrColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DrColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DrColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: DrColors.primary, width: 1.5),
        ),
      ),
      isEmpty: widget.controller.text.isEmpty && !_focused,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SearchableDialCodePicker(
            selected: _selected,
            onChanged: widget.onDialCodeChanged,
          ),
          Container(width: 1, height: 24, color: DrColors.border),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                validator: widget.validator,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: DrColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Phone number',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: DrColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A searchable country code picker that opens a styled overlay with a search field.
class _SearchableDialCodePicker extends StatefulWidget {
  final CountryCode selected;
  final ValueChanged<String> onChanged;

  const _SearchableDialCodePicker({
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_SearchableDialCodePicker> createState() =>
      _SearchableDialCodePickerState();
}

class _SearchableDialCodePickerState extends State<_SearchableDialCodePicker> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  void _openDropdown() {
    if (_isOpen) {
      _closeDropdown();
      return;
    }
    _isOpen = true;

    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlay = OverlayEntry(
      builder: (_) => _CountryDropdownOverlay(
        link: _layerLink,
        triggerSize: size,
        selected: widget.selected,
        onSelected: (code) {
          widget.onChanged(code.dialCode);
          _closeDropdown();
        },
        onClose: _closeDropdown,
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _closeDropdown() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _closeDropdown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _openDropdown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.selected.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 5),
              Text(
                widget.selected.dialCode,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DrColors.textPrimary,
                ),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: DrColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryDropdownOverlay extends StatefulWidget {
  final LayerLink link;
  final Size triggerSize;
  final CountryCode selected;
  final ValueChanged<CountryCode> onSelected;
  final VoidCallback onClose;

  const _CountryDropdownOverlay({
    required this.link,
    required this.triggerSize,
    required this.selected,
    required this.onSelected,
    required this.onClose,
  });

  @override
  State<_CountryDropdownOverlay> createState() =>
      _CountryDropdownOverlayState();
}

class _CountryDropdownOverlayState extends State<_CountryDropdownOverlay> {
  final _searchCtrl = TextEditingController();
  List<CountryCode> _filtered = kCountryCodes;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.toLowerCase().trim();
      setState(() {
        _filtered = q.isEmpty
            ? kCountryCodes
            : kCountryCodes
                  .where(
                    (c) =>
                        c.name.toLowerCase().contains(q) ||
                        c.dialCode.contains(q),
                  )
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Barrier to close on outside tap
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onClose,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          showWhenUnlinked: false,
          offset: Offset(0, widget.triggerSize.height + 4),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 240,
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: DrColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: DrColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search field
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: DrColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search country...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: DrColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: DrColors.textSecondary,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: DrColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: DrColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: DrColors.primary,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: DrColors.background,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Country list
                  Flexible(
                    child: _filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No results found',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: DrColors.textTertiary,
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final c = _filtered[i];
                              final isSelected =
                                  c.dialCode == widget.selected.dialCode &&
                                  c.name == widget.selected.name;
                              return InkWell(
                                onTap: () => widget.onSelected(c),
                                child: Container(
                                  color: isSelected
                                      ? DrColors.primaryLight
                                      : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        c.flag,
                                        style: const TextStyle(fontSize: 17),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          c.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: DrColors.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        c.dialCode,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: DrColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
