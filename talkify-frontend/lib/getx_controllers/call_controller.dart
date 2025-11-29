
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import '../core/theme.dart';
import '../services/socket_service.dart';
import '../services/webrtc_service.dart';
import '../widgets/incoming_call_notification.dart';

class CallController extends GetxController {
  // Reactive variables for state management
  final RxString callState = 'idle'.obs; // idle, calling, ringing, connected, ended
  // Backend status values: initiated, ringing, answered, ended, missed, rejected
  final RxBool isConnected = false.obs;
  final RxBool isRinging = false.obs;
  final RxBool isMuted = false.obs;
  final RxBool isVideoEnabled = true.obs;
  final RxBool isSpeakerEnabled = false.obs;
  final RxString callDuration = '00:00'.obs;
  final RxString remoteUserId = ''.obs;
  final RxString callId = ''.obs;
  final RxString remoteUserName = ''.obs;
  final RxString callType = 'audio'.obs; // audio or video
  final RxBool isIncomingCall = false.obs;
  
  // Pending offer (store offer until call is accepted)
  Map<String, dynamic>? _pendingOffer;
  String? _pendingOfferRoomId;
  String? _pendingOfferFromUserId;
  
  // Call timer
  Timer? _callTimer;
  DateTime? _callStartTime;

  @override
  void onInit() {
    super.onInit();
    // Initialize controller
    _setupSocketListeners();
    _initializeWebRTC();
  }

  @override
  void onReady() {
    super.onReady();
    // Controller is ready
    // Initialize WebRTC and Socket.io
  }

  @override
  void onClose() {
    // Clean up resources
    _cleanupCall();
    WebRTCService.dispose();
    super.onClose();
  }

  // Setup Socket.IO event listeners
  void _setupSocketListeners() {
    // Check socket connection status
    final socketStatus = SocketService.getConnectionStatus();
    print('🔌 Socket connection status: $socketStatus');
    
    if (!socketStatus['isConnected']) {
      print('⚠️ Socket not connected, listeners may not work properly');
    }
    // Call-user events (when someone calls you)
    SocketService.onCallUser = (data) {
      print('📞 Call-user event: $data');
      handleCallUser(data);
    };
    
    // Incoming call events
    SocketService.onIncomingCall = (data) {
      print('📞 Incoming call: $data');
      _handleIncomingCall(data);
    };
    
    SocketService.onCallAccepted = (data) {
      print('✅ Call accepted: $data');
      _handleCallAccepted(data);
    };
    
    SocketService.onCallRejected = (data) {
      print('❌ Call rejected: $data');
      _handleCallRejected(data);
    };
    
    SocketService.onCallEnded = (data) {
      print('📞 Call ended: $data');
      _handleCallEnded(data);
    };
    
    // WebRTC signaling events
    SocketService.onCallOffer = (data) {
      print('📡 WebRTC offer received: $data');
      _handleCallOffer(data);
    };
    
    SocketService.onCallAnswer = (data) {
      print('📡 WebRTC answer received: $data');
      _handleCallAnswer(data);
    };
    
    SocketService.onIceCandidate = (data) {
      print('🧊 ICE candidate received: $data');
      _handleIceCandidate(data);
    };
    
    SocketService.onCallStateChange = (data) {
      print('🔄 Call state changed: $data');
      _handleCallStateChange(data);
    };
    
    // WebRTC signaling events
    SocketService.onWebRTCOffer = (data) {
      print('📡 WebRTC offer received: $data');
      _handleWebRTCOffer(data);
    };
    
    SocketService.onWebRTCAnswer = (data) {
      print('📡 WebRTC answer received: $data');
      _handleWebRTCAnswer(data);
    };
    
    SocketService.onWebRTCIceCandidate = (data) {
      print('🧊 WebRTC ICE candidate received: $data');
      _handleWebRTCIceCandidate(data);
    };
    
    // Connection status
    SocketService.onConnectionStatusChanged = (status) {
      print('🔌 Socket connection status: $status');
      _handleConnectionStatusChange(status);
    };
  }

