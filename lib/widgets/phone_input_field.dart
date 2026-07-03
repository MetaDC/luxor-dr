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

int getMaxDigitsForDialCode(String dialCode) {
  switch (dialCode) {
    case '+91': return 10; // India
    case '+1': return 10;  // US / Canada
    case '+44': return 10; // UK
    case '+92': return 10; // Pakistan
    case '+880': return 10; // Bangladesh
    case '+86': return 11; // China
    case '+81': return 10; // Japan
    case '+7': return 10;  // Russia
    case '+61': return 9;  // Australia
    case '+971': return 9; // UAE
    case '+966': return 9; // Saudi Arabia
    case '+65': return 8;  // Singapore
    case '+33': return 9;  // France
    case '+49': return 10; // Germany
    case '+39': return 10; // Italy
    case '+34': return 9;  // Spain
    case '+60': return 10; // Malaysia
    case '+90': return 10; // Turkey
    case '+62': return 10; // Indonesia
    case '+965': return 8;  // Kuwait
    case '+974': return 8;  // Qatar
    case '+968': return 8;  // Oman
    case '+973': return 8;  // Bahrain
    default: return 10; // Default to 10
  }
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  @override
  Widget build(BuildContext context) {
    final selected = kCountryCodes.firstWhere(
      (c) => c.dialCode == widget.selectedDialCode,
      orElse: () => kCountryCodes.first,
    );
    final maxDigits = getMaxDigitsForDialCode(widget.selectedDialCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Separate Country Dropdown Form Field
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => _SearchCountryDialog(
                selected: selected,
                onSelected: (code) {
                  widget.onDialCodeChanged(code.dialCode);
                  widget.controller.clear(); // Clear text to prevent mismatching lengths
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: IgnorePointer(
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Country Selection *',
                suffixIcon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 24,
                  color: DrColors.textSecondary,
                ),
                filled: true,
                fillColor: DrColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: DrColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: DrColors.border),
                ),
              ),
              child: Text(
                '${selected.flag} ${selected.name} (${selected.dialCode})',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: DrColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // 2. Separate Phone Input Field
        TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(maxDigits),
          ],
          style: GoogleFonts.inter(
            fontSize: 15,
            color: DrColors.textPrimary,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Required';
            }
            final cleanVal = val.trim();
            if (cleanVal.length != maxDigits) {
              return 'Must be exactly $maxDigits digits';
            }
            if (widget.validator != null) {
              return widget.validator!(val);
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Phone Number *',
            hintText: 'Enter $maxDigits digits',
            prefixText: '${widget.selectedDialCode} ',
            prefixStyle: GoogleFonts.inter(
              fontSize: 15,
              color: DrColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: DrColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        ),
      ],
    );
  }
}

class _SearchCountryDialog extends StatefulWidget {
  final CountryCode selected;
  final ValueChanged<CountryCode> onSelected;

  const _SearchCountryDialog({
    required this.selected,
    required this.onSelected,
  });

  @override
  State<_SearchCountryDialog> createState() => _SearchCountryDialogState();
}

class _SearchCountryDialogState extends State<_SearchCountryDialog> {
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
                .where((c) =>
                    c.name.toLowerCase().contains(q) ||
                    c.dialCode.contains(q))
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Country',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DrColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DrColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Search country or code...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  color: DrColors.textTertiary,
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SizedBox(
                width: double.maxFinite,
                height: 300,
                child: ListView.separated(
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = _filtered[i];
                    final isSel = item.dialCode == widget.selected.dialCode;
                    return ListTile(
                      leading: Text(item.flag, style: const TextStyle(fontSize: 22)),
                      title: Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.w500,
                          color: isSel ? DrColors.primary : DrColors.textPrimary,
                        ),
                      ),
                      trailing: Text(
                        item.dialCode,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isSel ? DrColors.primary : DrColors.textSecondary,
                          fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        widget.onSelected(item);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
