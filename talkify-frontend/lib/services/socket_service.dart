import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_service.dart';
import '../core/config.dart';

/// Socket.IO Service for real-time communication
/// Handles call signaling and real-time events
/// Connects to Node.js backend with JWT authentication
class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  static String? _jwtToken;
  static String? _currentUserId;
  
  // Event callbacks for call signaling
  static Function(Map<String, dynamic>)? onIncomingCall;
  static Function(Map<String, dynamic>)? onCallUser;
  static Function(Map<String, dynamic>)? onCallAccepted;
  static Function(Map<String, dynamic>)? onCallRejected;
  static Function(Map<String, dynamic>)? onCallEnded;
  static Function(Map<String, dynamic>)? onCallOffer;
  static Function(Map<String, dynamic>)? onCallAnswer;
  static Function(Map<String, dynamic>)? onIceCandidate;
  static Function(Map<String, dynamic>)? onCallStateChange;
  
  // WebRTC signaling callbacks
  static Function(Map<String, dynamic>)? onWebRTCOffer;
  static Function(Map<String, dynamic>)? onWebRTCAnswer;
  static Function(Map<String, dynamic>)? onWebRTCIceCandidate;
  
  // Event callbacks for connection status
  static Function(String)? onConnectionStatusChanged;
  static Function(Map<String, dynamic>)? onUserOnline;
  static Function(Map<String, dynamic>)? onUserOffline;
  
  // Event callbacks for messages (if needed)
  static Function(Map<String, dynamic>)? onMessageReceived;
  static Function(Map<String, dynamic>)? onUserTyping;
  
  /// Initialize Socket.IO connection
  static Future<void> initializeSocket() async {
    try {
      print('🔌 Initializing Socket.IO connection');
      
      // Get JWT token
      _jwtToken = await ApiService.getJwtToken();
      if (_jwtToken == null) {
        print('❌ No JWT token found. Please login first.');
        return;
      }
      
      // Get current user info
      final userInfo = await ApiService.getUserInfo();
      _currentUserId = userInfo?['uid'];
      
      print('🔑 JWT token: ${_jwtToken?.substring(0, 20)}...');
      print('👤 Current user: $_currentUserId');
      
      // Create socket connection with proper authentication
      _socket = IO.io(
        AppConfig.socketBaseUrl,
        IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': _jwtToken}) // Backend expects token in auth object
          .enableAutoConnect()
          .setTimeout(20000)
          .build(),
      );
      
      _setupEventListeners();
      print('✅ Socket.IO initialized successfully');
      
    } catch (e) {
      print('❌ Socket.IO initialization failed: $e');
    }
  }
  
  /// Setup event listeners
  static void _setupEventListeners() {
    if (_socket == null) return;
    
    // Connection events
    _socket!.onConnect((_) {
      print('✅ Socket.IO connected to backend');
      _isConnected = true;
      onConnectionStatusChanged?.call('connected');
    });
    
    _socket!.onDisconnect((_) {
      print('❌ Socket.IO disconnected from backend');
      _isConnected = false;
      onConnectionStatusChanged?.call('disconnected');
    });
    
    _socket!.onConnectError((error) {
      print('❌ Socket.IO connection error: $error');
      _isConnected = false;
      onConnectionStatusChanged?.call('error');
    });
    
    // Backend connection confirmation
    _socket!.on('connected', (data) {
      print('🔗 Backend connection confirmed: $data');
    });
    
    // User presence events
    _socket!.on('user-online', (data) {
      print('👤 User came online: $data');
      onUserOnline?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('user-offline', (data) {
      print('👤 User went offline: $data');
      onUserOffline?.call(Map<String, dynamic>.from(data));
    });
    
    // Call signaling events (matching backend events)
    _socket!.on('incoming-call', (data) {
      print('📞 Incoming call: $data');
      onIncomingCall?.call(Map<String, dynamic>.from(data));
    });
    
    // Call-user event (when someone calls you)
    _socket!.on('call-user', (data) {
      print('📞 Call-user event received: $data');
      onCallUser?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('call-initiated', (data) {
      print('📞 Call initiated: $data');
    });
    
    _socket!.on('call-accepted', (data) {
      print('✅ Call accepted: $data');
      onCallAccepted?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('call-rejected', (data) {
      print('❌ Call rejected: $data');
      onCallRejected?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('call-ended', (data) {
      print('📞 Call ended: $data');
      onCallEnded?.call(Map<String, dynamic>.from(data));
    });
    
    // WebRTC signaling events
    _socket!.on('call-offer', (data) {
      print('📡 WebRTC offer received: $data');
      onCallOffer?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('call-answer', (data) {
      print('📡 WebRTC answer received: $data');
      onCallAnswer?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('ice-candidate', (data) {
      print('🧊 ICE candidate received: $data');
      onIceCandidate?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('call-state-change', (data) {
      print('🔄 Call state changed: $data');
      onCallStateChange?.call(Map<String, dynamic>.from(data));
    });
    
    // WebRTC signaling events
    _socket!.on('call-offer', (data) {
      print('========================================');
      print('📥 === WEBRTC OFFER RECEIVED ===');
      print('📥 Raw data: $data');
      final offerData = Map<String, dynamic>.from(data);
      print('📥 Parsed data keys: ${offerData.keys.join(", ")}');
      print('📥 From user: ${offerData['from'] ?? offerData['callerId'] ?? "UNKNOWN"}');
      print('📥 Room ID: ${offerData['roomId'] ?? offerData['callId'] ?? "UNKNOWN"}');
      print('📥 Offer present: ${offerData['offer'] != null ? "YES" : "NO"}');
      print('========================================');
      onWebRTCOffer?.call(offerData);
    });
    
    _socket!.on('call-answer', (data) {
      print('========================================');
      print('📥 === WEBRTC ANSWER RECEIVED ===');
      print('📥 Raw data: $data');
      final answerData = Map<String, dynamic>.from(data);
      print('📥 Parsed data keys: ${answerData.keys.join(", ")}');
      print('📥 From user: ${answerData['from'] ?? answerData['calleeId'] ?? "UNKNOWN"}');
      print('📥 Room ID: ${answerData['roomId'] ?? answerData['callId'] ?? "UNKNOWN"}');
      print('📥 Answer present: ${answerData['answer'] != null ? "YES" : "NO"}');
      print('========================================');
      onWebRTCAnswer?.call(answerData);
    });
    
    _socket!.on('ice-candidate', (data) {
      print('========================================');
      print('📥 === WEBRTC ICE CANDIDATE RECEIVED ===');
      print('📥 Raw data: $data');
      final candidateData = Map<String, dynamic>.from(data);
      print('📥 Parsed data keys: ${candidateData.keys.join(", ")}');
      print('📥 From user: ${candidateData['senderId'] ?? candidateData['from'] ?? "UNKNOWN"}');
      print('📥 Candidate present: ${candidateData['candidate'] != null ? "YES" : "NO"}');
      print('========================================');
      onWebRTCIceCandidate?.call(candidateData);
    });
    
    // Message events (if needed)
    _socket!.on('message-received', (data) {
      print('💬 Message received: $data');
      onMessageReceived?.call(Map<String, dynamic>.from(data));
    });
    
    _socket!.on('user-typing', (data) {
      print('⌨️ User typing: $data');
      onUserTyping?.call(Map<String, dynamic>.from(data));
    });
    
    // Error handling
    _socket!.onError((error) {
      print('❌ Socket.IO error: $error');
    });
    
    _socket!.on('call-error', (data) {
      print('❌ Call error: $data');
    });
    
    _socket!.on('call-failed', (data) {
      print('❌ Call failed: $data');
    });
  }
  
  /// Connect to Socket.IO server
  static Future<void> connect() async {
    try {
      if (_socket == null) {
        await initializeSocket();
      }
      
      if (_socket != null && !_isConnected) {
        _socket!.connect();
        print('🔄 Attempting to connect to Socket.IO server');
      }
      
    } catch (e) {
      print('❌ Failed to connect to Socket.IO: $e');
    }
  }
  
  /// Disconnect from Socket.IO server
  static void disconnect() {
    try {
      if (_socket != null) {
        _socket!.disconnect();
        _isConnected = false;
        print('🔌 Disconnected from Socket.IO server');
      }
    } catch (e) {
      print('❌ Error disconnecting from Socket.IO: $e');
    }
  }
  
  /// Check if connected
  static bool get isConnected => _isConnected;
  
  /// Get connection status with details
  static Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': _isConnected,
      'socketExists': _socket != null,
      'jwtToken': _jwtToken != null,
      'currentUserId': _currentUserId,
    };
  }
  
  /// Ensure CallController is initialized and connected to Socket.IO events
  static void ensureCallControllerInitialized() {
    try {
      // This will be handled by the calling code
      print('✅ CallController initialization check');
    } catch (e) {
      print('⚠️ CallController not found, initializing...');
      // This will be handled by the calling code
    }
  }
  
  /// Emit call-user event (initiate call)
  static void callUser({
    required String targetUserId,
    required String callType, // 'audio' or 'video'
    String? roomId,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot make call.');
      return;
    }
    
    try {
      final callData = {
        'to': targetUserId,
        'callType': callType,
        if (roomId != null) 'roomId': roomId,
      };
      
      _socket!.emit('call-user', callData);
      print('📞 Call initiated to user: $targetUserId ($callType)');
      
    } catch (e) {
      print('❌ Error initiating call: $e');
    }
  }
  
  /// Emit accept-call event
  static void acceptCall({
    required String callId,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot accept call.');
      return;
    }
    
    try {
      final acceptData = {
        'callId': callId,
      };
      
      _socket!.emit('accept-call', acceptData);
      print('✅ Call accepted: $callId');
      
    } catch (e) {
      print('❌ Error accepting call: $e');
    }
  }
  
  /// Emit reject-call event
  static void rejectCall({
    required String callId,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot reject call.');
      return;
    }
    
    try {
      final rejectData = {
        'callId': callId,
      };
      
      _socket!.emit('reject-call', rejectData);
      print('❌ Call rejected: $callId');
      
    } catch (e) {
      print('❌ Error rejecting call: $e');
    }
  }
  
  /// Emit end-call event
  static void endCall({
    required String callId,
    String? reason,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot end call.');
      return;
    }
    
    try {
      final endData = {
        'callId': callId,
        if (reason != null) 'reason': reason,
      };
      
      _socket!.emit('end-call', endData);
      print('📞 Call ended: $callId');
      
    } catch (e) {
      print('❌ Error ending call: $e');
    }
  }
  
  /// Emit WebRTC call offer
  static void sendCallOffer({
    required String callId,
    required Map<String, dynamic> offer,
    required String targetUserId,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot send offer.');
      return;
    }
    
    try {
      final offerData = {
        'callId': callId,
        'offer': offer,
        'to': targetUserId,
      };
      
      _socket!.emit('call-offer', offerData);
      print('📡 WebRTC offer sent: $callId');
      
    } catch (e) {
      print('❌ Error sending offer: $e');
    }
  }
  
  /// Emit WebRTC call answer
  static void sendCallAnswer({
    required String callId,
    required Map<String, dynamic> answer,
    required String targetUserId,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot send answer.');
      return;
    }
    
    try {
      final answerData = {
        'callId': callId,
        'answer': answer,
        'to': targetUserId,
      };
      
      _socket!.emit('call-answer', answerData);
      print('📡 WebRTC answer sent: $callId');
      
    } catch (e) {
      print('❌ Error sending answer: $e');
    }
  }
  
  /// Emit ICE candidate
  static void sendIceCandidate({
    required String callId,
    required String targetUserId,
    required Map<String, dynamic> candidate,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot send ICE candidate.');
      return;
    }
    
    try {
      final iceData = {
        'callId': callId,
        'to': targetUserId,
        'candidate': candidate,
      };
      
      _socket!.emit('ice-candidate', iceData);
      print('🧊 ICE candidate sent: $callId → $targetUserId');
      
    } catch (e) {
      print('❌ Error sending ICE candidate: $e');
    }
  }
  
  /// Emit call state change
  static void sendCallStateChange({
    required String callId,
    required String state,
    required String targetUserId,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot send state change.');
      return;
    }
    
    try {
      final stateData = {
        'callId': callId,
        'state': state,
        'to': targetUserId,
      };
      
      _socket!.emit('call-state-change', stateData);
      print('🔄 Call state changed: $callId → $state');
      
    } catch (e) {
      print('❌ Error sending state change: $e');
    }
  }

  // WebRTC Signaling Methods

  /// Send WebRTC offer
  static void sendWebRTCOffer({
    required String roomId,
    required String toUserId,
    required dynamic offer,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot send WebRTC offer.');
      return;
    }
    
    try {
      print('========================================');
      print('📤 === EMITTING WEBRTC OFFER ===');
      print('📤 Room ID: $roomId');
      print('📤 To user: $toUserId');
      print('📤 Offer type: ${offer.type}');
      
      final offerData = {
        'roomId': roomId,
        'to': toUserId,
        'offer': offer.toMap(),
      };
      
      print('📤 Full offer data being emitted:');
      print('📤 ${offerData.toString().substring(0, 300)}...');
      
      _socket!.emit('call-offer', offerData);
      print('✅ WebRTC offer emitted successfully to: $toUserId');
      print('========================================');
      
    } catch (e) {
      print('❌ Error sending WebRTC offer: $e');
    }
  }

  /// Send WebRTC answer
  static void sendWebRTCAnswer({
    required String roomId,
    required String toUserId,
    required dynamic answer,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot send WebRTC answer.');
      return;
    }
    
    try {
      print('========================================');
      print('📤 === EMITTING WEBRTC ANSWER ===');
      print('📤 Room ID: $roomId');
      print('📤 To user: $toUserId');
      print('📤 Answer type: ${answer.type}');
      
      final answerData = {
        'roomId': roomId,
        'to': toUserId,
        'answer': answer.toMap(),
      };
      
      print('📤 Full answer data being emitted:');
      print('📤 ${answerData.toString().substring(0, 300)}...');
      
      _socket!.emit('call-answer', answerData);
      print('✅ WebRTC answer emitted successfully to: $toUserId');
      print('========================================');
      
    } catch (e) {
      print('❌ Error sending WebRTC answer: $e');
    }
  }

  /// Send WebRTC ICE candidate
  static void sendWebRTCIceCandidate({
    required String roomId,
    required String toUserId,
    required dynamic candidate,
  }) {
    if (_socket == null || !_isConnected) {
      print('❌ Socket not connected. Cannot send WebRTC ICE candidate.');
      return;
    }
    
    try {
      print('========================================');
      print('📤 === EMITTING WEBRTC ICE CANDIDATE ===');
      print('📤 Room ID: $roomId');
      print('📤 To user: $toUserId');
      
      final candidateData = {
        'roomId': roomId,
        'to': toUserId,
        'candidate': candidate.toMap(),
      };
      
      print('📤 Candidate data: ${candidateData['candidate']}');
      
      _socket!.emit('ice-candidate', candidateData);
      print('✅ WebRTC ICE candidate emitted successfully to: $toUserId');
      print('========================================');
      
    } catch (e) {
      print('❌ Error sending WebRTC ICE candidate: $e');
    }
  }
  
  /// Reconnect with new JWT token
  static Future<void> reconnectWithNewToken() async {
    try {
      print('🔄 Reconnecting with new JWT token');
      
      // Disconnect current connection
      disconnect();
      
      // Wait a bit
      await Future.delayed(const Duration(seconds: 1));
      
      // Reinitialize with new token
      await initializeSocket();
      await connect();
      
    } catch (e) {
      print('❌ Error reconnecting with new token: $e');
    }
  }
  
  /// Cleanup resources
  static void dispose() {
    try {
      disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      print('🧹 Socket.IO service disposed');
    } catch (e) {
      print('❌ Error disposing Socket.IO service: $e');
    }
  }
}
