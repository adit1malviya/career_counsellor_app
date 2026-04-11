import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../dashboards/parent_dashboard.dart';
import '../services/assessment_service.dart'; // ✅ Added required import

class LinkWardScreen extends StatefulWidget {
  const LinkWardScreen({super.key});

  @override
  State<LinkWardScreen> createState() => _LinkWardScreenState();
}

class _LinkWardScreenState extends State<LinkWardScreen> {
  final TextEditingController _wardEmailController = TextEditingController();
  final TextEditingController _accessCodeController = TextEditingController();

  // ✅ Instantiate the service to handle API calls
  final AssessmentService _apiService = AssessmentService();

  /// Logic: Handles the linking process by validating input and calling the backend
  void _handleLinkProfile() async {
    final code = _accessCodeController.text.trim();

    // 1. Basic Validation
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid 6-digit code"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Show Modern Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.parentTheme,
          strokeWidth: 3,
        ),
      ),
    );

    try {
      // 3. Call the Backend API via AssessmentService
      final result = await _apiService.linkStudentToParent(code);

      if (!mounted) return;
      Navigator.pop(context); // Close the loading dialog

      // 4. Handle Success or Failure
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Successfully linked!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // 5. Navigate to Parent Dashboard and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ParentDashboard()),
              (route) => false,
        );
      } else {
        // Display backend error message (e.g., "Invalid invite code")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? "Linking failed"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loader on exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _wardEmailController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              AppTheme.parentTheme.withOpacity(0.03),
              const Color(0xFFF0F4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildBackButton(),
                const SizedBox(height: 40),

                // Header Section
                Stack(
                  children: [
                    Positioned(
                      left: 0, top: 0,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.parentTheme.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8, top: 8),
                      child: Text(
                        "Link Your Ward",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.parentTheme,
                          letterSpacing: -1.0,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Text(
                  "Connect with your child's account to monitor their growth journey.",
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey, height: 1.5),
                ),

                const SizedBox(height: 45),

                // Inputs Section
                _buildInputLabel("Ward's Registered Email"),
                _buildInputField(
                  hint: "alex@email.com",
                  icon: Icons.alternate_email_rounded,
                  controller: _wardEmailController,
                ),

                const SizedBox(height: 25),

                _buildInputLabel("Parent-Child Access Code"),
                _buildInputField(
                  hint: "Enter 6-digit code",
                  icon: Icons.vpn_key_outlined,
                  controller: _accessCodeController,
                  isCode: true,
                ),

                const SizedBox(height: 20),

                // Instruction Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.parentTheme.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.parentTheme.withOpacity(0.1),
                        radius: 18,
                        child: const Icon(Icons.lightbulb_outline, color: AppTheme.parentTheme, size: 20),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          "Your ward can find this code in their Profile > Settings > Family Link.",
                          style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.4, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                _buildVerifyButton(),

                const SizedBox(height: 20),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Link later",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS (UNCHANGED DESIGN) ---

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        height: 45, width: 45,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.chevron_left_rounded, color: Colors.black, size: 28),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black.withOpacity(0.7), letterSpacing: 0.3),
      ),
    );
  }

  Widget _buildInputField({required String hint, required IconData icon, required TextEditingController controller, bool isCode = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.characters, // ✅ Auto-capitalize for invite codes
        keyboardType: isCode ? TextInputType.text : TextInputType.emailAddress,
        maxLength: isCode ? 6 : null,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(
          counterText: "",
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: AppTheme.parentTheme.withOpacity(0.4), size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [AppTheme.parentTheme, Color(0xFF6554C0)]),
        boxShadow: [
          BoxShadow(color: AppTheme.parentTheme.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _handleLinkProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text(
          "Verify & Link Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}