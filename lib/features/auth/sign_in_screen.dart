import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/providers/auth_provider.dart';
import '../../core/data/providers/trip_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.signIn(_emailController.text, _passwordController.text);

    if (mounted) {
      setState(() => _isLoading = false);
      
      final authState = ref.read(authProvider);
      authState.when(
        authenticated: (_) {
          // Refresh trips after successful login
          ref.read(tripsProvider.notifier).loadTrips();
          context.go('/');
        },
        guest: (_) {
          // Guest login shouldn't happen here, but handle it
          context.go('/');
        },
        error: (error) => _showErrorSnackBar(error),
        initial: () {},
        loading: () {},
        unauthenticated: () {},
      );
    }
  }

  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);

    final authNotifier = ref.read(authProvider.notifier);
    await authNotifier.signInAsGuest();

    if (mounted) {
      setState(() => _isLoading = false);
      
      final authState = ref.read(authProvider);
      authState.when(
        authenticated: (_) {
          // Regular login shouldn't happen here, but handle it
          context.go('/');
        },
        guest: (_) {
          // Navigate to public trips discovery
          context.go('/discover');
        },
        error: (error) => _showErrorSnackBar(error),
        initial: () {},
        loading: () {},
        unauthenticated: () {},
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.paddingLg,
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top - AppSpacing.lg * 2,
              child: Column(
                children: [
                  // Header
                  AppSpacing.verticalSpaceXl,
                  _buildHeader(theme),
                  
                  const Spacer(),
                  
                  // Sign In Form
                  _buildForm(theme),
                  
                  const Spacer(),
                  
                  // Footer
                  _buildFooter(theme),
                  AppSpacing.verticalSpaceLg,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => context.go('/auth/welcome'),
            icon: const Icon(Icons.arrow_back_ios),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              padding: AppSpacing.paddingMd,
            ),
          ),
        ),
        
        AppSpacing.verticalSpaceXl,
        
        // Welcome text
        Text(
          'Welcome back!',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        
        AppSpacing.verticalSpaceMd,
        
        Text(
          'Sign in to continue your journey',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(ThemeData theme) {
    return Container(
      padding: AppSpacing.paddingXl,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppSpacing.cardRadius,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            
            AppSpacing.verticalSpaceLg,
            
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _signIn(),
            ),
            
            AppSpacing.verticalSpaceMd,
            
            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Handle forgot password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Forgot password feature coming soon!'),
                    ),
                  );
                },
                child: const Text('Forgot Password?'),
              ),
            ),
            
            AppSpacing.verticalSpaceLg,
            
            // Sign in button
            SizedBox(
              height: AppSpacing.buttonHeightLg,
              child: FilledButton(
                onPressed: _isLoading ? null : _signIn,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            
            AppSpacing.verticalSpaceLg,
            
            // Divider
            Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.3))),
                Padding(
                  padding: AppSpacing.paddingHorizontalMd,
                  child: Text(
                    'or',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outline.withOpacity(0.3))),
              ],
            ),
            
            AppSpacing.verticalSpaceLg,
            
            // Social sign in buttons
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Google Sign-In coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.g_mobiledata),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                padding: AppSpacing.paddingVerticalMd,
              ),
            ),
            
            AppSpacing.verticalSpaceMd,
            
            // Guest login button
            TextButton.icon(
              onPressed: () => _signInAsGuest(),
              icon: const Icon(Icons.person_outline),
              label: const Text('Continue as Guest'),
              style: TextButton.styleFrom(
                padding: AppSpacing.paddingVerticalMd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () => context.go('/auth/signup'),
          child: const Text(
            'Sign Up',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

