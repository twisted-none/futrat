import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
  // ЛОКАЛЬНАЯ ПЕРЕМЕННАЯ (хранит состояние только этого экрана)
  // true = Регистрация, false = Вход
  bool _isRegister = true; 
  
  bool _obscurePassword = true;

  final Color _deepPurple = const Color(0xFF2E004E);
  final Color _neonPurple = const Color(0xFFD500F9);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF121212), _deepPurple],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "FUTRAT",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 15.0, color: _neonPurple, offset: Offset.zero),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isRegister ? "Создание аккаунта" : "Вход в систему",
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                  const SizedBox(height: 40),

                  // === ПОЛЕ НИКНЕЙМ (Только при регистрации) ===
                  if (_isRegister)
                    Column(
                      children: [
                        _buildNeonTextField(
                          controller: _usernameController,
                          label: "Никнейм",
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  // === ПОЛЕ EMAIL / ЛОГИН ===
                  _buildNeonTextField(
                    controller: _emailController,
                    label: _isRegister ? "Email" : "Email или Никнейм",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // === ПОЛЕ ПАРОЛЬ ===
                  _buildNeonTextField(
                    controller: _passwordController,
                    label: "Пароль",
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  
                  const SizedBox(height: 30),

                  // Ошибки
                  if (authProvider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Кнопка действия
                  if (authProvider.isLoading)
                    CircularProgressIndicator(color: _neonPurple)
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _neonPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 5,
                        ),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          
                          if (_isRegister) {
                            await authProvider.register(
                              _emailController.text.trim(),
                              _usernameController.text.trim(),
                              _passwordController.text.trim()
                            );
                          } else {
                            await authProvider.login(
                              _emailController.text.trim(), 
                              _passwordController.text.trim()
                            );
                          }
                        },
                        child: Text(
                          _isRegister ? "ЗАРЕГИСТРИРОВАТЬСЯ" : "ВОЙТИ",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  // === КНОПКА ПЕРЕКЛЮЧЕНИЯ ===
                  // ВАЖНО: Тут нет вызовов authProvider, только setState!
                  TextButton(
                    onPressed: () {
                      print("--- КНОПКА НАЖАТА: setState ---");
                      setState(() {
                        _isRegister = !_isRegister;
                        // Мы НЕ вызываем authProvider.clearError(), чтобы не будить Роутер
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      foregroundColor: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isRegister ? "Уже есть аккаунт? " : "Нет аккаунта? ",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          _isRegister ? "Войти" : "Создать",
                          style: TextStyle(
                            color: _neonPurple, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeonTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Colors.white),
      cursorColor: _neonPurple,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword 
          ? IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            )
          : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _neonPurple, width: 2),
        ),
      ),
    );
  }
}