// Login View – minimal auth entry point.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: 280,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppTheme.headerGradient),
            child: const SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 56, color: AppTheme.white),
                  SizedBox(height: 16),
                  Text('BP Mitra',
                      style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 6),
                  Text('Your Hypertension Companion',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/dashboard'),
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text('Don\'t have an account? Register',
                        style: TextStyle(color: AppTheme.darkBlue)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
