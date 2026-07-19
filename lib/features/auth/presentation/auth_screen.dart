import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../../main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

    if (!canAuthenticate) {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
      }
      return;
    }

    bool authenticated = false;
    try {
      setState(() => _isAuthenticating = true);
      authenticated = await auth.authenticate(
        localizedReason: 'Cüzdanınıza erişmek için doğrulama yapın',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      // Hata oluştu (Örn: Emülatörde kilit ekranı ayarlı değil)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cihazda kilit ekranı bulunamadı. Otomatik geçiş yapılıyor...'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      authenticated = true; // Emülatör testleri için bypass
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
    
    if (authenticated && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fingerprint, size: 80, color: Theme.of(context).primaryColor),
            ),
            const SizedBox(height: 24),
            Text('Fon Vakti', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 12),
            Text('Gizliliğiniz bizim için önemli', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 48),
            if (_isAuthenticating)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.lock_open),
                label: const Text('Kilidi Aç'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            const SizedBox(height: 16),
            if (!_isAuthenticating)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                  );
                },
                child: const Text('Test Girişi (Emülatör)', style: TextStyle(color: Colors.white54)),
              ),
          ],
        ),
      ),
    );
  }
}
