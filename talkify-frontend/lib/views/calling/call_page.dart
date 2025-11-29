import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import '../../getx_controllers/call_controller.dart';
import '../../services/webrtc_service.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get call arguments
    final arguments = Get.arguments as Map<String, dynamic>?;
    final user = arguments?['user'] as Map<String, dynamic>?;
    final callType = arguments?['callType'] as String? ?? 'audio';
    final isIncoming = arguments?['isIncoming'] as bool? ?? false;
    
    return GetX<CallController>(
      init: Get.isRegistered<CallController>() ? Get.find<CallController>() : Get.put(CallController()),
      builder: (controller) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // Remote Video Stream (Full Screen)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey.shade800,
                  child: Stack(
                    children: [
                      // Remote video/audio stream
                      if (WebRTCService.remoteRenderer != null)
                        Stack(
                          children: [
                            webrtc.RTCVideoView(
                              WebRTCService.remoteRenderer!,
                              mirror: false,
                              objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                          ],
                        )
                      else
                        // Audio call UI (fallback when no stream)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                controller.remoteUserName.value.isNotEmpty 
                                    ? controller.remoteUserName.value 
                                    : user?['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Audio Call',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              if (controller.callState.value == 'connected') ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    controller.callDuration.value,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      
                      // Connection status overlay
                      if (controller.callState.value != 'connected')
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (controller.callState.value == 'ringing') ...[
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      isIncoming ? 'Incoming call...' : 'Ringing...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ] else if (controller.callState.value == 'calling') ...[
                                    const CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Connecting...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            
            // Local Video Stream (Picture-in-Picture)
            if (callType == 'video')
              Positioned(
                top: 60,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: WebRTCService.localRenderer != null
                        ? webrtc.RTCVideoView(
                            WebRTCService.localRenderer!,
                            mirror: true,
                            objectFit: webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          )
                        : Container(
                            color: Colors.grey.shade700,
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Local Video',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            
                // Call Status Info
                Positioned(
                  top: 60,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.remoteUserName.value.isNotEmpty 
                              ? controller.remoteUserName.value 
                              : user?['name'] ?? 'Unknown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCallStatusText(controller.callState.value, isIncoming),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            
            
                // Call Control Buttons (Bottom)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute Button
                        _buildCallButton(
                          icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
                          color: controller.isMuted.value ? Colors.red : Colors.white,
                          backgroundColor: controller.isMuted.value ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                          onPressed: () => controller.toggleMute(),
                          label: 'Mute',
                        ),
                        
                        // Speaker Button
                        _buildCallButton(
                          icon: controller.isSpeakerEnabled.value ? Icons.volume_up : Icons.volume_down,
                          color: controller.isSpeakerEnabled.value ? Colors.blue : Colors.white,
                          backgroundColor: controller.isSpeakerEnabled.value ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.2),
                          onPressed: () => controller.toggleSpeaker(),
                          label: 'Speaker',
                        ),
                        
                        // Toggle Camera Button (only for video calls)
                        if (callType == 'video')
                          _buildCallButton(
                            icon: controller.isVideoEnabled.value ? Icons.videocam : Icons.videocam_off,
                            color: controller.isVideoEnabled.value ? Colors.green : Colors.red,
                            backgroundColor: controller.isVideoEnabled.value ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                            onPressed: () => controller.toggleVideo(),
                            label: 'Camera',
                          ),
                        
                        // Accept/Reject buttons for incoming calls
                        if (isIncoming && controller.callState.value == 'ringing') ...[
                          _buildCallButton(
                            icon: Icons.call,
                            color: Colors.white,
                            backgroundColor: Colors.green,
                            onPressed: () => controller.acceptIncomingCall(controller.callId.value),
                            label: 'Accept',
                            isEndCall: true,
                          ),
                          _buildCallButton(
                            icon: Icons.call_end,
                            color: Colors.white,
                            backgroundColor: Colors.red,
                            onPressed: () => controller.rejectIncomingCall(controller.callId.value),
                            label: 'Reject',
                            isEndCall: true,
                          ),
                        ] else
                          // End Call Button
                          _buildCallButton(
                            icon: Icons.call_end,
                            color: Colors.white,
                            backgroundColor: Colors.red,
                            onPressed: () => controller.endCurrentCall(),
                            label: 'End',
                            isEndCall: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Get call status text based on state
  String _getCallStatusText(String callState, bool isIncoming) {
    switch (callState) {
      case 'calling':
        return 'Calling...';
      case 'ringing':
        return isIncoming ? 'Incoming call...' : 'Ringing...';
      case 'connected':
        return 'Connected';
      case 'ended':
        return 'Call ended';
      default:
        return 'Unknown';
    }
  }
  
  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isEndCall = false,
    String? label,
    Color? backgroundColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isEndCall ? 70 : 60,
          height: isEndCall ? 70 : 60,
          decoration: BoxDecoration(
            color: backgroundColor ?? color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (backgroundColor ?? color).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: color,
              size: isEndCall ? 30 : 24,
            ),
            onPressed: onPressed,
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