  // Handle call-user event (when someone calls you)
  void handleCallUser(Map<String, dynamic> data) {
    final from = data['from'] ?? data['callerId'] ?? '';
    final callType = data['callType'] ?? 'audio';
    final roomId = data['roomId'] ?? data['callId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final callerName = data['callerName'] ?? data['fromName'] ?? 'Unknown Caller';
    
    print('📞 Handling call-user event: $callerName ($callType)');
    
    // Update call state
    callId.value = roomId;
    remoteUserId.value = from;
    remoteUserName.value = callerName;
    this.callType.value = callType;
    isIncomingCall.value = true;
    callState.value = 'ringing';
    isRinging.value = true;
    
    // Ensure CallController is registered globally
    if (!Get.isRegistered<CallController>()) {
      Get.put(this);
    }
    
    // Navigate to CallNotificationPage
    Get.toNamed('/call-notification', arguments: {
      'callerId': from,
      'callerName': callerName,
      'callType': callType,
      'roomId': roomId,
    });
  }

  // Handle incoming call
  void _handleIncomingCall(Map<String, dynamic> data) {
    final callId = data['callId'] ?? data['roomId'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final callerId = data['callerId'] ?? data['from'];
    final callerName = data['callerName'] ?? data['fromName'] ?? 'Unknown';
    final callType = data['callType'] ?? 'audio';
    
    print('📞 Handling incoming call: $callerName ($callType)');
    
    // Update call state
    this.callId.value = callId;
    remoteUserId.value = callerId ?? '';
    remoteUserName.value = callerName;
    this.callType.value = callType;
    isIncomingCall.value = true;
    callState.value = 'ringing';
    isRinging.value = true;

    // Ensure CallController is registered globally
    if (!Get.isRegistered<CallController>()) {
      Get.put(this);
    }

    // Navigate to CallNotificationPage for incoming call
    Get.toNamed('/call-notification', arguments: {
      'callerId': callerId ?? '',
      'callerName': callerName,
      'callType': callType,
      'roomId': callId,
    });
  }


  // Handle call accepted
  void _handleCallAccepted(Map<String, dynamic> data) {
    final callId = data['callId'];
    final acceptedBy = data['acceptedBy'];
    print('Call $callId accepted by $acceptedBy');
    
    // Update call state (backend status: answered -> UI state: connected)
    callState.value = 'connected';
    isRinging.value = false;
    isConnected.value = true;
    
    // Start call timer
    _startCallTimer();
    
    Get.snackbar('Call Connected', 'Call accepted by $acceptedBy');
  }

  // Handle call rejected
  void _handleCallRejected(Map<String, dynamic> data) {
    final callId = data['callId'];
    final rejectedBy = data['rejectedBy'];
    print('Call $callId rejected by $rejectedBy');
    
    // Update call state
    callState.value = 'ended';
    isRinging.value = false;
    isConnected.value = false;
    
    Get.snackbar('Call Rejected', 'Call was rejected by the other party');
    _cleanupCall();
  }

  // Handle call ended
  void _handleCallEnded(Map<String, dynamic> data) {
    final callId = data['callId'];
    final endedBy = data['endedBy'];
    final duration = data['duration'];
    print('Call $callId ended by $endedBy (duration: ${duration}s)');
    
    // Update call state
    callState.value = 'ended';
    isRinging.value = false;
    isConnected.value = false;
    
    // Stop call timer
    _stopCallTimer();
    
    Get.snackbar('Call Ended', 'Call ended (duration: ${duration}s)');
    _cleanupCall();
  }

  // Handle WebRTC offer
  void _handleCallOffer(Map<String, dynamic> data) {
    final callId = data['callId'];
    final from = data['from'];
    print('WebRTC offer received for call $callId from $from');
    // TODO: Handle WebRTC offer
  }

  // Handle WebRTC answer
  void _handleCallAnswer(Map<String, dynamic> data) {
    final callId = data['callId'];
    final from = data['from'];
    print('WebRTC answer received for call $callId from $from');
    // TODO: Handle WebRTC answer
  }

  // Handle ICE candidate
  void _handleIceCandidate(Map<String, dynamic> data) {
    final callId = data['callId'];
    final from = data['from'];
    print('ICE candidate received for call $callId from $from');
    // TODO: Handle ICE candidate
  }

  // Handle call state change
  void _handleCallStateChange(Map<String, dynamic> data) {
    final callId = data['callId'];
    final state = data['state'];
    final from = data['from'];
    print('Call state changed: $callId → $state from $from');
    // TODO: Handle call state change
  }

  // Handle connection status change
  void _handleConnectionStatusChange(String status) {
    print('Socket connection status: $status');
    // TODO: Update UI based on connection status
  }

  // WebRTC Event Handlers

  // Handle WebRTC offer - CRITICAL: Store offer but DON'T process until call accepted
  void _handleWebRTCOffer(Map<String, dynamic> data) {
    try {
      print('========================================');
      print('📡 === CALL CONTROLLER: RECEIVED WEBRTC OFFER ===');
      print('⚠️ IMPORTANT: Offer will be STORED but NOT processed until call is accepted');
      print('📡 Full data received: $data');
      
      final roomId = data['roomId'];
      final fromUserId = data['from'];
      final offerData = data['offer'];
      
      print('📡 Parsed values:');
      print('📡 Room ID: $roomId');
      print('📡 From user: $fromUserId');
      print('📡 Offer data present: ${offerData != null ? "YES" : "NO"}');
      
      if (offerData == null) {
        print('❌ CRITICAL: No offer data in received message!');
        return;
      }
      
      print('📡 Offer data keys: ${offerData.keys.join(", ")}');
      print('📡 Offer SDP present: ${offerData['sdp'] != null ? "YES" : "NO"}');
      print('📡 Offer type: ${offerData['type']}');
      
      // CRITICAL: Store the offer but DON'T process it yet
      // This prevents media from flowing before the call is accepted
      _pendingOffer = offerData;
      _pendingOfferRoomId = roomId;
      _pendingOfferFromUserId = fromUserId;
      
      print('✅ Offer STORED (not processed)');
      print('✅ Media will NOT flow until user accepts the call');
      print('========================================');
      
    } catch (e, stackTrace) {
      print('❌ Error handling WebRTC offer: $e');
      print('❌ Stack trace: $stackTrace');
      print('========================================');
    }
  }

  // Handle WebRTC answer
  void _handleWebRTCAnswer(Map<String, dynamic> data) {
    try {
      print('========================================');
      print('📡 === CALL CONTROLLER: HANDLING WEBRTC ANSWER ===');
      print('📡 Full data received: $data');
      
      final answerData = data['answer'];
      
      print('📡 Answer data present: ${answerData != null ? "YES" : "NO"}');
      
      if (answerData == null) {
        print('❌ CRITICAL: No answer data in received message!');
        return;
      }
      
      print('📡 Answer data keys: ${answerData.keys.join(", ")}');
      print('📡 Answer SDP present: ${answerData['sdp'] != null ? "YES" : "NO"}');
      print('📡 Answer type: ${answerData['type']}');
      
      // Create RTCSessionDescription from answer data
      final answer = webrtc.RTCSessionDescription(
        answerData['sdp'],
        answerData['type'],
      );
      
      print('📡 Created RTCSessionDescription:');
      print('📡 - Type: ${answer.type}');
      print('📡 - SDP length: ${answer.sdp?.length ?? 0}');
      print('📡 - SDP preview: ${answer.sdp?.substring(0, 100) ?? "N/A"}...');
      
      // Handle the answer
      print('📡 Passing answer to WebRTCService.handleAnswer()...');
      WebRTCService.handleAnswer(answer);
      print('========================================');
      
    } catch (e, stackTrace) {
      print('❌ Error handling WebRTC answer: $e');
      print('❌ Stack trace: $stackTrace');
      print('========================================');
    }
  }

  // Handle WebRTC ICE candidate
  void _handleWebRTCIceCandidate(Map<String, dynamic> data) {
    try {
      print('========================================');
      print('🧊 === CALL CONTROLLER: HANDLING WEBRTC ICE CANDIDATE ===');
      print('🧊 Full data received: $data');
      
      final candidateData = data['candidate'];
      
      print('🧊 Candidate data present: ${candidateData != null ? "YES" : "NO"}');
      
      if (candidateData == null) {
        print('❌ CRITICAL: No candidate data in received message!');
        return;
      }
      
      print('🧊 Candidate data keys: ${candidateData.keys.join(", ")}');
      print('🧊 Candidate: ${candidateData['candidate']}');
      print('🧊 SDP MID: ${candidateData['sdpMid']}');
      print('🧊 SDP MLine Index: ${candidateData['sdpMLineIndex']}');
      
      // Create RTCIceCandidate from candidate data
      final candidate = webrtc.RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      
      print('🧊 Created RTCIceCandidate successfully');
      print('🧊 Candidate: ${candidate.candidate}');
      
      // Handle the ICE candidate
      print('🧊 Passing candidate to WebRTCService.handleIceCandidate()...');
      WebRTCService.handleIceCandidate(candidate);
      print('========================================');
      
    } catch (e, stackTrace) {
      print('❌ Error handling WebRTC ICE candidate: $e');
      print('❌ Stack trace: $stackTrace');
      print('========================================');
    }
  }

  // Accept incoming call
  void acceptIncomingCall(String callId) async {
    print('========================================');
    print('📞 === ACCEPTING INCOMING CALL ===');
    print('📞 Call ID: $callId');
    print('📞 Remote user: ${remoteUserId.value}');
    print('📞 Call type: ${callType.value}');
    
    try {
      // Hide incoming call notification
      IncomingCallNotificationManager.hideIncomingCall();
      print('📞 Incoming call notification hidden');
      
      // Send accept call via Socket.IO
      print('📞 Sending accept-call via Socket.IO...');
      SocketService.acceptCall(callId: callId);
      print('📞 Accept-call sent');
      
      // Initialize WebRTC for incoming call
      print('📞 Accepting incoming call with WebRTC...');
      bool webrtcInitialized = await WebRTCService.acceptIncomingCall(
        callId,
        _getCurrentUserId(),
        remoteUserId.value,
        callType: callType.value,
      );
      
      if (!webrtcInitialized) {
        print('❌ Failed to initialize WebRTC for incoming call');
        _showErrorSnackBar('Failed to start audio call');
        print('========================================');
        return;
      }
      print('✅ WebRTC incoming call accepted');
      
      // NOW process the pending offer (if any)
      if (_pendingOffer != null && _pendingOfferRoomId != null && _pendingOfferFromUserId != null) {
        print('========================================');
        print('📡 === PROCESSING PENDING OFFER ===');
        print('📡 User has accepted call - now processing stored offer');
        print('========================================');
        
        final offer = webrtc.RTCSessionDescription(
          _pendingOffer!['sdp'],
          _pendingOffer!['type'],
        );
        
        // Handle the offer NOW
        await WebRTCService.handleOffer(
          offer,
          _pendingOfferRoomId!,
          _pendingOfferFromUserId!,
          callType: callType.value,
        );
        
        // Clear pending offer
        _pendingOffer = null;
        _pendingOfferRoomId = null;
        _pendingOfferFromUserId = null;
        
        print('✅ Pending offer processed');
      } else {
        print('⚠️ No pending offer to process');
      }
      
      // Update call state
      callState.value = 'connected';
      isRinging.value = false;
      isConnected.value = true;
      isIncomingCall.value = false;
      print('📞 Call state updated to: connected');
      
      // Start call timer
      _startCallTimer();
      print('📞 Call timer started');
      
      // Navigate to call screen
      print('📞 Navigating to call screen...');
      Get.toNamed('/calling', arguments: {
        'user': {
          'uid': remoteUserId.value,
          'name': remoteUserName.value,
          'callType': callType.value,
        },
        'callType': callType.value,
        'isIncoming': true,
      });
      print('========================================');
      
    } catch (e, stackTrace) {
      print('❌ Error accepting call: $e');
      print('❌ Stack trace: $stackTrace');
      _showErrorSnackBar('Failed to accept call: $e');
      print('========================================');
    }
  }

  // Reject incoming call
  void rejectIncomingCall(String callId) {
    print('========================================');
    print('📞 === REJECTING INCOMING CALL ===');
    print('📞 Call ID: $callId');
    print('========================================');
    
    // Clear pending offer (important - prevents processing offer after rejection)
    if (_pendingOffer != null) {
      print('🗑️ Clearing pending offer (call rejected before acceptance)');
      _pendingOffer = null;
      _pendingOfferRoomId = null;
      _pendingOfferFromUserId = null;
    }
    
    // Hide incoming call notification
    IncomingCallNotificationManager.hideIncomingCall();
    
    // Send reject call via Socket.IO
    SocketService.rejectCall(callId: callId);
    
    // Update call state
    callState.value = 'ended';
    isRinging.value = false;
    isConnected.value = false;
    
    // Show rejection feedback
    Get.snackbar(
      'Call Rejected',
      'Call was rejected',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: AppColors.white,
      duration: const Duration(seconds: 2),
    );
    
    _cleanupCall();
  }

  // Initiate call to user
  void initiateCall(String targetUserId, String callType, String targetUserName) async {
    print('========================================');
    print('📞 === INITIATING OUTGOING CALL ===');
    print('📞 Target user: $targetUserId');
    print('📞 Target name: $targetUserName');
    print('📞 Call type: $callType');
    
    try {
      // Generate unique call ID
      String roomId = DateTime.now().millisecondsSinceEpoch.toString();
      callId.value = roomId;
      print('📞 Generated call ID: $roomId');
      
      // Update call state
      remoteUserId.value = targetUserId;
      remoteUserName.value = targetUserName;
      this.callType.value = callType;
      isIncomingCall.value = false;
      callState.value = 'calling';
      isRinging.value = true;
      print('📞 Call state updated to: calling');
      
      // Send call via Socket.IO
      print('📞 Sending call-user via Socket.IO...');
      SocketService.callUser(
        targetUserId: targetUserId,
        callType: callType,
      );
      print('📞 Call-user sent');
      
      // Initialize WebRTC for outgoing call
      print('📞 Starting WebRTC outgoing call...');
      bool webrtcInitialized = await WebRTCService.startOutgoingCall(
        roomId,
        _getCurrentUserId(),
        targetUserId,
        callType: callType,
      );
      
      if (!webrtcInitialized) {
        print('❌ Failed to initialize WebRTC for outgoing call');
        _showErrorSnackBar('Failed to start call');
        print('========================================');
        return;
      }
      print('✅ WebRTC outgoing call initialized');
      
      // Navigate to call screen
      print('📞 Navigating to call screen...');
      Get.toNamed('/calling', arguments: {
        'user': {
          'uid': targetUserId,
          'name': targetUserName,
        },
        'callType': callType,
        'isIncoming': false,
      });
      print('========================================');
      
    } catch (e, stackTrace) {
      print('❌ Error initiating call: $e');
      print('❌ Stack trace: $stackTrace');
      _showErrorSnackBar('Failed to initiate call: $e');
      print('========================================');
    }
  }

  // End current call
  void endCurrentCall() async {
    try {
      if (callId.value.isNotEmpty) {
        print('Ending call: ${callId.value}');
        SocketService.endCall(callId: callId.value);
      }
      
      // End WebRTC call
      await WebRTCService.endCall();
      
      // Update call state
      callState.value = 'ended';
      isRinging.value = false;
      isConnected.value = false;
      
      // Stop call timer
      _stopCallTimer();
      
      _cleanupCall();
      
    } catch (e) {
      print('❌ Error ending call: $e');
    }
  }

  // Toggle mute
  void toggleMute() {
    isMuted.value = !isMuted.value;
    print('========================================');
    print('🎤 User toggled mute: ${isMuted.value ? "MUTED" : "UNMUTED"}');
    print('========================================');
    
    // Toggle audio track in WebRTC service
    WebRTCService.toggleAudio(!isMuted.value);
  }

  // Toggle video
  void toggleVideo() {
    isVideoEnabled.value = !isVideoEnabled.value;
    print('========================================');
    print('📹 User toggled video: ${isVideoEnabled.value ? "ENABLED" : "DISABLED"}');
    print('========================================');
    
    // Toggle video track in WebRTC service
    WebRTCService.toggleVideo(isVideoEnabled.value);
  }

  // Debug method to check WebRTC status
  void checkWebRTCStatus() {
    final status = WebRTCService.getConnectionStatus();
    print('🔍 WebRTC Status: $status');
  }

  // Debug method to process queued ICE candidates
  void processQueuedIceCandidates() {
    WebRTCService.processQueuedIceCandidates();
  }

  // Toggle speaker
  void toggleSpeaker() {
    isSpeakerEnabled.value = !isSpeakerEnabled.value;
    print('Speaker ${isSpeakerEnabled.value ? 'enabled' : 'disabled'}');
    // TODO: Implement actual speaker toggle functionality
  }

  // Start call timer
  void _startCallTimer() {
    _callStartTime = DateTime.now();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStartTime != null) {
        final duration = DateTime.now().difference(_callStartTime!);
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        callDuration.value = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    });
  }

