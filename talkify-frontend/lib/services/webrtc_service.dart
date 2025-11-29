import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'socket_service.dart';

/// WebRTC Service for Audio/Video Calling
class WebRTCService {
  static webrtc.RTCPeerConnection? _peerConnection;
  static webrtc.MediaStream? _localStream;
  static webrtc.MediaStream? _remoteStream;
  static webrtc.RTCVideoRenderer? _localRenderer;
  static webrtc.RTCVideoRenderer? _remoteRenderer;
  static String? _currentRoomId;
  static String? _remoteUserId;
  
  // ICE candidate queue for timing issues
  static final List<webrtc.RTCIceCandidate> _iceCandidateQueue = [];
  static bool _isPeerConnectionReady = false;
  
  // Callbacks
  static Function(webrtc.MediaStream)? onLocalStream;
  static Function(webrtc.MediaStream)? onRemoteStream;
  static Function()? onCallConnected;
  static Function()? onCallDisconnected;
  static Function(String)? onCallError;

  /// Initialize WebRTC service
  static Future<bool> initialize() async {
    try {
      print('🎤 Initializing WebRTC service...');
      
      // Initialize renderers
      _localRenderer = webrtc.RTCVideoRenderer();
      _remoteRenderer = webrtc.RTCVideoRenderer();
      
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();
      
      print('✅ WebRTC service initialized successfully');
      return true;
    } catch (e) {
      print('❌ Failed to initialize WebRTC service: $e');
      return false;
    }
  }

  /// Check and request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    try {
      print('========================================');
      print('🎤 === REQUESTING MICROPHONE PERMISSION ===');
      print('========================================');
      
      // Check current permission status
      PermissionStatus status = await Permission.microphone.status;
      print('🎤 Current microphone permission status: $status');
      
      if (status.isGranted) {
        print('✅ ✅ ✅ Microphone permission ALREADY GRANTED');
        print('========================================');
        return true;
      }
      
