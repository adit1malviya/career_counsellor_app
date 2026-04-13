import 'package:flutter/material.dart';
import 'package:dyte_uikit/dyte_uikit.dart';

class VideoCallScreen extends StatelessWidget {
  final String token;

  const VideoCallScreen({
    super.key,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Create the meeting info with your backend token
    final meetingInfo = DyteMeetingInfoV2(authToken: token);

    // 2. Initialize the UI Kit Info
    final uiKitInfo = DyteUIKitInfo(meetingInfo);

    // 3. Build the actual Video Call Widget
    final dyteWidget = DyteUIKitBuilder.build(
      uiKitInfo: uiKitInfo,
    );

    return Scaffold(
      backgroundColor: Colors.black, // Sleek black background
      body: SafeArea(
        // This widget automatically handles the camera, mic, grid, and End Call button
        child: dyteWidget,
      ),
    );
  }
}