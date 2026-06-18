import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/soft_card.dart';

class AuthGateScreen extends StatefulWidget {
  const AuthGateScreen({
    super.key,
    required this.controller,
    this.initialMode = 'guest',
    this.upgradeMode = false,
  });

  final AppController controller;
  final String initialMode;
  final bool upgradeMode;

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

enum AuthView { selection, login, signup, forgot, verify }

class _AuthGateScreenState extends State<AuthGateScreen> {
  AuthView _view = AuthView.selection;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // Default to selection if not upgrade mode
    _view = widget.upgradeMode ? AuthView.login : AuthView.selection;
  }

  final _otpController = TextEditingController();
  String _pendingEmail = '';
  String _pendingPassword = '';
  String _pendingName = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _enterGuest() async {
    await widget.controller.continueAsGuest();
  }

  Future<void> _signInEmail({required bool createAccount}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (createAccount && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sabhi fields bharna zaruri hai.')),
      );
      return;
    }

    try {
      if (createAccount) {
        // Step 1: Send OTP to Firestore
        await widget.controller.sendOtpToEmail(email);
        
        // Step 2: Show OTP entry screen
        if (!mounted) return;
        setState(() {
          _pendingEmail = email;
          _pendingPassword = password;
          _pendingName = name;
          _view = AuthView.verify;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code Firestore mein save kar diya gaya hai. Console check karein.')),
        );
      } else {
        await widget.controller.signInWithEmail(
          email: email,
          password: password,
        );
      }
    } catch (exc) {
      if (!mounted) return;
      final msg = exc.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _completeSignupWithCode() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please 6-digit ka code dalo.')),
      );
      return;
    }

    try {
      final isValid = await widget.controller.verifyOtp(_pendingEmail, code);
      if (!isValid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Galti code! Phir se try karo.')),
        );
        return;
      }

      // If code is valid, proceed with actual Firebase signup
      await widget.controller.signUpWithEmail(
        name: _pendingName,
        email: _pendingEmail,
        password: _pendingPassword,
      );
      
      // Verification link logic is still there as a second layer, but we can bypass or ignore for now
    } catch (exc) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exc.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _completeSignup() async {
    final code = _otpController.text.trim();
    if (code != '123456') { // Standard placeholder for demo or real OTP logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Galti code! Sahi verification code dalo.')),
      );
      return;
    }

    try {
      await widget.controller.signUpWithEmail(
        name: _pendingName,
        email: _pendingEmail,
        password: _pendingPassword,
      );
    } catch (exc) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exc.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _signInGoogle() async {
    try {
      await widget.controller.signInWithGoogle();
    } catch (exc) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exc.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle apna email ID likho.')),
      );
      return;
    }

    try {
      await widget.controller.sendPasswordResetEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset link aapke email par bhej di gayi hai.')),
      );
    } catch (exc) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exc.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = widget.controller.isBusy;

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentView(context, theme, busy),
        ),
      ),
    );
  }

  Widget _buildCurrentView(BuildContext context, ThemeData theme, bool busy) {
    switch (_view) {
      case AuthView.selection:
        return _buildSelectionView(context, theme, busy);
      case AuthView.login:
        return _buildLoginView(context, theme, busy);
      case AuthView.signup:
        return _buildSignupView(context, theme, busy);
      case AuthView.forgot:
        return _buildForgotView(context, theme, busy);
      case AuthView.verify:
        return _buildVerifyView(context, theme, busy);
    }
  }

  Widget _buildSelectionView(BuildContext context, ThemeData theme, bool busy) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildHero(theme),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy ? null : () => setState(() => _view = AuthView.login),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blueSoft,
              foregroundColor: AppColors.text,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Login with Email'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: busy ? null : () => setState(() => _view = AuthView.signup),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenSoft,
              foregroundColor: AppColors.text,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Create New Account'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.g_mobiledata, size: 30),
            onPressed: busy ? null : _signInGoogle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.text,
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.line),
            ),
            label: Text(busy ? 'Please wait...' : 'Sign in with Google'),
          ),
        ),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: busy ? null : _enterGuest,
            child: const Text('Continue as Guest (No login needed)',
                style: TextStyle(color: AppColors.muted)),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginView(BuildContext context, ThemeData theme, bool busy) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildHero(theme),
        const SizedBox(height: 24),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _view = AuthView.selection),
                  ),
                  Text('Email Sign-In', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    )),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _view = AuthView.forgot),
                  child: const Text('Forgot Password?', 
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : () => _signInEmail(createAccount: false),
                  child: Text(busy ? 'Please wait...' : 'Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _view = AuthView.signup),
                  child: const Text('New here? Create an Account'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignupView(BuildContext context, ThemeData theme, bool busy) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildHero(theme),
        const SizedBox(height: 24),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _view = AuthView.selection),
                  ),
                  Text('Create Account', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 12),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    )),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : () => _signInEmail(createAccount: true),
                  child: Text(busy ? 'Please wait...' : 'Sign Up'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _view = AuthView.login),
                  child: const Text('Already have an account? Sign In'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForgotView(BuildContext context, ThemeData theme, bool busy) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildHero(theme),
        const SizedBox(height: 24),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _view = AuthView.login),
                  ),
                  Text('Forgot Password', style: theme.textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Apna email ID dalo, hum aapko password reset karne ke liye ek verification link bhejenge.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : _handleForgotPassword,
                  child: Text(busy ? 'Sending...' : 'Send Reset Link'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyView(BuildContext context, ThemeData theme, bool busy) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _buildHero(theme),
        const SizedBox(height: 24),
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify Account', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text(
                  'Humne $_pendingEmail ke liye ek verification code generate kiya hai. Use yahan dalo.'),
              const SizedBox(height: 24),
              TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                      labelText: '6-Digit Code',
                      counterText: '',
                      prefixIcon: Icon(Icons.verified_user_outlined))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : _completeSignupWithCode,
                  child: const Text('Verify & Create Account'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: busy ? null : () => widget.controller.sendOtpToEmail(_pendingEmail),
                  child: const Text('Resend Code'),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _view = AuthView.selection),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.yellowSoft,
            AppColors.tealSoft,
            AppColors.blueSoft
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sudarshan', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 10),
          Text(
            widget.upgradeMode
                ? 'Guest se account par aao aur apna daily score, cloud record aur progress safely continue karo.'
                : 'Daily test, fast practice aur smart revision ko mobile rhythm ke saath chalane ke liye bana hua student app.',
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
