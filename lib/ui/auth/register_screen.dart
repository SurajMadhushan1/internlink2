import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:internlink/ui/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final String role;

  const RegisterScreen({
    super.key,
    required this.role,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _linkedinController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _linkedinController.dispose();
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

  bool get _isCompanyRole => widget.role == AppConstants.roleCompany;

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    // If already signed in, just navigate
    if (authProvider.isAuthenticated) {
      final role = authProvider.user?.role ?? widget.role;
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
    await authProvider.registerWithEmailPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: widget.role,
      linkedinUrl: _isCompanyRole ? _linkedinController.text.trim() : null,
    );

    if (authProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else if (mounted) {
      // Navigate to home for the role after successful sign up
      final role = authProvider.user?.role ?? widget.role;
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

  Future<void> _signUpWithGoogle() async {
    final authProvider = context.read<AuthProvider>();
    // If already signed in, just navigate
    if (authProvider.isAuthenticated) {
      final role = authProvider.user?.role ?? widget.role;
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
      final role = authProvider.user?.role ?? widget.role;
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

  void _goToLogin() {
    context.go('/login?role=${widget.role}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up as $_roleDisplayName'),
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
                      'Create Account',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Join InternLink as a $_roleDisplayName',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText:
                            _isCompanyRole ? 'Company Name' : 'Full Name',
                        prefixIcon: Icon(
                            _isCompanyRole ? Icons.business : Icons.person),
                      ),
                      validator: (value) => Validators.required(value, 'Name'),
                    ),

                    const SizedBox(height: 16),

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

                    // LinkedIn URL (only for companies)
                    if (_isCompanyRole) ...[
                      TextFormField(
                        controller: _linkedinController,
                        decoration: const InputDecoration(
                          labelText: 'LinkedIn Company URL',
                          prefixIcon: Icon(Icons.link),
                          hintText: 'https://linkedin.com/company/your-company',
                        ),
                        keyboardType: TextInputType.url,
                        validator: Validators.linkedinUrl,
                      ),
                      const SizedBox(height: 16),
                    ],

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

                    const SizedBox(height: 16),

                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscureConfirmPassword,
                      validator: (value) => Validators.confirmPassword(
                          value, _passwordController.text),
                    ),

                    const SizedBox(height: 32),

                    // Company approval notice
                    if (_isCompanyRole) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Company accounts require admin approval before posting internships.',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Sign up button
                    ElevatedButton(
                      onPressed: _signUpWithEmail,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Create Account'),
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

                    // Google sign up
                    OutlinedButton.icon(
                      onPressed: _signUpWithGoogle,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login link
                    Center(
                      child: TextButton(
                        onPressed: _goToLogin,
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
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
                                text: 'Sign In',
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