  // Stop call timer
  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
    _callStartTime = null;
    callDuration.value = '00:00';
  }


  // Cleanup call resources
  void _cleanupCall() {
    print('========================================');
    print('🧹 === CLEANING UP CALL RESOURCES ===');
    print('========================================');
    
    // Clear pending offer (important!)
    if (_pendingOffer != null) {
      print('🗑️ Clearing pending offer during cleanup');
      _pendingOffer = null;
      _pendingOfferRoomId = null;
      _pendingOfferFromUserId = null;
    }
    
    // Hide any incoming call notifications
    IncomingCallNotificationManager.hideIncomingCall();
    
    // Reset all call state
    callState.value = 'idle';
    isRinging.value = false;
    isConnected.value = false;
    isMuted.value = false;
    isVideoEnabled.value = true;
    isSpeakerEnabled.value = false;
    callDuration.value = '00:00';
    remoteUserId.value = '';
    callId.value = '';
    remoteUserName.value = '';
    callType.value = 'audio';
    isIncomingCall.value = false;
    
    // Stop timer
    _stopCallTimer();
    
    print('✅ Call cleanup complete');
    print('========================================');
    
    // Navigate back to users list
    Get.offAllNamed('/users-list');
  }

  // Manage WebRTC call state (connected, disconnected, ringing)
  // void updateCallState(CallState state) {}
  
  // Handle local and remote streams
  // void setLocalStream(MediaStream stream) {}
  // void setRemoteStream(MediaStream stream) {}
  
  // Integrate with Socket.io for signaling
  // void initializeSocketConnection() {}
  // void sendOffer(String offer) {}
  // void sendAnswer(String answer) {}
  // void sendIceCandidate(String candidate) {}
  
  // Control mic, camera, and speaker
  // void toggleMute() {}
  // void toggleVideo() {}
  // void toggleSpeaker() {}
  
  // Manage call timers and cleanup
  // void startCallTimer() {}
  // void stopCallTimer() {}
  // void updateCallDuration() {}
  
  // Initiate call
  // void initiateCall(String userId) {}
  
  // Accept incoming call
  // void acceptCall() {}
  
  // Reject call
  // void rejectCall() {}
  
  // End call
  // void endCall() {}
  
  // Handle call cleanup
  // void cleanupCall() {}
  
  // Handle WebRTC connection events
  // void onConnectionStateChange() {}
  // void onIceCandidate() {}
  // void onAddStream() {}

  // Helper Methods

  /// Initialize WebRTC service
  void _initializeWebRTC() async {
    try {
      print('🎤 Initializing WebRTC service...');
      bool initialized = await WebRTCService.initialize();
      if (initialized) {
        print('✅ WebRTC service initialized');
        _setupWebRTCCallbacks();
      } else {
        print('❌ Failed to initialize WebRTC service');
      }
    } catch (e) {
      print('❌ Error initializing WebRTC: $e');
    }
  }
  
  

  /// Setup WebRTC callbacks
  void _setupWebRTCCallbacks() {
    WebRTCService.onCallConnected = () {
      print('✅ WebRTC call connected');
      callState.value = 'connected';
      isConnected.value = true;
      isRinging.value = false;
    };

    WebRTCService.onCallDisconnected = () {
      print('❌ WebRTC call disconnected');
      callState.value = 'ended';
      isConnected.value = false;
      isRinging.value = false;
    };

    WebRTCService.onCallError = (String error) {
      print('❌ WebRTC call error: $error');
      _showErrorSnackBar('Call error: $error');
    };
  }

  /// Get current user ID
  String _getCurrentUserId() {
    // This should return the current user's ID
    // You might need to get this from your auth service
    return 'current_user_id'; // Replace with actual user ID
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}
