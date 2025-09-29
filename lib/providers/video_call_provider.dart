import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

class VideoCallProvider with ChangeNotifier {
  RtcEngine? _engine;
  bool _isInitialized = false;
  bool _localUserJoined = false;
  int? _remoteUid;
  bool _muted = false;
  bool _videoDisabled = false;
  bool _screenSharing = false;
  String _errorMessage = '';

  // Getters
  bool get isInitialized => _isInitialized;
  bool get localUserJoined => _localUserJoined;
  int? get remoteUid => _remoteUid;
  bool get muted => _muted;
  bool get videoDisabled => _videoDisabled;
  bool get screenSharing => _screenSharing;
  String get errorMessage => _errorMessage;
  RtcEngine? get engine => _engine;

  Future<void> initializeAgora(String channelName, BuildContext context) async {
    try {
      await _requestPermissions();
      await dotenv.load();
      final appId = dotenv.env['AGORA_APP_ID'] ?? '';

      if (appId.isEmpty) {
        _setError('Agora App ID is missing. Please check your .env file');
        return;
      }

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(appId: appId));
      _setupEventHandlers();

      await _engine!.enableVideo();
      await _engine!.setChannelProfile(
        ChannelProfileType.channelProfileCommunication,
      );
      await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      await _engine!.joinChannel(
        token: dotenv.env['AGORA_TOKEN'] ?? '',
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _setError('Initialization failed: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final status = await [Permission.camera, Permission.microphone].request();

      if (status[Permission.camera]!.isDenied) {
        throw Exception('Camera permission is required for video calls');
      }
      if (status[Permission.microphone]!.isDenied) {
        throw Exception('Microphone permission is required for audio');
      }
    } catch (e) {
      throw Exception('Permission request failed: $e');
    }
  }

  void _setupEventHandlers() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onError: (err, msg) {
          _setError('Agora Error: $err, $msg');
        },
        onJoinChannelSuccess: (connection, elapsed) {
          _localUserJoined = true;
          _isInitialized = true;
          debugPrint('Local user ${connection.localUid} joined channel');
          notifyListeners();
        },
        onUserJoined: (connection, uid, elapsed) {
          _remoteUid = uid;
          debugPrint('Remote user $uid joined');
          notifyListeners();
        },
        onUserOffline: (connection, uid, reason) {
          _remoteUid = null;
          debugPrint('Remote user $uid left channel');
          notifyListeners();
        },
      ),
    );
  }

  void _setError(String message) {
    _errorMessage = message;
    debugPrint(message);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    if (!_isInitialized || _engine == null) return;
    _muted = !_muted;
    await _engine!.muteLocalAudioStream(_muted);
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    if (!_isInitialized || _engine == null || _screenSharing) return;
    _videoDisabled = !_videoDisabled;
    await _engine!.enableLocalVideo(!_videoDisabled);
    notifyListeners();
  }

  Future<void> toggleScreenSharing() async {
    if (!_isInitialized || _engine == null) {
      _setError('Engine not initialized');
      return;
    }

    try {
      if (!_screenSharing) {
        await _startScreenSharing();
      } else {
        await _stopScreenSharing();
      }
      notifyListeners();
    } catch (e) {
      _setError('Screen sharing error: $e');
    }
  }

  Future<void> _startScreenSharing() async {
    try {
      debugPrint('Starting screen sharing...');

      // For Android, we need to use MediaProjection API
      if (Platform.isAndroid) {
        await _startAndroidScreenSharing();
      } else if (Platform.isIOS) {
        await _startIosScreenSharing();
      } else {
        await _startDesktopScreenSharing();
      }

      _screenSharing = true;
      _videoDisabled = true;

      debugPrint('Screen sharing started successfully');
    } catch (e) {
      debugPrint('Screen sharing failed: $e');
      await _revertToCamera();
      rethrow;
    }
  }

  Future<void> _startAndroidScreenSharing() async {
    try {
      // Request screen capture permission using MediaProjection
      // This should trigger the system screen capture permission dialog
      final screenShareParams = ScreenCaptureParameters2(
        captureAudio: true,
        captureVideo: true,
        videoParams: const ScreenVideoParameters(frameRate: 15, bitrate: 0),
      );

      // This call should trigger the system permission dialog
      await _engine!.startScreenCapture(screenShareParams);

      // Update media options for screen sharing
      await _engine!.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishCameraTrack: false,
          publishScreenTrack: true,
          publishScreenCaptureAudio: true,
        ),
      );

      debugPrint('Android screen sharing setup completed');
    } catch (e) {
      throw Exception('Failed to start screen sharing on Android: $e');
    }
  }

  Future<void> _startIosScreenSharing() async {
    try {
      // For iOS, we need to use broadcast picker
      // This requires Broadcast Upload Extension setup
      final screenShareParams = ScreenCaptureParameters2(
        captureAudio: true,
        captureVideo: true,
        videoParams: const ScreenVideoParameters(frameRate: 15, bitrate: 0),
      );

      await _engine!.startScreenCapture(screenShareParams);

      await _engine!.updateChannelMediaOptions(
        ChannelMediaOptions(
          publishCameraTrack: false,
          publishScreenTrack: true,
          publishScreenCaptureAudio: true,
        ),
      );

      debugPrint('iOS screen sharing setup completed');
    } catch (e) {
      throw Exception('Failed to start screen sharing on iOS: $e');
    }
  }

  Future<void> _startDesktopScreenSharing() async {
    // For desktop platforms
    final screenShareParams = ScreenCaptureParameters2(
      captureAudio: true,
      captureVideo: true,
      videoParams: const ScreenVideoParameters(frameRate: 15, bitrate: 0),
    );

    await _engine!.startScreenCapture(screenShareParams);

    await _engine!.updateChannelMediaOptions(
      ChannelMediaOptions(
        publishCameraTrack: false,
        publishScreenTrack: true,
        publishScreenCaptureAudio: true,
      ),
    );
  }

  Future<void> _stopScreenSharing() async {
    try {
      await _engine!.stopScreenCapture();

      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: true,
          publishScreenTrack: false,
          publishScreenCaptureAudio: false,
        ),
      );

      await _engine!.enableLocalVideo(true);

      _screenSharing = false;
      _videoDisabled = false;

      debugPrint('Screen sharing stopped successfully');
    } catch (e) {
      _setError('Error stopping screen share: $e');
      rethrow;
    }
  }

  Future<void> _revertToCamera() async {
    try {
      await _engine!.updateChannelMediaOptions(
        const ChannelMediaOptions(
          publishCameraTrack: true,
          publishScreenTrack: false,
          publishScreenCaptureAudio: false,
        ),
      );
      await _engine!.enableLocalVideo(true);
      _screenSharing = false;
      _videoDisabled = false;
    } catch (e) {
      debugPrint('Error reverting to camera: $e');
    }
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      try {
        if (_screenSharing) {
          await _stopScreenSharing();
        }
        await _engine!.leaveChannel();
        await _engine!.release();
      } catch (e) {
        debugPrint('Error during leaveChannel: $e');
      }
    }
    _resetState();
  }

  void _resetState() {
    _engine = null;
    _isInitialized = false;
    _localUserJoined = false;
    _remoteUid = null;
    _muted = false;
    _videoDisabled = false;
    _screenSharing = false;
    _errorMessage = '';
    notifyListeners();
  }
}
