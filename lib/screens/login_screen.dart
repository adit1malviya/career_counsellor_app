import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../dashboards/student_dashboard.dart';
import '../dashboards/parent_dashboard.dart';
import '../dashboards/mentor_dashboard.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool isLoading = false;

  // ✅ Secure Storage — Updated to use EncryptedSharedPreferences for Android reliability
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confPassController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confPassController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleAuth() async {
    debugPrint("🔥 URL IS: ${AuthService().cleanBaseUrl}");
    final authService = AuthService();

    if (_emailController.text.trim().isEmpty || _passController.text.trim().isEmpty) {
      _showSnackBar("Please fill in all fields", Colors.redAccent);
      return;
    }

    if (!isLogin) {
      if (_nameController.text.trim().isEmpty) {
        _showSnackBar("Full Name is required", Colors.redAccent);
        return;
      }
      if (_passController.text != _confPassController.text) {
        _showSnackBar("Passwords do not match!", Colors.redAccent);
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // ✅ login() now returns Map<String, dynamic>
        //    'error' key    → failure, show the message
        //    'access_token' → success, save token and navigate
        final Map<String, dynamic> response = await authService.login(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
          selectedRole: widget.role,
        );

        if (response.containsKey('error')) {
          // ✅ Show the REAL error (role mismatch, wrong password, etc.)
          _showSnackBar(response['error'] as String, Colors.red);
        } else if (response.containsKey('access_token')) {
          final String token = response['access_token'] as String;

          // ✅ STEP 1: Write token to secure storage
          await _storage.write(key: 'auth_token', value: token);

          // ✅ STEP 2: Read back immediately to confirm it was stored
          final String? verify = await _storage.read(key: 'auth_token');

          // ✅ STEP 3: Log result clearly in debug console
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
          if (verify != null && verify.isNotEmpty) {
            debugPrint("✅ TOKEN SUCCESSFULLY STORED IN SECURE STORAGE");
            debugPrint("🔑 KEY   : auth_token");
            debugPrint("📄 TOKEN : $verify");
          } else {
            debugPrint("❌ TOKEN STORAGE FAILED — storage returned null");
          }
          debugPrint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

          _navigateToDashboard();
        } else {
          _showSnackBar("Unexpected server response. Please try again.", Colors.red);
        }

      } else {
        // ✅ register() still returns String — unchanged
        final String regResult = await authService.register(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
          fullName: _nameController.text.trim(),
          role: widget.role,
        );

        if (regResult == "SUCCESS") {
          _showSnackBar("Registration successful! Please login.", Colors.green);
          setState(() {
            isLogin = true;
            _confPassController.clear();
          });
        } else {
          _showSnackBar(regResult, Colors.red);
        }
      }
    } catch (e) {
      debugPrint("❌ AUTH ERROR: $e");
      _showSnackBar("An unexpected error occurred", Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UI HELPERS ---

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToDashboard() {
    Widget nextScreen;
    if (widget.role == "Student") {
      nextScreen = const StudentDashboard();
    } else if (widget.role == "Parent") {
      nextScreen = const ParentDashboard();
    } else if (widget.role == "Mentor") {
      nextScreen = const MentorDashboard();
    } else {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppTheme.backgroundBottom,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: h * 0.45,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.backgroundMid, AppTheme.backgroundBottom],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Opacity(
                          opacity: 0.35,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1523240795612-9a054b0db644?q=80&w=2070',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCirc,
                      height: isLogin ? h * 0.68 : h * 0.82,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.elliptical(300, isLogin ? 150 : 80),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () => setState(() => isLogin = !isLogin),
                                child: Text(
                                  isLogin ? "Sign up" : "Log In",
                                  style: AppTheme.subheading.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                isLogin ? "Welcome Back" : "Join Us",
                                style: AppTheme.heading.copyWith(fontSize: 34, letterSpacing: -1),
                              ),
                              Text("Logging in as ${widget.role}", style: TextStyle(color: Colors.grey.shade500)),
                              const SizedBox(height: 30),
                              if (!isLogin) ...[
                                _buildTextField("Full Name", Icons.person_outline, controller: _nameController),
                                const SizedBox(height: 16),
                              ],
                              _buildTextField("Email address", Icons.email_outlined, controller: _emailController),
                              const SizedBox(height: 16),
                              _buildTextField("Password", Icons.lock_outline, isPassword: true, controller: _passController),
                              if (!isLogin) ...[
                                const SizedBox(height: 16),
                                _buildTextField("Confirm Password", Icons.lock_outline, isPassword: true, controller: _confPassController),
                              ],
                              if (isLogin) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text("Forgot password?",
                                      style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                              const SizedBox(height: 35),
                              ElevatedButton(
                                onPressed: isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.textPrimary,
                                  minimumSize: const Size(double.infinity, 60),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  elevation: 5,
                                  shadowColor: AppTheme.textPrimary.withOpacity(0.3),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  isLogin ? "Log in" : "Sign up",
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _buildSocialSection(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialSection() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 35, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 45),
              child: Row(
                children: [
                  Expanded(child: Container(height: 1.5, color: Colors.black.withOpacity(0.1))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                        "or continue with",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54)
                    ),
                  ),
                  Expanded(child: Container(height: 1.5, color: Colors.black.withOpacity(0.1))),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton('https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png'),
                const SizedBox(width: 25),
                _buildSocialButton('https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/600px-Facebook_Logo_%282019%29.png'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {bool isPassword = false, TextEditingController? controller}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildSocialButton(String url) {
    return Container(
      padding: const EdgeInsets.all(12),
      width: 62, height: 62,
      decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5)
            )
          ]
      ),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.public, color: Colors.grey),
      ),
    );
  }
}