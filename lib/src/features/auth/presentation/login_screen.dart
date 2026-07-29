import 'package:flutter/material.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../shell/presentation/main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final rutController = TextEditingController();
  final passwordController = TextEditingController();
  bool hidePassword = true;

  @override
  void dispose() {
    rutController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (rutController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el RUT y la contraseña.')),
      );
      return;
    }

    await LocalStorageService.instance.writeBool('auth.session.active', true);
    await LocalStorageService.instance.writeString(
      'auth.session.rut',
      rutController.text.trim(),
    );

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(0xFFE7F0FA),
                      child: Icon(
                        Icons.engineering,
                        size: 58,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 33,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.edition,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      AppStrings.slogan,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: rutController,
                      decoration: const InputDecoration(
                        labelText: 'RUT',
                        hintText: '12.345.678-9',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      onSubmitted: (_) => login(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          tooltip: hidePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: login,
                        icon: const Icon(Icons.login),
                        label: const Text(
                          'INGRESAR',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Proyecto Maestro · Sprint 1',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
