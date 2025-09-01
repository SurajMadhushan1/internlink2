import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internlink/ui/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final String role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleDisplayName {
    switch (widget.role) {
      case AppConstants.roleUser:
        return 'Student';
      case AppConstants.roleCompany:
        return 'Company';
      case AppConstants.roleAdmin:
        return 'Admin';
      default:
        return 'User';
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    // If already signed in, just navigate
    if (authProvider.isAuthenticated) {
      await authProvider.ensureProfileLoaded();
      final role = authProvider.user?.role ?? widget.role;
      if (role != widget.role) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please use the $role login to sign in.')),
          );
        }
        context.go('/login?role=$role');
        return;
      }
      switch (role) {
        case AppConstants.roleCompany:
          context.go('/company');
          break;
        case AppConstants.roleAdmin:
          context.go('/admin');
          break;
        case AppConstants.roleUser:
        default:
          context.go('/user');
      }
      return;
    }
    await authProvider.signInWithEmailPassword(
      _emailController.text.trim(),
      _passwordController.text,
      roleForCreation: widget.role,
    );

    if (authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else if (mounted) {
      await authProvider.ensureProfileLoaded();
      final role = authProvider.user?.role ?? widget.role;
      // Enforce that user signs in via the correct role-specific login
      if (role != widget.role) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please use the $role login to sign in.')),
        );
        await authProvider.signOut();
        context.go('/login?role=$role');
        return;
      }
      switch (role) {
        case AppConstants.roleCompany:
          context.go('/company');
          break;
        case AppConstants.roleAdmin:
          context.go('/admin');
          break;
        case AppConstants.roleUser:
        default:
          context.go('/user');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    // If already signed in, just navigate
    if (authProvider.isAuthenticated) {
      await authProvider.ensureProfileLoaded();
      final role = authProvider.user?.role ?? widget.role;
      if (role != widget.role) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please use the $role login to sign in.')),
          );
        }
        context.go('/login?role=$role');
        return;
      }
      switch (role) {
        case AppConstants.roleCompany:
          context.go('/company');
          break;
        case AppConstants.roleAdmin:
          context.go('/admin');
          break;
        case AppConstants.roleUser:
        default:
          context.go('/user');
      }
      return;
    }
    await authProvider.signInWithGoogle(widget.role);

    if (authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else if (mounted) {
      await authProvider.ensureProfileLoaded();
      final role = authProvider.user?.role ?? widget.role;
      if (role != widget.role) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please use the $role login to sign in.')),
        );
        await authProvider.signOut();
        context.go('/login?role=$role');
        return;
      }
      switch (role) {
        case AppConstants.roleCompany:
          context.go('/company');
          break;
        case AppConstants.roleAdmin:
          context.go('/admin');
          break;
        case AppConstants.roleUser:
        default:
          context.go('/user');
      }
    }
  }

  void _goToRegister() {
    context.go('/register?role=${widget.role}');
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) => _ForgotPasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign In as $_roleDisplayName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/auth-selector'),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),

                    // Welcome text
                    Text(
                      'Welcome back!',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Sign in to your $_roleDisplayName account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: Validators.password,
                    ),

                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign in button
                    ElevatedButton(
                      onPressed: _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Sign In'),
                    ),

                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.5),
                                ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google sign in
                    OutlinedButton.icon(
                      onPressed: _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Register link
                    Center(
                      child: TextButton(
                        onPressed: _goToRegister,
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                ),
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.resetPassword(_emailController.text.trim());

    if (mounted) {
      Navigator.of(context).pop();

      if (authProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Enter your email address and we\'ll send you a password reset link.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _resetPassword,
          child: const Text('Send Reset Email'),
        ),
      ],
    );
  }
}
