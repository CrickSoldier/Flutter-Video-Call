import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:provider/provider.dart';
import '../providers/video_call_provider.dart';
import 'user_list_screen.dart';
import 'login_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final String userName;

  const VideoCallScreen({super.key, required this.userName});

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final String channelName = 'test_channel';

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  void _initializeCall() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VideoCallProvider>(
        context,
        listen: false,
      ).initializeAgora(channelName, context);
    });
  }

  @override
  void dispose() {
    Provider.of<VideoCallProvider>(context, listen: false).leaveChannel();
    super.dispose();
  }

  Widget _buildLocalVideo(VideoCallProvider provider) {
    if (!provider.isInitialized ||
        provider.engine == null ||
        !provider.localUserJoined) {
      return _buildPlaceholder(widget.userName);
    }

    if (provider.videoDisabled && !provider.screenSharing) {
      return _buildPlaceholder(widget.userName);
    }

    try {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: provider.engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } catch (e) {
      debugPrint('Error building local video: $e');
      return _buildPlaceholder(widget.userName);
    }
  }

  Widget _buildRemoteVideo(VideoCallProvider provider) {
    if (!provider.isInitialized || provider.engine == null) {
      return _buildWaitingMessage();
    }

    if (provider.remoteUid != null) {
      try {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: provider.engine!,
            canvas: VideoCanvas(uid: provider.remoteUid!),
            connection: RtcConnection(channelId: channelName),
          ),
        );
      } catch (e) {
        debugPrint('Error building remote video: $e');
        return _buildWaitingMessage();
      }
    }

    return _buildWaitingMessage();
  }

  Widget _buildPlaceholder(String userName) {
    return Container(
      color: Colors.grey[800],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingMessage() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Waiting for remote user...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(VideoCallProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolbarButton(
            icon: provider.muted ? Icons.mic_off : Icons.mic,
            color: provider.muted ? Colors.red : Colors.white,
            label: provider.muted ? 'Unmute' : 'Mute',
            onPressed: provider.isInitialized
                ? () => _toggleMute(provider)
                : null,
          ),
          _buildToolbarButton(
            icon: provider.videoDisabled ? Icons.videocam_off : Icons.videocam,
            color: provider.videoDisabled ? Colors.red : Colors.white,
            label: provider.videoDisabled ? 'Enable Video' : 'Disable Video',
            onPressed: provider.isInitialized && !provider.screenSharing
                ? () => _toggleVideo(provider)
                : null,
          ),
          _buildToolbarButton(
            icon: provider.screenSharing
                ? Icons.stop_screen_share
                : Icons.screen_share,
            color: provider.screenSharing ? Colors.red : Colors.white,
            label: provider.screenSharing ? 'Stop Share' : 'Share Screen',
            onPressed: provider.isInitialized
                ? () => _toggleScreenSharing(provider)
                : null,
          ),
          _buildToolbarButton(
            icon: Icons.call_end,
            color: Colors.red,
            label: 'End Call',
            onPressed: () => _endCall(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(icon, color: color, size: 30),
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Future<void> _toggleMute(VideoCallProvider provider) async {
    try {
      await provider.toggleMute();
      _showSnackBar(provider.muted ? 'Microphone Off' : 'Microphone On');
    } catch (e) {
      _showSnackBar('Failed to toggle microphone: ${e.toString()}');
    }
  }

  Future<void> _toggleVideo(VideoCallProvider provider) async {
    try {
      await provider.toggleVideo();
      _showSnackBar(provider.videoDisabled ? 'Video Off' : 'Video On');
    } catch (e) {
      _showSnackBar('Failed to toggle video: ${e.toString()}');
    }
  }

  Future<void> _toggleScreenSharing(VideoCallProvider provider) async {
    try {
      // Show loading indicator
      _showSnackBar('Starting screen sharing...');

      await provider.toggleScreenSharing();

      if (provider.screenSharing) {
        _showSnackBar('Screen Sharing Started');

        // Show platform-specific instructions
        if (Theme.of(context).platform == TargetPlatform.android) {
          _showScreenSharingInstructions();
        }
      } else {
        _showSnackBar('Screen Sharing Stopped');
      }
    } catch (e) {
      String errorMessage = 'Failed to toggle screen sharing';

      // Provide more specific error messages
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        errorMessage =
            'Screen sharing permission denied. Please grant permission when prompted.';
      } else if (e.toString().contains('not supported')) {
        errorMessage = 'Screen sharing is not supported on this device.';
      } else {
        errorMessage = 'Screen sharing error: ${e.toString()}';
      }

      _showSnackBar(errorMessage);
    }
  }

  void _showScreenSharingInstructions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Screen Sharing Setup'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To start screen sharing:'),
              SizedBox(height: 12),
              Text('1. Wait for system permission dialog'),
              Text('2. Tap "Start Now" to begin recording'),
              Text('3. Your screen will be shared with participants'),
              SizedBox(height: 12),
              Text(
                'Note: You can stop sharing anytime using the stop button.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got It'),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _endCall(VideoCallProvider provider) async {
    try {
      await provider.leaveChannel();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar('Error ending call: ${e.toString()}');
      // Force navigation even if there's an error
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(VideoCallProvider provider) {
    bool isScreenSharingError =
        provider.errorMessage.contains('screen') ||
        provider.errorMessage.contains('sharing') ||
        provider.errorMessage.contains('permission');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isScreenSharingError ? Icons.screen_share : Icons.error,
                color: isScreenSharingError ? Colors.orange : Colors.red,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                isScreenSharingError
                    ? 'Screen Sharing Error'
                    : 'Connection Error',
                style: TextStyle(
                  color: isScreenSharingError ? Colors.orange : Colors.red,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                provider.errorMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (isScreenSharingError) ...[
                ElevatedButton(
                  onPressed: () {
                    // Clear error and retry screen sharing
                    Provider.of<VideoCallProvider>(
                      context,
                      listen: false,
                    ).toggleScreenSharing();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Retry Screen Sharing'),
                ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: () => _initializeCall(),
                child: const Text('Retry Connection'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Go Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoCallProvider>(
      builder: (context, provider, _) {
        if (provider.errorMessage.isNotEmpty) {
          return _buildErrorWidget(provider);
        }

        if (!provider.isInitialized) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing video call...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(
              'Video Call with ${widget.userName}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.black,
            actions: [
              // Screen sharing status indicator
              if (provider.screenSharing)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.screen_share, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Sharing',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.people, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UserListScreen()),
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              // Remote video (main view)
              Center(child: _buildRemoteVideo(provider)),

              // Local video (picture-in-picture)
              if (provider.localUserJoined)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 120,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: provider.screenSharing
                            ? Colors.orange
                            : Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        children: [
                          _buildLocalVideo(provider),
                          if (provider.screenSharing)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.screen_share,
                                      color: Colors.orange,
                                      size: 30,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Screen Sharing',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Toolbar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildToolbar(provider),
              ),

              // Screen sharing overlay when active
              if (provider.screenSharing)
                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.screen_share, size: 16, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'You are sharing your screen',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
