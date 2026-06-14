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

class _AuthGateScreenState extends State<AuthGateScreen> {
  late String _mode;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
        await widget.controller.signUpWithEmail(
          name: name,
          email: email,
          password: password,
        );
      } else {
        await widget.controller.signInWithEmail(
          email: email,
          password: password,
        );
      }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = widget.controller.isBusy;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
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
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _Pill(label: 'Guest'),
                      _Pill(label: 'Email'),
                      _Pill(label: 'Google'),
                      _Pill(label: 'Live Tests'),
                      _Pill(label: 'Notebook'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SoftCard(
              color: AppColors.coralSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.upgradeMode ? 'Upgrade Account' : 'Student App',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text)),
                  const SizedBox(height: 8),
                  Text(
                    widget.upgradeMode
                        ? 'Guest daily data aur local progress ko account ke saath continue karne ke liye sign in karo.'
                        : 'Phone app students ke liye hai. Daily test, published practice aur mistake notebook yahin se smoothly chalenge.',
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!widget.upgradeMode) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : _enterGuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueSoft,
                    foregroundColor: AppColors.text,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(busy ? 'Please wait...' : 'Continue as Guest'),
                ),
              ),
              const SizedBox(height: 12),
            ],
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
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _mode == 'email_signup' ? 'Create Account' : 'Email Sign-In',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (_mode == 'email_signup') ...[
                    TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline))),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined))),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: busy
                          ? null
                          : () => _signInEmail(
                              createAccount: _mode == 'email_signup'),
                      child: Text(busy
                          ? 'Please wait...'
                          : _mode == 'email_signup'
                              ? 'Create Account'
                              : 'Sign In'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _mode = _mode == 'email_signup'
                              ? 'email_login'
                              : 'email_signup';
                        });
                      },
                      child: Text(_mode == 'email_signup'
                          ? 'Already have an account? Sign In'
                          : 'New here? Create an Account'),
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
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        label,
        style:
            const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
      ),
    );
  }
}
