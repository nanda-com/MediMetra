import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'services/report_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Safely initialize Firebase so it doesn't crash on Web if flutterfire isn't configured yet
  try {
    await Firebase.initializeApp();
  } catch (e) {
    if (kDebugMode) {
      print("Warning: Firebase configuration missing, but continuing to render UI. \nError: $e");
    }
  }
  
  runApp(const HealthApp());
}

class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Health Reminders',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Sleek deep slate blue
        useMaterial3: true,
        fontFamily: 'Roboto', // Modern sans-serif fallback
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _uploadMedicalReport() async {
    // Allows user to pick a medical bill/report directly from their device gallery
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    
    if (image != null && mounted) {
      setState(() => _isUploading = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI is analyzing your report...', style: TextStyle(color: Colors.white)), 
          duration: Duration(seconds: 4),
          backgroundColor: Color(0xFF38BDF8),
        )
      );
      
      try {
         final result = await ReportService().uploadReport(image);
         if (result != null && mounted) {
            final int reminders = result['total_reminders_generated'] ?? 0;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Success! Gemini AI scheduled $reminders upcoming reminders.'), backgroundColor: Colors.green)
            );
         } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to parse document: No response from AI.'), backgroundColor: Colors.red)
            );
         }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to parse document: $e'), backgroundColor: Colors.red)
           );
         }
      } finally {
         if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Splash screen animation setup
    _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Color(0xFFE11D48), size: 32),
            const SizedBox(width: 12),
            Text(
              "Vitals",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                  ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
            onPressed: () {},
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Background Gradient Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF818CF8).withValues(alpha: 0.4), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [const Color(0xFF38BDF8).withValues(alpha: 0.3), Colors.transparent],
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                children: [
                  const Text(
                    "Hello, Nanda",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Here is your daily health tracking.",
                    style: TextStyle(fontSize: 18, color: Colors.white60),
                  ),
                  const SizedBox(height: 32),
                  
                  // Today's Focus Card
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Focus",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Icon(Icons.auto_graph_rounded, color: Color(0xFF38BDF8)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            _buildMiniStat(Icons.water_drop_rounded, "1.2 L", "Hydration", const Color(0xFF38BDF8)),
                            const SizedBox(width: 16),
                            _buildMiniStat(Icons.directions_run_rounded, "4k", "Steps", const Color(0xFF34D399)),
                            const SizedBox(width: 16),
                            _buildMiniStat(Icons.nights_stay_rounded, "7h", "Sleep", const Color(0xFF818CF8)),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Pending Reminders Header
                  const Text(
                    "Pending Reminders",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reminders List
                  _buildReminderTile(
                    title: "Take Blood Pressure Medication",
                    time: "08:00 AM",
                    icon: Icons.medication_rounded,
                    color: const Color(0xFFF43F5E),
                  ),
                  const SizedBox(height: 12),
                  _buildReminderTile(
                    title: "Drink 2 glasses of water",
                    time: "10:30 AM",
                    icon: Icons.water_drop_rounded,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 12),
                  _buildReminderTile(
                    title: "Afternoon Walk",
                    time: "03:00 PM",
                    icon: Icons.directions_walk_rounded,
                    color: const Color(0xFF34D399),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isUploading ? null : _uploadMedicalReport,
        backgroundColor: _isUploading ? Colors.grey : const Color(0xFF818CF8),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _isUploading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Icon(Icons.document_scanner_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderTile({required String title, required String time, required IconData icon, required Color color}) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white54, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white38, size: 28),
            onPressed: () {},
            hoverColor: Colors.white10,
            splashRadius: 24,
          )
        ],
      ),
    );
  }
}

// A reusable Glassmorphism UI Card
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24.0),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: -2,
              )
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
