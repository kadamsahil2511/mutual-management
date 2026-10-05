import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/input.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.next});
  final String? next;
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _register = false, _busy = false, _visible = false;
  String? _message;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit({bool reset = false}) async {
    if (_busy) return;
    if (reset
        ? emailError(_email.text) != null
        : !_form.currentState!.validate()) {
      if (reset) setState(() => _message = 'Enter your email address first.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final auth = ref.read(authRepositoryProvider);
      if (reset) {
        await auth.resetPassword(_email.text.trim());
        if (mounted) {
          setState(
            () => _message =
                'If an account exists, a password reset email is on its way.',
          );
        }
      } else {
        if (_register) {
          await auth.register(
            _email.text.trim(),
            _password.text,
            _name.text.trim(),
          );
        } else {
          await auth.signIn(_email.text.trim(), _password.text);
        }
        if (mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(safeNextPath(widget.next));
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _message = switch (e.code) {
            'invalid-credential' ||
            'wrong-password' ||
            'user-not-found' => 'The email or password is incorrect.',
            'email-already-in-use' =>
              'This email already has an account. Sign in instead.',
            'weak-password' =>
              'Choose a stronger password with at least 8 characters.',
            'too-many-requests' => 'Too many attempts. Please try again later.',
            'network-request-failed' =>
              'Unable to connect. Check your connection and try again.',
            _ => e.message ?? 'Unable to sign in. Please try again.',
          },
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Unable to connect. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: _register ? 'Your first step.' : 'Welcome back.',
    subtitle: 'Real account. Real data. A safe place to practice investing.',
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppCard(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _register ? 'Create your account' : 'Sign in',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Your name'),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (s) => (s?.trim().isEmpty ?? true)
                          ? 'Enter your name.'
                          : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: (s) => emailError(s ?? ''),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _password,
                    obscureText: !_visible,
                    autofillHints: [
                      _register
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip: _visible ? 'Hide password' : 'Show password',
                        onPressed: () => setState(() => _visible = !_visible),
                        icon: Icon(
                          _visible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => _submit(),
                    validator: (s) =>
                        s == null || s.length < (_register ? 8 : 1)
                        ? (_register
                              ? 'Use at least 8 characters.'
                              : 'Enter your password.')
                        : null,
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        _message!,
                        style: const TextStyle(color: AppColors.ink),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : () => _submit(),
                    child: Text(
                      _busy
                          ? 'Please wait…'
                          : (_register ? 'Create account' : 'Sign in'),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : () => context.push('/auth/reset'),
                    child: const Text('Forgot password?'),
                  ),
                  const Divider(),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _message = null;
                          }),
                    child: Text(
                      _register
                          ? 'Already registered? Sign in'
                          : 'New here? Create an account',
                    ),
                  ),
                  const Text(
                    'New accounts start empty. Every investment you record is a simulation; no money is moved.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});
  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false, _sent = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _email.text = ref.read(authStateProvider).value?.email ?? '';
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).resetPassword(_email.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not send the reset email. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: _sent ? 'Check your inbox' : 'Forgot your password?',
    subtitle: _sent
        ? 'If an account exists for this email, a reset link is on its way.'
        : 'Enter your account email. We’ll send a link to reset your password.',
    children: [
      AppCard(
        child: _sent
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.mark_email_read_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Check spam as well. Return to sign in after choosing your new password.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/auth');
                      }
                    },
                    child: const Text('Done'),
                  ),
                ],
              )
            : Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) => emailError(value ?? ''),
                      onFieldSubmitted: (_) => _send(),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      Text(_error!),
                      const SizedBox(height: 12),
                    ],
                    FilledButton(
                      onPressed: _busy ? null : _send,
                      child: Text(_busy ? 'Sending…' : 'Send reset link'),
                    ),
                  ],
                ),
              ),
      ),
    ],
  );
}
