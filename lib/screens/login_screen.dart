import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme/app_theme.dart';
import '../dashboards/student_dashboard.dart';
import '../dashboards/parent_dashboard.dart';
import '../dashboards/mentor_dashboard.dart';
import '../services/auth_service.dart';
import '../screens/link_ward_screen.dart';
import '../services/assessment_service.dart';

class LoginScreen extends StatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool isLoading = false;

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
        final Map<String, dynamic> response = await authService.login(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
          selectedRole: widget.role,
        );

        if (response.containsKey('error')) {
          _showSnackBar(response['error'] as String, Colors.red);
        } else if (response.containsKey('access_token')) {
          final String token = response['access_token'] as String;

          await _storage.write(key: 'auth_token', value: token);

          final String? verify = await _storage.read(key: 'auth_token');

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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToDashboard() async {
    Widget nextScreen;

    if (widget.role == "Student") {
      nextScreen = const StudentDashboard();
    } else if (widget.role == "Parent") {
      final AssessmentService apiService = AssessmentService();

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()));

      try {
        final status = await apiService.getLinkedStudentStatus();

        if (!mounted) return;
        Navigator.pop(context);

        if (status['is_linked'] == true) {
          nextScreen = const ParentDashboard();
        } else {
          nextScreen = const LinkWardScreen();
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        _showSnackBar("Session error: Please link your ward manually.", Colors.orange);
        nextScreen = const LinkWardScreen();
      }
    } else if (widget.role == "Mentor") {
      nextScreen = const MentorDashboard();
    } else {
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Responsive helpers ──────────────────────────────────────────────────
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;   // screen width
    final sh = mq.size.height;  // screen height

    // Scale factor relative to a 390×844 baseline (iPhone 14 logical pixels).
    // Clamp between 0.8 and 1.2 so extremely small/large screens don't go wild.
    final double sf = (sw / 390).clamp(0.80, 1.20);

    // Responsive spacing helpers
    double rw(double v) => v * sf;           // width / horizontal
    double rh(double v) => v * (sh / 844);  // height / vertical
    double rs(double v) => v * sf;           // font sizes

    // White card height fractions — adjusted per form state
    final double cardHeightFraction = isLogin ? 0.68 : 0.84;
    // On very short screens (< 700 dp) the card should grow a bit more
    final double cardHeightFraction2 =
    sh < 700 ? (isLogin ? 0.75 : 0.92) : cardHeightFraction;

    final double ellipseY = isLogin ? rh(150) : rh(80);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBottom,
      // Keeps the layout from being pushed up by the soft keyboard
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Stack(
                  children: [
                    // ── Background gradient + image ─────────────────────────
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: sh * 0.45,
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
                            errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),

                    // ── White animated card ─────────────────────────────────
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCirc,
                      height: sh * cardHeightFraction2,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.elliptical(rw(300), ellipseY),
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
                          padding: EdgeInsets.symmetric(horizontal: rw(32)),
                          child: Column(
                            children: [
                              SizedBox(height: rh(10)),

                              // Toggle Login / Sign-up
                              GestureDetector(
                                onTap: () => setState(() => isLogin = !isLogin),
                                child: Text(
                                  isLogin ? "Sign up" : "Log In",
                                  style: AppTheme.subheading.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                    fontSize: rs(15),
                                  ),
                                ),
                              ),
                              SizedBox(height: rh(20)),

                              // Heading
                              Text(
                                isLogin ? "Welcome Back" : "Join Us",
                                style: AppTheme.heading.copyWith(
                                  fontSize: rs(34),
                                  letterSpacing: -1,
                                ),
                              ),
                              Text(
                                "Logging in as ${widget.role}",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: rs(13),
                                ),
                              ),
                              SizedBox(height: rh(30)),

                              // Full-name field (sign-up only)
                              if (!isLogin) ...[
                                _buildTextField(
                                  "Full Name",
                                  Icons.person_outline,
                                  controller: _nameController,
                                  sf: sf,
                                ),
                                SizedBox(height: rh(16)),
                              ],

                              _buildTextField(
                                "Email address",
                                Icons.email_outlined,
                                controller: _emailController,
                                sf: sf,
                              ),
                              SizedBox(height: rh(16)),

                              _buildTextField(
                                "Password",
                                Icons.lock_outline,
                                isPassword: true,
                                controller: _passController,
                                sf: sf,
                              ),

                              if (!isLogin) ...[
                                SizedBox(height: rh(16)),
                                _buildTextField(
                                  "Confirm Password",
                                  Icons.lock_outline,
                                  isPassword: true,
                                  controller: _confPassController,
                                  sf: sf,
                                ),
                              ],

                              if (isLogin) ...[
                                SizedBox(height: rh(12)),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: rs(13),
                                    ),
                                  ),
                                ),
                              ],

                              SizedBox(height: rh(35)),

                              // Auth button
                              ElevatedButton(
                                onPressed: isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.textPrimary,
                                  minimumSize: Size(double.infinity, rh(60)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(rw(20)),
                                  ),
                                  elevation: 5,
                                  shadowColor: AppTheme.textPrimary.withOpacity(0.3),
                                ),
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                  isLogin ? "Log in" : "Sign up",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: rs(16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: rh(20)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Social section (sits below the card) ─────────────────
                    _buildSocialSection(sf: sf, sh: sh),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSocialSection({required double sf, required double sh}) {
    double rw(double v) => v * sf;
    double rh(double v) => v * (sh / 844);
    double rs(double v) => v * sf;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: rh(35), top: rh(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: rw(45)),
              child: Row(
                children: [
                  Expanded(
                      child: Container(height: 1.5, color: Colors.black.withOpacity(0.1))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: rw(15)),
                    child: Text(
                      "or continue with",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: rs(13),
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Expanded(
                      child: Container(height: 1.5, color: Colors.black.withOpacity(0.1))),
                ],
              ),
            ),
            SizedBox(height: rh(25)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  'https://www.gstatic.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                  sf: sf,
                  sh: sh,
                ),
                SizedBox(width: rw(25)),
                _buildSocialButton(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/600px-Facebook_Logo_%282019%29.png',
                  sf: sf,
                  sh: sh,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String hint,
      IconData icon, {
        bool isPassword = false,
        TextEditingController? controller,
        required double sf,
      }) {
    final double rs14 = (14 * sf).clamp(12.0, 16.0);
    final double iconSize = (22 * sf).clamp(18.0, 24.0);
    final double vertPad = (20 * sf).clamp(14.0, 22.0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(18 * sf),
        border: Border.all(color: Colors.black.withOpacity(0.02)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: rs14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: rs14),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: iconSize),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: vertPad, horizontal: 20 * sf),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      String url, {
        required double sf,
        required double sh,
      }) {
    final double size = (62 * sf).clamp(50.0, 70.0);
    final double pad = (12 * sf).clamp(10.0, 14.0);

    return Container(
      padding: EdgeInsets.all(pad),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.public, color: Colors.grey),
      ),
    );
  }
}