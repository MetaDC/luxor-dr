import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../controllers/auth_ctrl.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/app_text_field.dart';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),
              // Logo
              Image.asset(
                'assets/luxor_logo.png',
                height: 52,
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 48),
              GetBuilder<AuthCtrl>(
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
            ],
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
          Text(
            'Welcome back',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: DrColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to your doctor account',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DrColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email Address',
            hint: 'doctor@example.com',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!v.contains('@')) return 'Enter a valid email.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (errorMsg != null) ...[
            _ErrorBox(message: errorMsg!),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSend,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text('Send OTP'),
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
        GestureDetector(
          onTap: onBack,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DrColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DrColors.border),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                size: 20, color: DrColors.textPrimary),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Check your email',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: DrColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                fontSize: 14, color: DrColors.textSecondary),
            children: [
              const TextSpan(text: 'We sent a 6-digit OTP to '),
              TextSpan(
                text: email,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: DrColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AppTextField(
          label: 'One-Time Password',
          hint: '123456',
          controller: otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 16),
        if (errorMsg != null) ...[
          _ErrorBox(message: errorMsg!),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isLoading ? null : onVerify,
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Verify & Sign In'),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onResend,
            child: Text(
              'Resend OTP',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: DrColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DrColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DrColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: DrColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: DrColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
