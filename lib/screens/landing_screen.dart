import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/role_card.dart';
import '../screens/login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundTop,
              AppTheme.backgroundMid,
              AppTheme.backgroundBottom,
            ],
            stops: [0.0, 0.45, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flexible top gap - adapts to screen height
                const Spacer(flex: 2),

                // 1. Heading Section
                RichText(
                  text: TextSpan(
                    style: AppTheme.heading.copyWith(
                      fontSize: 52, // Slightly reduced from 60 for better fit
                      height: 1.1,
                      letterSpacing: -1.0,
                      fontWeight: FontWeight.w900,
                    ),
                    children: [
                      const TextSpan(
                        text: "How do you\nwant to\n",
                        style: TextStyle(color: AppTheme.textPrimary),
                      ),
                      TextSpan(
                        text: "join us?",
                        style: TextStyle(color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Subheading Section
                Text(
                  "Select your role to personalize your journey toward meaningful growth.",
                  style: AppTheme.subheading.copyWith(
                    fontSize: 14,
                    color: AppTheme.textSecondary.withOpacity(0.7),
                    height: 1.4,
                  ),
                ),

                // Flexible gap between text and cards
                const Spacer(flex: 2),

                // 3. ROLE CARDS
                RoleCard(
                  title: "Student",
                  subtitle: "Discover your career path",
                  icon: Icons.school_outlined,
                  accentColor: AppTheme.student,
                  iconBg: AppTheme.studentBg,
                  onTap: () => _navigateToLogin(context, "Student"),
                ),

                const SizedBox(height: 12),

                RoleCard(
                  title: "Mentor",
                  subtitle: "Guide the next generation",
                  icon: Icons.work_outline_rounded,
                  accentColor: AppTheme.mentor,
                  iconBg: AppTheme.mentorBg,
                  onTap: () => _navigateToLogin(context, "Mentor"),
                ),

                const SizedBox(height: 12),

                RoleCard(
                  title: "Parent",
                  subtitle: "Track your child's progress",
                  icon: Icons.group_outlined,
                  accentColor: AppTheme.parent,
                  iconBg: AppTheme.parentBg,
                  onTap: () => _navigateToLogin(context, "Parent"),
                ),

                // Flexible gap before the bottom button
                const Spacer(flex: 3),

                // 4. Bottom Section (Sign In)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: GestureDetector(
                      onTap: () => _navigateToLogin(context, "Student"),
                      child: RichText(
                        text: TextSpan(
                          text: "ALREADY HAVE AN ACCOUNT? ",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.8,
                          ),
                          children: [
                            TextSpan(
                              text: "SIGN IN",
                              style: TextStyle(
                                color: AppTheme.primary.withOpacity(0.8),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(role: role),
      ),
    );
  }
}