      if (status.isDenied) {
        print('⚠️ Microphone permission is DENIED - requesting now...');
        
        // Request permission
        status = await Permission.microphone.request();
        print('🎤 After request, permission status: $status');
        
        if (status.isGranted) {
          print('✅ ✅ ✅ Microphone permission GRANTED by user');
          print('========================================');
          return true;
        } else if (status.isDenied) {
          print('❌ ❌ ❌ User DENIED microphone permission');
          print('========================================');
          _showPermissionDeniedDialog();
          return false;
        } else if (status.isPermanentlyDenied) {
          print('❌ ❌ ❌ User PERMANENTLY DENIED microphone permission');
          print('========================================');
          _showPermissionPermanentlyDeniedDialog();
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        print('❌ ❌ ❌ Microphone permission is PERMANENTLY DENIED');
        print('🔧 User must enable in device Settings → App Permissions → Microphone');
        print('========================================');
        _showPermissionPermanentlyDeniedDialog();
        return false;
      }
      
      if (status.isRestricted) {
        print('❌ Microphone permission is RESTRICTED (parental controls?)');
        print('========================================');
        return false;
      }
      
      print('⚠️ Unknown permission status: $status');
      print('========================================');
      return false;
    } catch (e) {
      print('❌ ❌ ❌ ERROR requesting microphone permission: $e');
      print('Stack trace: ${StackTrace.current}');
      print('========================================');
      return false;
    }
  }

  /// Check and request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      print('========================================');
      print('📹 === REQUESTING CAMERA PERMISSION ===');
      print('========================================');
      
      PermissionStatus status = await Permission.camera.status;
      print('📹 Current camera permission status: $status');
      
      if (status.isGranted) {
        print('✅ ✅ ✅ Camera permission ALREADY GRANTED');
        print('========================================');
        return true;
      }
      
      if (status.isDenied) {
        print('⚠️ Camera permission is DENIED - requesting now...');
        status = await Permission.camera.request();
        print('📹 After request, permission status: $status');
        
        if (status.isGranted) {
          print('✅ ✅ ✅ Camera permission GRANTED by user');
          print('========================================');
          return true;
        } else if (status.isDenied) {
          print('❌ ❌ ❌ User DENIED camera permission');
          print('========================================');
          _showPermissionDeniedDialog();
          return false;
        } else if (status.isPermanentlyDenied) {
          print('❌ ❌ ❌ User PERMANENTLY DENIED camera permission');
          print('========================================');
          _showPermissionPermanentlyDeniedDialog();
          return false;
        }
      }
      
      if (status.isPermanentlyDenied) {
        print('❌ ❌ ❌ Camera permission is PERMANENTLY DENIED');
        print('🔧 User must enable in device Settings → App Permissions → Camera');
        print('========================================');
        _showPermissionPermanentlyDeniedDialog();
        return false;
      }
      
      if (status.isRestricted) {
        print('❌ Camera permission is RESTRICTED (parental controls?)');
        print('========================================');
        return false;
      }
      
      print('⚠️ Unknown permission status: $status');
      print('========================================');
      return false;
    } catch (e) {
      print('❌ ❌ ❌ ERROR requesting camera permission: $e');
      print('Stack trace: ${StackTrace.current}');
      print('========================================');
      return false;
    }
  }

  /// Start local media stream (audio/video based on call type)
  static Future<webrtc.MediaStream?> startLocalStream({String callType = 'audio'}) async {
    try {
      print('========================================');
      print('🎤 === STARTING LOCAL MEDIA STREAM ===');
      print('🎤 Call type: $callType');
      print('========================================');
      
      // Request microphone permission first - CRITICAL: Must succeed before getUserMedia
      bool hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        print('========================================');
        print('❌ ❌ ❌ CANNOT START CALL: Microphone permission NOT granted');
        print('========================================');
        onCallError?.call('Microphone permission denied. Please enable microphone access in Settings.');
        return null;
      }
      
      print('========================================');
      print('✅ ✅ ✅ Microphone permission confirmed GRANTED');
      print('========================================');
      
      // Request camera permission for video calls - CRITICAL: Must succeed before getUserMedia
      bool hasVideoPermission = true;
      if (callType == 'video') {
        hasVideoPermission = await requestCameraPermission();
        if (!hasVideoPermission) {
          print('========================================');
          print('❌ ❌ ❌ CANNOT START VIDEO CALL: Camera permission NOT granted');
          print('========================================');
          onCallError?.call('Camera permission denied. Please enable camera access in Settings.');
          return null;
        }
        
        print('========================================');
        print('✅ ✅ ✅ Camera permission confirmed GRANTED');
        print('========================================');
      }
      
      // Get user media based on call type
      Map<String, dynamic> mediaConstraints = {
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': 44100,
        },
        'video': callType == 'video' ? {
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
          'frameRate': {'ideal': 30},
          'facingMode': 'user', // Front camera
        } : false,
      };
      
      print('🎤 Media constraints:');
      print('🎤 - Audio: ENABLED');
      print('📹 - Video: ${callType == 'video' ? "ENABLED" : "DISABLED"}');
      if (callType == 'video') {
        print('📹 - Video constraints: 1280x720@30fps, front camera');
      }
      
      print('========================================');
      print('🎤 === CALLING getUserMedia() ===');
      print('🎤 This will access the microphone and camera');
      print('🎤 Permissions have been confirmed as granted');
      print('========================================');
      
      try {
        _localStream = await webrtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
      } catch (e) {
        print('========================================');
        print('❌ ❌ ❌ getUserMedia() FAILED');
        print('❌ Error: $e');
        print('❌ This usually means:');
        print('   1. Permissions were revoked after granting');
        print('   2. Device does not have camera/microphone');
        print('   3. Camera/microphone is in use by another app');
        print('========================================');
        onCallError?.call('Failed to access camera/microphone: $e');
        return null;
      }
      
      if (_localStream != null) {
        print('========================================');
        print('✅ ✅ ✅ LOCAL MEDIA STREAM STARTED SUCCESSFULLY');
        print('========================================');
        print('🔊 Stream ID: ${_localStream!.id}');
        print('🔊 Total tracks: ${_localStream!.getTracks().length}');
        
        int audioTracks = 0;
        int videoTracks = 0;
        
        for (var track in _localStream!.getTracks()) {
          if (track.kind == 'audio') audioTracks++;
          if (track.kind == 'video') videoTracks++;
          
          print('========================================');
          print('🔊 Track ${track.kind?.toUpperCase()}:');
          print('🔊 - ID: ${track.id}');
          print('🔊 - Label: ${track.label}');
          print('🔊 - Enabled: ${track.enabled}');
          print('🔊 - Muted: ${track.muted}');
          print('🔊 - Ready State: ${track.label}');
          print('========================================');
          
          // Set up track event listeners
          track.onEnded = () {
            print('⚠️ ⚠️ ⚠️ Local ${track.kind} track ENDED!');
            onCallError?.call('Local ${track.kind} track ended');
          };
          
          track.onMute = () {
            print('⚠️ Local ${track.kind} track MUTED');
          };
          
          track.onUnMute = () {
            print('✅ Local ${track.kind} track UNMUTED');
          };
        }
        
        print('📊 Summary:');
        print('📊 - Audio tracks: $audioTracks');
        print('📊 - Video tracks: $videoTracks');
        print('📊 - Expected: Audio=1, Video=${callType == 'video' ? '1' : '0'}');
        
        if (audioTracks == 0) {
          print('❌ WARNING: No audio tracks found!');
        }
        
        if (callType == 'video' && videoTracks == 0) {
          print('❌ WARNING: Video call requested but no video tracks found!');
        }
        
        print('========================================');
        
        // Set local stream to local renderer
        if (_localRenderer != null) {
          print('📹 === SETTING LOCAL STREAM TO LOCAL RENDERER ===');
          _localRenderer!.srcObject = _localStream;
          print('📹 Local renderer srcObject: ${_localRenderer!.srcObject != null ? "SUCCESS" : "FAILED"}');
          
          if (_localRenderer!.srcObject != null) {
            print('✅ ✅ ✅ Local video preview is ready!');
          } else {
            print('❌ Failed to set local stream to renderer');
          }
        } else {
          print('⚠️ Local renderer is null - local preview not available');
        }
        
        // Monitor stream health
        _monitorStreamHealth();
        
        print('📞 Calling onLocalStream callback...');
        onLocalStream?.call(_localStream!);
        print('========================================');
        return _localStream;
      } else {
        print('❌ ❌ ❌ Failed to start local media stream');
        onCallError?.call('Failed to start local media stream');
        return null;
      }
    } catch (e) {
      print('❌ Error starting local audio stream: $e');
      onCallError?.call('Failed to start audio: $e');
      return null;
    }
  }

  /// Create peer connection
  static Future<webrtc.RTCPeerConnection?> createPeerConnection({String callType = 'audio'}) async {
  try {
    print('🔗 Creating peer connection for $callType call...');

    // ✅ Correct configuration as Map
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
        {'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'iceCandidatePoolSize': 10,
    };

    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': callType == 'video',
      },
      'optional': [],
    };

    _peerConnection = await webrtc.createPeerConnection(configuration, constraints);
    
    if (_peerConnection == null) {
      print('❌ Failed to create peer connection - returned null');
      return null;
    }
    
    print('✅ Peer connection created successfully');
    
    // Mark peer connection as ready and process queued ICE candidates
    _isPeerConnectionReady = true;
    _processQueuedIceCandidates();

    // Set up event handlers
    _peerConnection!.onIceCandidate = (webrtc.RTCIceCandidate candidate) {
      print('🧊 === ICE CANDIDATE GENERATED ===');
      print('🧊 Candidate: ${candidate.candidate}');
      print('🧊 SDP MID: ${candidate.sdpMid}');
      print('🧊 SDP MLine Index: ${candidate.sdpMLineIndex}');
      print('🧊 Sending to remote peer...');
      _sendIceCandidate(candidate);
      print('🧊 ICE candidate sent');
    };

    _peerConnection!.onTrack = (webrtc.RTCTrackEvent event) async {
      print('========================================');
      print('📺 === REMOTE TRACK EVENT RECEIVED ===');
      print('========================================');
      print('📺 Track kind: ${event.track.kind}');
      print('📺 Track ID: ${event.track.id}');
      print('📺 Track label: ${event.track.label}');
      print('📺 Track enabled: ${event.track.enabled}');
      print('📺 Track muted: ${event.track.muted}');
      print('📺 Track readyState: ${event.track.label}');
      print('📺 Event streams count: ${event.streams.length}');
      
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        print('🔊 === REMOTE STREAM RECEIVED ===');
        print('🔊 Stream ID: ${_remoteStream!.id}');
        print('🔊 Total tracks in remote stream: ${_remoteStream!.getTracks().length}');
        
        // Log all tracks in detail
        int trackIndex = 0;
        for (var track in _remoteStream!.getTracks()) {
          trackIndex++;
          print('🔊 --- Track #$trackIndex ---');
          print('🔊 Kind: ${track.kind}');
          print('🔊 ID: ${track.id}');
          print('🔊 Label: ${track.label}');
          print('🔊 Enabled: ${track.enabled}');
          print('🔊 Muted: ${track.muted}');
          
          // Handle audio tracks
          if (track.kind == 'audio') {
            track.enabled = true;
            print('🔊 ✅ Remote AUDIO track force-enabled: ${track.enabled}');
            
            // Set up track event listeners
            track.onEnded = () {
              print('⚠️ ⚠️ ⚠️ Remote audio track ENDED!');
            };
            track.onMute = () {
              print('⚠️ Remote audio track MUTED');
            };
            track.onUnMute = () {
              print('✅ Remote audio track UNMUTED');
            };
          }
          
          // Handle video tracks
          if (track.kind == 'video') {
            track.enabled = true;
            print('📹 ✅ Remote VIDEO track force-enabled: ${track.enabled}');
            
            // Set up track event listeners
            track.onEnded = () {
              print('⚠️ ⚠️ ⚠️ Remote video track ENDED!');
            };
            track.onMute = () {
              print('⚠️ Remote video track MUTED');
            };
            track.onUnMute = () {
              print('✅ Remote video track UNMUTED');
            };
          }
        }
        
        // Set the remote stream to the renderer
        print('🔊 === SETTING REMOTE STREAM TO RENDERER ===');
        if (_remoteRenderer != null) {
          print('🔊 Remote renderer exists, setting srcObject...');
          _remoteRenderer!.srcObject = _remoteStream;
          print('🔊 srcObject assignment result: ${_remoteRenderer!.srcObject != null ? "SUCCESS" : "FAILED"}');
          
          if (_remoteRenderer!.srcObject != null) {
            print('✅ ✅ ✅ Remote stream successfully set to renderer!');
            print('🔊 Renderer stream ID: ${_remoteRenderer!.srcObject?.id ?? "N/A"}');
          } else {
            print('❌ ❌ ❌ CRITICAL: Failed to set srcObject on first attempt!');
            print('🔄 Retrying in 100ms...');
            Future.delayed(const Duration(milliseconds: 100), () {
              _remoteRenderer!.srcObject = _remoteStream;
              print('🔄 Retry result: ${_remoteRenderer!.srcObject != null ? "SUCCESS" : "FAILED"}');
            });
          }
        } else {
          print('❌ CRITICAL: Remote renderer is null!');
          print('🔄 Initializing new renderer...');
          _remoteRenderer = webrtc.RTCVideoRenderer();
          await _remoteRenderer!.initialize();
          _remoteRenderer!.srcObject = _remoteStream;
          print('🔄 New renderer initialized and stream set: ${_remoteRenderer!.srcObject != null ? "SUCCESS" : "FAILED"}');
        }
        
        print('📞 Calling onRemoteStream callback...');
        onRemoteStream?.call(_remoteStream!);
        print('========================================');
      } else {
        print('❌ ❌ ❌ CRITICAL: No streams in track event!');
        print('========================================');
      }
    };

    _peerConnection!.onConnectionState = (webrtc.RTCPeerConnectionState state) {
      print('🔗 Connection state: $state');
      switch (state) {
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          print('✅ WebRTC connection established');
          onCallConnected?.call();
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
          print('⚠️ WebRTC connection disconnected - attempting to reconnect');
          // Don't immediately call onCallDisconnected for disconnected state
          // as it might be temporary
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          print('❌ WebRTC connection failed');
          onCallError?.call('Connection failed');
          onCallDisconnected?.call();
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          print('🔒 WebRTC connection closed');
          onCallDisconnected?.call();
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
          print('🔄 WebRTC connection connecting...');
          break;
        case webrtc.RTCPeerConnectionState.RTCPeerConnectionStateNew:
          print('🆕 WebRTC connection new');
          break;
      }
    };

    print('✅ Peer connection created');
    return _peerConnection;
  } catch (e) {
    print('❌ Error creating peer connection: $e');
    onCallError?.call('Failed to create connection: $e');
    return null;
  }
}


  /// Start outgoing call
  static Future<bool> startOutgoingCall(String roomId, String userId, String remoteUserId, {String callType = 'audio'}) async {
    try {
      print('📞 Starting outgoing call to $remoteUserId in room $roomId');
      
      _currentRoomId = roomId;
      _remoteUserId = remoteUserId;
      
      // Reset ICE candidate queue for new call
      _iceCandidateQueue.clear();
      _isPeerConnectionReady = false;
      
      // Initialize renderers if not already done
      if (_localRenderer == null) {
        _localRenderer = webrtc.RTCVideoRenderer();
        await _localRenderer!.initialize();
        print('✅ Local renderer initialized');
      }
      
      if (_remoteRenderer == null) {
        _remoteRenderer = webrtc.RTCVideoRenderer();
        await _remoteRenderer!.initialize();
        print('✅ Remote renderer initialized');
      }
      
      // Start local stream
      webrtc.MediaStream? localStream = await startLocalStream(callType: callType);
      if (localStream == null) {
        return false;
      }
      
      // Create peer connection
      webrtc.RTCPeerConnection? peerConnection = await createPeerConnection(callType: callType);
      if (peerConnection == null) {
        return false;
      }
      
      // Store the peer connection globally
      _peerConnection = peerConnection;
      
      // Add local stream tracks to peer connection
      print('🔊 === ADDING LOCAL TRACKS TO PEER CONNECTION ===');
      try {
        final tracks = localStream.getTracks();
        print('🔊 Total tracks to add: ${tracks.length}');
        for (var track in tracks) {
          print('🔊 Adding track: ${track.kind}, enabled: ${track.enabled}, readyState: ${track.label}');
          await peerConnection.addTrack(track, localStream);
          print('✅ Successfully added ${track.kind} track');
        }
      } catch (e) {
        print('❌ Error adding tracks: $e');
        throw Exception('Failed to add tracks to peer connection: $e');
      }
      
      // Create offer
      print('📡 === CREATING OFFER ===');
      webrtc.RTCSessionDescription offer = await peerConnection.createOffer();
      print('📡 Offer created - type: ${offer.type}');
      print('📡 Offer SDP length: ${offer.sdp?.length ?? 0}');
      print('📡 Setting local description...');
      await peerConnection.setLocalDescription(offer);
      print('✅ Local description set');
      
      // Send offer via Socket.IO
      print('📡 Sending offer via Socket.IO to $remoteUserId in room $roomId');
      _sendOffer(offer, roomId, remoteUserId);
      
      print('✅ Outgoing call started');
      return true;
    } catch (e) {
      print('❌ Error starting outgoing call: $e');
      onCallError?.call('Failed to start call: $e');
      return false;
    }
  }

  /// Accept incoming call
  static Future<bool> acceptIncomingCall(String roomId, String userId, String remoteUserId, {String callType = 'audio'}) async {
    try {
      print('📞 Accepting incoming call from $remoteUserId in room $roomId');
      
      _currentRoomId = roomId;
      _remoteUserId = remoteUserId;
      
      // Reset ICE candidate queue for new call
      _iceCandidateQueue.clear();
      _isPeerConnectionReady = false;
      
      // Initialize renderers if not already done
      if (_localRenderer == null) {
        _localRenderer = webrtc.RTCVideoRenderer();
        await _localRenderer!.initialize();
        print('✅ Local renderer initialized');
      }
      
      if (_remoteRenderer == null) {
        _remoteRenderer = webrtc.RTCVideoRenderer();
        await _remoteRenderer!.initialize();
        print('✅ Remote renderer initialized');
      }
      
      // Start local stream
      webrtc.MediaStream? localStream = await startLocalStream(callType: callType);
      if (localStream == null) {
        return false;
      }
      
      // Create peer connection
      webrtc.RTCPeerConnection? peerConnection = await createPeerConnection(callType: callType);
      if (peerConnection == null) {
        return false;
      }
      
      // Store the peer connection globally
      _peerConnection = peerConnection;
      
      // NOTE: DO NOT add tracks here!
      // Tracks will be added in handleOffer() AFTER setting remote description
      // This is the correct WebRTC order: setRemoteDescription -> addTrack -> createAnswer
      print('🔊 Local stream ready with ${localStream.getTracks().length} tracks');
      print('📞 Peer connection ready - tracks will be added when processing offer');
      
      print('✅ Ready to accept incoming call');
      return true;
    } catch (e) {
      print('❌ Error accepting incoming call: $e');
      onCallError?.call('Failed to accept call: $e');
      return false;
    }
  }

  /// Handle incoming offer
  static Future<void> handleOffer(webrtc.RTCSessionDescription offer, String roomId, String fromUserId, {String callType = 'audio'}) async {
    try {
      print('📨 Handling incoming offer from $fromUserId');
      print('📨 Offer type: ${offer.type}');
      print('📨 Offer SDP length: ${offer.sdp?.length ?? 0}');
      
      // Store room and user info
      _currentRoomId = roomId;
      _remoteUserId = fromUserId;
      
      // Reset ICE candidate queue for new call
      _iceCandidateQueue.clear();
      _isPeerConnectionReady = false;
      
      if (_peerConnection == null) {
        print('❌ No peer connection available, creating one...');
        await createPeerConnection(callType: callType);
        if (_peerConnection == null) {
          print('❌ Failed to create peer connection');
          onCallError?.call('Failed to create peer connection');
          return;
        }
        print('✅ Peer connection created in handleOffer');
      } else {
        print('✅ Peer connection already exists');
      }
      
      print('📨 Setting remote description (offer)...');
      await _peerConnection!.setRemoteDescription(offer);
      print('✅ Remote description (offer) set successfully');
      print('📨 Peer connection signaling state: ${_peerConnection!.signalingState}');
      
      // CRITICAL: Local stream should already be started by acceptIncomingCall
      if (_localStream == null) {
        print('⚠️⚠️⚠️ WARNING: Local stream is NULL! Starting it now (this should not happen)...');
        await startLocalStream(callType: callType);
      } else {
        print('✅ Local stream already available with ${_localStream!.getTracks().length} tracks');
      }
      
      // CRITICAL: Add local stream tracks to peer connection AFTER setting remote description
      // This is the correct WebRTC order for answerer: setRemoteDescription -> addTrack -> createAnswer
      if (_localStream != null) {
        print('========================================');
        print('🔊 === ADDING LOCAL TRACKS TO PEER CONNECTION (ANSWERER) ===');
        print('🔊 This is User B adding their video/audio to send to User A');
        print('========================================');
        try {
          final tracks = _localStream!.getTracks();
          print('🔊 Total local tracks available: ${tracks.length}');
          
          int audioCount = 0;
          int videoCount = 0;
          
          for (var track in tracks) {
            if (track.kind == 'audio') audioCount++;
            if (track.kind == 'video') videoCount++;
            
            print('========================================');
            print('🔊 Adding ${track.kind?.toUpperCase()} track to peer connection');
            print('🔊 - Track ID: ${track.id}');
            print('🔊 - Track label: ${track.label}');
            print('🔊 - Track enabled: ${track.enabled}');
            print('🔊 - Track muted: ${track.muted}');
            print('========================================');
            
            await _peerConnection!.addTrack(track, _localStream!);
            print('✅ ✅ ✅ Successfully added local ${track.kind} track to peer connection');
          }
          
          print('========================================');
          print('📊 TRACK SUMMARY FOR ANSWER:');
          print('📊 - Audio tracks added: $audioCount');
          print('📊 - Video tracks added: $videoCount');
          print('📊 - Expected for $callType call: Audio=1, Video=${callType == 'video' ? '1' : '0'}');
          print('========================================');
          
          if (audioCount == 0) {
            print('❌❌❌ CRITICAL: No audio tracks added! User A will not hear User B!');
          }
          
          if (callType == 'video' && videoCount == 0) {
            print('❌❌❌ CRITICAL: No video tracks added! User A will not see User B!');
          }
          
        } catch (e) {
          print('❌❌❌ CRITICAL ERROR adding local tracks: $e');
          print('❌ This means User A will NOT receive User B\'s video/audio!');
        }
      } else {
        print('❌❌❌ CRITICAL: No local stream available when creating answer!');
        print('❌ User A will NOT receive User B\'s video/audio!');
      }
      
      // Create answer
      print('========================================');
      print('📨 === CREATING ANSWER ===');
      print('📨 Creating answer with local tracks included');
      print('========================================');
      webrtc.RTCSessionDescription answer = await _peerConnection!.createAnswer();
      print('✅ Answer created successfully');
      print('📨 Answer type: ${answer.type}');
      print('📨 Answer SDP length: ${answer.sdp?.length ?? 0}');
      
      // Verify SDP includes media
      if (answer.sdp != null) {
        final hasAudio = answer.sdp!.contains('m=audio');
        final hasVideo = answer.sdp!.contains('m=video');
        print('========================================');
        print('📨 SDP ANALYSIS:');
        print('📨 - Contains audio media line: $hasAudio');
        print('📨 - Contains video media line: $hasVideo');
        print('📨 - Expected for $callType call: Audio=$hasAudio, Video=${callType == 'video' ? hasVideo : 'N/A'}');
        print('========================================');
        
        if (!hasAudio) {
          print('❌❌❌ CRITICAL: Answer SDP does NOT contain audio! User A will not hear User B!');
        }
        
        if (callType == 'video' && !hasVideo) {
          print('❌❌❌ CRITICAL: Answer SDP does NOT contain video! User A will not see User B!');
        }
      }
      
      print('📨 Setting local description (answer)...');
      await _peerConnection!.setLocalDescription(answer);
      print('✅ Local description (answer) set');
      
      // Send answer via Socket.IO
      print('📨 Sending answer via Socket.IO to $fromUserId in room $roomId');
      _sendAnswer(answer, roomId, fromUserId);
      
      print('✅ Offer handled and answer sent');
    } catch (e) {
      print('❌ Error handling offer: $e');
      onCallError?.call('Failed to handle offer: $e');
    }
  }

  /// Handle incoming answer
  static Future<void> handleAnswer(webrtc.RTCSessionDescription answer) async {
    try {
      print('========================================');
      print('📨 === USER A: HANDLING INCOMING ANSWER FROM USER B ===');
      print('📨 This is User A receiving User B\'s answer');
      print('========================================');
      print('📨 Answer type: ${answer.type}');
      print('📨 Answer SDP length: ${answer.sdp?.length ?? 0}');
      
      // Verify SDP includes media
      if (answer.sdp != null) {
        final hasAudio = answer.sdp!.contains('m=audio');
        final hasVideo = answer.sdp!.contains('m=video');
        print('========================================');
        print('📨 ANSWER SDP ANALYSIS:');
        print('📨 - Contains audio media line: $hasAudio');
        print('📨 - Contains video media line: $hasVideo');
        print('========================================');
        
        if (!hasAudio) {
          print('❌❌❌ CRITICAL: Answer SDP does NOT contain audio! User A will NOT hear User B!');
        } else {
          print('✅ Answer SDP contains audio - User A should hear User B');
        }
        
        if (!hasVideo) {
          print('⚠️ Answer SDP does NOT contain video (might be audio-only call or issue)');
        } else {
          print('✅ Answer SDP contains video - User A should see User B');
        }
      }
      
      if (_peerConnection == null) {
        print('❌❌❌ CRITICAL: No peer connection available in handleAnswer');
        return;
      }
      print('✅ Peer connection available in handleAnswer');
      print('📨 Current signaling state: ${_peerConnection!.signalingState}');
      
      print('========================================');
      print('📨 Setting remote description (answer) on User A\'s peer connection...');
      print('📨 This will complete the signaling handshake');
      print('========================================');
      await _peerConnection!.setRemoteDescription(answer);
      print('✅ ✅ ✅ Remote description (answer) set successfully');
      print('📨 New signaling state: ${_peerConnection!.signalingState}');
      
      // Mark peer connection as ready for ICE candidates
      _isPeerConnectionReady = true;
      print('✅ Peer connection marked as ready for ICE candidates');
      
      // Process queued ICE candidates
      if (_iceCandidateQueue.isNotEmpty) {
        print('========================================');
        print('🧊 Processing ${_iceCandidateQueue.length} queued ICE candidates');
        print('========================================');
        for (var i = 0; i < _iceCandidateQueue.length; i++) {
          try {
            print('🧊 Adding queued ICE candidate ${i + 1}/${_iceCandidateQueue.length}');
            await _peerConnection!.addCandidate(_iceCandidateQueue[i]);
            print('✅ Added queued ICE candidate ${i + 1}');
          } catch (e) {
            print('❌ Error adding queued ICE candidate ${i + 1}: $e');
          }
        }
        _iceCandidateQueue.clear();
        print('✅ All queued ICE candidates processed and queue cleared');
      } else {
        print('ℹ️ No queued ICE candidates to process');
      }
      
      print('========================================');
      print('✅ ✅ ✅ ANSWER HANDLED SUCCESSFULLY');
      print('📨 User A should now start receiving User B\'s tracks via ontrack events');
      print('📨 Watch for "=== REMOTE TRACK RECEIVED ===" logs next');
      print('========================================');
    } catch (e) {
      print('❌❌❌ CRITICAL ERROR handling answer: $e');
      onCallError?.call('Failed to handle answer: $e');
    }
  }

  /// Handle incoming ICE candidate
  static Future<void> handleIceCandidate(webrtc.RTCIceCandidate candidate) async {
    try {
      print('🧊 Handling incoming ICE candidate');
      print('🧊 Candidate: ${candidate.candidate}');
      print('🧊 SDP MID: ${candidate.sdpMid}');
      print('🧊 SDP MLine Index: ${candidate.sdpMLineIndex}');
      
      if (_peerConnection == null || !_isPeerConnectionReady) {
        print('⚠️ Peer connection not ready, queuing ICE candidate');
        _iceCandidateQueue.add(candidate);
        print('📋 ICE candidate queued (${_iceCandidateQueue.length} total)');
        return;
      }
      
      print('✅ Peer connection ready, adding ICE candidate immediately');
      await _peerConnection!.addCandidate(candidate);
      print('✅ ICE candidate added');
    } catch (e) {
      print('❌ Error handling ICE candidate: $e');
      // If adding fails, queue it for later
      _iceCandidateQueue.add(candidate);
      print('📋 ICE candidate queued due to error (${_iceCandidateQueue.length} total)');
    }
  }

  /// End call
  static Future<void> endCall() async {
    try {
      print('📞 Ending call...');
      
      // Clear ICE candidate queue
      _iceCandidateQueue.clear();
      _isPeerConnectionReady = false;
      
      // Close peer connection
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      
      // Stop local stream
      if (_localStream != null) {
        await _localStream!.dispose();
        _localStream = null;
      }
      
      // Clear remote stream
      if (_remoteStream != null) {
        _remoteStream = null;
      }
      
      // Clear renderers
      if (_localRenderer != null) {
        await _localRenderer!.dispose();
        _localRenderer = null;
      }
      
      if (_remoteRenderer != null) {
        await _remoteRenderer!.dispose();
        _remoteRenderer = null;
      }
      
      // Reset state
      _currentRoomId = null;
      _remoteUserId = null;
      
      onCallDisconnected?.call();
      print('✅ Call ended');
    } catch (e) {
      print('❌ Error ending call: $e');
    }
  }

  /// Get local renderer
  static webrtc.RTCVideoRenderer? get localRenderer => _localRenderer;
  
  /// Get remote renderer
  static webrtc.RTCVideoRenderer? get remoteRenderer => _remoteRenderer;
  
  /// Process queued ICE candidates when peer connection is ready
  static Future<void> _processQueuedIceCandidates() async {
    if (!_isPeerConnectionReady || _peerConnection == null) {
      print('⚠️ Cannot process ICE candidates - peer connection not ready');
      return;
    }
    
    print('🔄 Processing ${_iceCandidateQueue.length} queued ICE candidates...');
    
    for (var candidate in _iceCandidateQueue) {
      try {
        await _peerConnection!.addCandidate(candidate);
        print('✅ Queued ICE candidate added: ${candidate.candidate}');
      } catch (e) {
        print('❌ Failed to add queued ICE candidate: $e');
      }
    }
    
    _iceCandidateQueue.clear();
    print('✅ All queued ICE candidates processed');
  }
  
  /// Manually process queued ICE candidates (for debugging)
  static Future<void> processQueuedIceCandidates() async {
    await _processQueuedIceCandidates();
  }
  
  /// Get current peer connection status for debugging
  static Map<String, dynamic> getConnectionStatus() {
    return {
      'peerConnection': _peerConnection != null,
      'localStream': _localStream != null,
      'remoteStream': _remoteStream != null,
      'localRenderer': _localRenderer != null,
      'remoteRenderer': _remoteRenderer != null,
      'currentRoomId': _currentRoomId,
      'remoteUserId': _remoteUserId,
      'isPeerConnectionReady': _isPeerConnectionReady,
      'queuedIceCandidates': _iceCandidateQueue.length,
    };
  }
  
  /// Check if call is active
  static bool get isCallActive => _peerConnection != null && _localStream != null;
  
  /// Get current room ID
  static String? get currentRoomId => _currentRoomId;
  
  /// Check if remote stream is connected
  static bool get isRemoteStreamConnected => 
      _remoteRenderer != null && _remoteRenderer!.srcObject != null;
  
  /// Get remote stream status
  static String get remoteStreamStatus {
    if (_remoteRenderer == null) return 'Renderer not initialized';
    if (_remoteStream == null) return 'No remote stream';
    if (_remoteRenderer!.srcObject == null) return 'No stream assigned';
    return 'Connected';
  }
  
  /// Force refresh remote stream assignment
  static void refreshRemoteStream() {
    if (_remoteRenderer != null && _remoteStream != null) {
      print('🔄 Refreshing remote stream assignment...');
      _remoteRenderer!.srcObject = _remoteStream;
      print('🔊 After refresh: ${_remoteRenderer!.srcObject != null ? "Set" : "Not set"}');
    }
  }
  

  // Private methods for Socket.IO communication

  static void _sendOffer(webrtc.RTCSessionDescription offer, String roomId, String toUserId) {
    print('📤 === SENDING OFFER VIA SOCKET ===');
    print('📤 Room ID: $roomId');
    print('📤 To user: $toUserId');
    print('📤 Offer type: ${offer.type}');
    SocketService.sendWebRTCOffer(
      roomId: roomId,
      toUserId: toUserId,
      offer: offer,
    );
    print('✅ Offer sent to SocketService');
  }

  static void _sendAnswer(webrtc.RTCSessionDescription answer, String roomId, String toUserId) {
    print('📤 === SENDING ANSWER VIA SOCKET ===');
    print('📤 Room ID: $roomId');
    print('📤 To user: $toUserId');
    print('📤 Answer type: ${answer.type}');
    SocketService.sendWebRTCAnswer(
      roomId: roomId,
      toUserId: toUserId,
      answer: answer,
    );
    print('✅ Answer sent to SocketService');
  }

  static void _sendIceCandidate(webrtc.RTCIceCandidate candidate) {
    print('📤 === SENDING ICE CANDIDATE VIA SOCKET ===');
    print('📤 Room ID: ${_currentRoomId ?? "NULL"}');
    print('📤 To user: ${_remoteUserId ?? "NULL"}');
    if (_currentRoomId == null || _remoteUserId == null) {
      print('❌ CRITICAL: Cannot send ICE candidate - roomId or remoteUserId is null!');
      return;
    }
    SocketService.sendWebRTCIceCandidate(
      roomId: _currentRoomId ?? '',
      toUserId: _remoteUserId ?? '',
      candidate: candidate,
    );
    print('✅ ICE candidate sent to SocketService');
  }

  // Permission dialogs

  static void _showPermissionDeniedDialog() {
    print('📱 Showing permission denied dialog to user');
    Get.dialog(
      AlertDialog(
        title: const Text('🎤 Permission Required'),
        content: const Text(
          'This app needs microphone and camera access to make calls.\n\n'
          'Please tap "Settings" and enable:\n'
          '• Microphone\n'
          '• Camera (for video calls)\n\n'
          'Then restart the call.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('User cancelled permission dialog');
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print('User opening app settings to grant permissions');
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static void _showPermissionPermanentlyDeniedDialog() {
    print('📱 Showing permanently denied permission dialog to user');
    Get.dialog(
      AlertDialog(
        title: const Text('⚠️ Permission Denied'),
        content: const Text(
          'Microphone/Camera permission is permanently denied.\n\n'
          'To enable calls:\n'
          '1. Tap "Open Settings" below\n'
          '2. Go to Permissions\n'
          '3. Enable Microphone and Camera\n'
          '4. Return to the app and try again',
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('User cancelled permanently denied dialog');
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print('User opening app settings (permanent denial)');
              Get.back();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Monitor stream health
  static void _monitorStreamHealth() {
    if (_localStream == null) return;
    
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_localStream == null) {
        timer.cancel();
        return;
      }
      
      final tracks = _localStream!.getTracks();
      bool hasActiveAudio = false;
      
      for (var track in tracks) {
        if (track.kind == 'audio' && track.enabled) {
          hasActiveAudio = true;
          break;
        }
      }
      
      if (!hasActiveAudio) {
        print('⚠️ No active audio tracks detected');
        onCallError?.call('Audio stream lost');
      }
    });
  }

  /// Toggle video track enabled/disabled
  static void toggleVideo(bool enabled) {
    print('========================================');
    print('📹 === TOGGLING VIDEO ===');
    print('📹 New state: ${enabled ? "ENABLED" : "DISABLED"}');
    
    if (_localStream == null) {
      print('❌ No local stream available to toggle video');
      return;
    }
    
    final videoTracks = _localStream!.getVideoTracks();
    print('📹 Video tracks found: ${videoTracks.length}');
    
    if (videoTracks.isEmpty) {
      print('⚠️ No video tracks in local stream');
      return;
    }
    
    for (var track in videoTracks) {
      track.enabled = enabled;
      print('📹 Video track ${track.id} enabled: ${track.enabled}');
    }
    
    print('✅ Video ${enabled ? "enabled" : "disabled"}');
    print('========================================');
  }
  
  /// Toggle audio track enabled/disabled (mute/unmute)
  static void toggleAudio(bool enabled) {
    print('========================================');
    print('🎤 === TOGGLING AUDIO ===');
    print('🎤 New state: ${enabled ? "ENABLED (Unmuted)" : "DISABLED (Muted)"}');
    
    if (_localStream == null) {
      print('❌ No local stream available to toggle audio');
      return;
    }
    
    final audioTracks = _localStream!.getAudioTracks();
    print('🎤 Audio tracks found: ${audioTracks.length}');
    
    if (audioTracks.isEmpty) {
      print('⚠️ No audio tracks in local stream');
      return;
    }
    
    for (var track in audioTracks) {
      track.enabled = enabled;
      print('🎤 Audio track ${track.id} enabled: ${track.enabled}');
    }
    
    print('✅ Audio ${enabled ? "enabled (unmuted)" : "disabled (muted)"}');
    print('========================================');
  }

  /// Dispose service
  static Future<void> dispose() async {
    await endCall();
  }
}