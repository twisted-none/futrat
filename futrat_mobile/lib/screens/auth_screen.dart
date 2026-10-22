import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  var _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isRegister = true;
  bool _obscurePassword = true;
  bool _submitted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(_isRegister ? 'Регистрация' : 'Вход')),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _submitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'FUTRAT',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRegister
                                ? 'Создание аккаунта'
                                : 'Вход в систему',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _field(
                            controller: _usernameController,
                            label: 'Никнейм',
                            icon: Icons.person_outline,
                            validator: (value) {
                              final name = (value ?? '').trim();
                              if (name.isEmpty) return 'Введите никнейм';
                              if (_isRegister && name.runes.length < 3) {
                                return 'Никнейм должен содержать не менее 3 символов';
                              }
                              return null;
                            },
                            hint: _isRegister ? 'Не менее 3 символов' : null,
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _passwordController,
                            label: 'Пароль',
                            icon: Icons.lock_outline,
                            password: true,
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) return 'Введите пароль';
                              if (_isRegister && password.runes.length < 6) {
                                return 'Пароль должен содержать не менее 6 символов';
                              }
                              if (_isRegister && password.trim().isEmpty) {
                                return 'Пароль не может состоять только из пробелов';
                              }
                              if (password.contains('\u0000')) {
                                return 'Пароль содержит недопустимый символ';
                              }
                              if (_isRegister &&
                                  utf8.encode(password).length > 72) {
                                return 'Пароль слишком длинный';
                              }
                              return null;
                            },
                            hint: _isRegister ? 'Не менее 6 символов' : null,
                          ),
                          const SizedBox(height: 24),
                          if (auth.errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  auth.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: colors.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          if (auth.isLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            ElevatedButton(
                              onPressed: () async {
                                FocusScope.of(context).unfocus();
                                setState(() => _submitted = true);
                                if (!_formKey.currentState!.validate()) return;
                                if (_isRegister) {
                                  await auth.register(
                                    _usernameController.text.trim(),
                                    _passwordController.text,
                                  );
                                } else {
                                  await auth.login(
                                    _usernameController.text.trim(),
                                    _passwordController.text,
                                  );
                                }
                                if (context.mounted && auth.isAuthenticated) {
                                  Navigator.of(context).pop(true);
                                }
                              },
                              child: Text(
                                _isRegister ? 'Создать аккаунт' : 'ВОЙТИ',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: auth.isLoading
                                ? null
                                : () {
                                    auth.clearError();
                                    setState(() {
                                      _isRegister = !_isRegister;
                                      _submitted = false;
                                      _formKey = GlobalKey<FormState>();
                                    });
                                  },
                            child: Text(
                              _isRegister
                                  ? 'Уже есть аккаунт? Войти'
                                  : 'Нет аккаунта? Создать',
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Продолжить без входа'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool password = false,
    String? hint,
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    validator: validator,
    enabled: !context.read<AuthProvider>().isLoading,
    onChanged: (_) => context.read<AuthProvider>().clearError(),
    autocorrect: false,
    enableSuggestions: !password,
    textInputAction: password ? TextInputAction.done : TextInputAction.next,
    obscureText: password && _obscurePassword,
    decoration: InputDecoration(
      labelText: label,
      helperText: hint,
      errorMaxLines: 3,
      prefixIcon: Icon(icon),
      suffixIcon: password
          ? IconButton(
              tooltip: _obscurePassword ? 'Показать пароль' : 'Скрыть пароль',
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
    ),
  );
}
