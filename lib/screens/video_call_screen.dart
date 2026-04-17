import 'package:flutter/material.dart';
import 'package:realtimekit_ui/realtimekit_ui.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String token;

  const VideoCallScreen({
    super.key,
    required this.token,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isCheckingPermissions = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.bluetoothConnect,
    ].request();

    if (mounted) {
      setState(() {
        _hasPermissions = statuses[Permission.camera] == PermissionStatus.granted &&
            statuses[Permission.microphone] == PermissionStatus.granted;
        _isCheckingPermissions = false;
      });
    }
  }

  void _joinMeeting() {
    try {
      final meetingInfo = RtkMeetingInfo(authToken: widget.token);
      final uiKitInfo = RealtimeKitUIInfo(meetingInfo);

      // The builder now returns the Widget directly! No need for loadUI().
      final rtkWidget = RealtimeKitUIBuilder.build(uiKitInfo: uiKitInfo);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => rtkWidget,
        ),
      );
    } catch (e) {
      debugPrint("Failed to load RealtimeKit UI: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to initialize the video session.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // STATE 1: Loading
    if (_isCheckingPermissions) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blueAccent),
              SizedBox(height: 24),
              Text("Securing connection...", style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    // STATE 2: Permissions Denied
    if (!_hasPermissions) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_rounded, color: Colors.orangeAccent, size: 64),
                const SizedBox(height: 16),
                const Text(
                  "Camera and Microphone access are required.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: openAppSettings,
                  child: const Text("Open Settings"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Go Back", style: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          ),
        ),
      );
    }

    // STATE 3: Ready to Join
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              "Hardware successfully prepared.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _joinMeeting,
                child: const Text(
                  "Enter Session",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            )
          ],
        ),
      ),
    );
  }
}