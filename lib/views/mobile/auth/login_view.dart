import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../controllers/auth_ctrl.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/app_text_field.dart';
import '../../../utils/phone_helper.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _auth = AuthCtrl.to;
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMsg = null);
    final err = await _auth.sendOtp(_emailCtrl.text.trim());
    if (err != null && mounted) setState(() => _errorMsg = err);
  }

  Future<void> _verifyOtp() async {
    if (_otpCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Please enter the OTP.');
      return;
    }
    setState(() => _errorMsg = null);
    final err = await _auth.verifyOtp(_otpCtrl.text.trim());
    if (err != null && mounted) {
      setState(() => _errorMsg = err);
    } else if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DrColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Header with visual hierarchy
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/luxor_logo.png',
                    height: 58,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                // Card wrapper for premium luxury feel
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  decoration: BoxDecoration(
                    color: DrColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: DrColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: GetBuilder<AuthCtrl>(
                    builder: (auth) {
                      if (auth.otpSent) {
                        return _OtpStep(
                          otpCtrl: _otpCtrl,
                          email: auth.enteredEmail,
                          isLoading: auth.isLoading,
                          errorMsg: _errorMsg,
                          onVerify: _verifyOtp,
                          onBack: () {
                            _auth.backToEmail();
                            _otpCtrl.clear();
                            setState(() => _errorMsg = null);
                          },
                          onResend: _auth.resendOtp,
                        );
                      }
                      return _EmailStep(
                        formKey: _formKey,
                        emailCtrl: _emailCtrl,
                        isLoading: auth.isLoading,
                        errorMsg: _errorMsg,
                        onSend: _sendOtp,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: DrColors.textSecondary,
                      ),
                      children: [
                        const TextSpan(text: 'Developed by '),
                        TextSpan(
                          text: 'Diwizon',
                          style: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600,
                            color: DrColors.primary,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => launchUrlString(
                              'https://diwizon.com',
                              mode: LaunchMode.externalApplication,
                            ),
                        ),
                      ],
                    ),
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

// ─── Email Step ───────────────────────────────────────────────────────────────

class _EmailStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onSend;

  const _EmailStep({
    required this.formKey,
    required this.emailCtrl,
    required this.isLoading,
    required this.errorMsg,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Welcome Back',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: DrColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to your doctor portal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: DrColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email Address',
            hint: 'doctor@luxor.com',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            // prefix: const Icon(
            //   Icons.email_outlined,
            //   color: DrColors.textSecondary,
            //   size: 20,
            // ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!isValidEmail(v.trim())) return 'Enter a valid email.';
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (errorMsg != null) ...[
            _ErrorBox(message: errorMsg!),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: DrColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Send Verification Code'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OTP Step ─────────────────────────────────────────────────────────────────

class _OtpStep extends StatelessWidget {
  final TextEditingController otpCtrl;
  final String email;
  final bool isLoading;
  final String? errorMsg;
  final VoidCallback onVerify;
  final VoidCallback onBack;
  final VoidCallback onResend;

  const _OtpStep({
    required this.otpCtrl,
    required this.email,
    required this.isLoading,
    required this.errorMsg,
    required this.onVerify,
    required this.onBack,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DrColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DrColors.border),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: DrColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Verify Email',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DrColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Verification Code',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: DrColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13,
              color: DrColors.textSecondary,
              height: 1.4,
            ),
            children: [
              const TextSpan(text: 'We have sent a 6-digit code to:\n'),
              TextSpan(
                text: email,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: DrColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // 6-digit custom OTP Input Box
        _OtpInputField(
          controller: otpCtrl,
          length: 6,
          onChanged: (val) {
            // Can be used to clear errors or update UI
          },
          onCompleted: (val) {
            onVerify();
          },
        ),
        const SizedBox(height: 24),
        if (errorMsg != null) ...[
          _ErrorBox(message: errorMsg!),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: DrColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Verify & Login'),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Didn't receive the code? ",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DrColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: onResend,
                child: Text(
                  'Resend Code',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: DrColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Custom 6-Box OTP Input Field ─────────────────────────────────────────────

class _OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const _OtpInputField({
    required this.controller,
    this.length = 6,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  State<_OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<_OtpInputField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hidden TextField spanning across entire container to capture inputs/focus
          Positioned.fill(
            child: Opacity(
              opacity: 0.0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                maxLength: widget.length,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (val) {
                  widget.onChanged(val);
                  if (val.length == widget.length) {
                    widget.onCompleted(val);
                  }
                },
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          // Visible Styled Boxes
          AnimatedBuilder(
            animation: Listenable.merge([widget.controller, _focusNode]),
            builder: (context, _) {
              final text = widget.controller.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (index) {
                  final isFocused = _focusNode.hasFocus && text.length == index;
                  final hasValue = index < text.length;
                  final value = hasValue ? text[index] : '';

                  return Container(
                    width: 44,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isFocused
                          ? Colors.white
                          : DrColors.background.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFocused
                            ? DrColors.primary
                            : hasValue
                            ? DrColors.primary.withValues(alpha: 0.4)
                            : DrColors.border,
                        width: isFocused ? 2 : 1.5,
                      ),
                      boxShadow: isFocused
                          ? [
                              BoxShadow(
                                color: DrColors.primary.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: isFocused
                        ? const _BlinkingCursor()
                        : Text(
                            value,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: DrColors.textPrimary,
                            ),
                          ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Blinking Cursor Widget for OTP Active Box ────────────────────────────────

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 22,
        decoration: BoxDecoration(
          color: DrColors.primary,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

// ─── Error Box Widget ─────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: DrColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DrColors.error.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: DrColors.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DrColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
