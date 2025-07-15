import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../atoms/custom_button.dart';
import '../atoms/custom_card.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quest_stop_model.dart';

class ChallengeAudioWidget extends StatefulWidget {
  final QuestStop questStop;
  final Function(String) onAudioRecorded;
  final bool isSubmitting;

  const ChallengeAudioWidget({
    Key? key,
    required this.questStop,
    required this.onAudioRecorded,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  State<ChallengeAudioWidget> createState() => _ChallengeAudioWidgetState();
}

class _ChallengeAudioWidgetState extends State<ChallengeAudioWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final AudioPlayer _player = AudioPlayer();
  
  bool _isRecording = false;
  bool _isPlaying = false;
  bool _hasPermission = false;
  bool _isRecorderInitialized = false;
  String? _audioPath;
  Duration _recordDuration = Duration.zero;
  Duration _playbackDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  
  Timer? _recordTimer;
  StreamSubscription? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _checkMicrophonePermission();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playerSubscription?.cancel();
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _initializeRecorder() async {
    try {
      await _recorder.openRecorder();
      setState(() {
        _isRecorderInitialized = true;
      });
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<void> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
    } else if (status.isDenied) {
      final result = await Permission.microphone.request();
      setState(() {
        _hasPermission = result.isGranted;
      });
    }
  }

  void _setupAudioPlayer() {
    _playerSubscription = _player.onDurationChanged.listen((duration) {
      setState(() {
        _playbackDuration = duration;
      });
    });

    _player.onPositionChanged.listen((position) {
      setState(() {
        _playbackPosition = position;
      });
    });

    _player.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _playbackPosition = Duration.zero;
      });
    });
  }

  Future<void> _startRecording() async {
    if (!_hasPermission) {
      await _checkMicrophonePermission();
      if (!_hasPermission) return;
    }

    if (!_isRecorderInitialized) {
      await _initializeRecorder();
      if (!_isRecorderInitialized) return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'quest_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      final path = '${directory.path}/$fileName';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
        _audioPath = path;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordDuration = Duration(seconds: timer.tick);
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _recorder.stopRecorder();
      _recordTimer?.cancel();
      
      setState(() {
        _isRecording = false;
      });

      if (_audioPath != null) {
        widget.onAudioRecorded(_audioPath!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error stopping recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _playRecording() async {
    if (_audioPath == null) return;

    try {
      await _player.play(DeviceFileSource(_audioPath!));
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopPlaying() async {
    await _player.stop();
    setState(() {
      _isPlaying = false;
      _playbackPosition = Duration.zero;
    });
  }

  void _deleteRecording() {
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    setState(() {
      _audioPath = null;
      _recordDuration = Duration.zero;
      _playbackDuration = Duration.zero;
      _playbackPosition = Duration.zero;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.teal, Colors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Challenge',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Record your response',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Challenge Instructions
          if (widget.questStop.challengeInstructions?.isNotEmpty == true) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blackOpacity10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.blackOpacity20,
                ),
              ),
              child: Text(
                widget.questStop.challengeInstructions!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Recording Interface
          if (!_hasPermission) ...[
            _buildPermissionRequest(),
          ] else ...[
            _buildRecordingInterface(),
          ],
          
          const SizedBox(height: 16),
          
          // Control Buttons
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_off,
              size: 48,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'Microphone Permission Required',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please grant microphone permission to record audio',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingInterface() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.withOpacity(0.1),
            Colors.cyan.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.teal.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Recording Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Recording...',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else if (_audioPath != null) ...[
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Recording Complete',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                const Icon(Icons.mic, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Ready to Record',
                  style: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Duration Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isRecording 
                  ? _formatDuration(_recordDuration)
                  : _audioPath != null
                      ? _formatDuration(_playbackDuration)
                      : '00:00',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
          
          // Playback Progress
          if (_audioPath != null && _playbackDuration.inSeconds > 0) ...[
            const SizedBox(height: 16),
            Column(
              children: [
                LinearProgressIndicator(
                  value: _playbackDuration.inSeconds > 0
                      ? _playbackPosition.inSeconds / _playbackDuration.inSeconds
                      : 0,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_playbackPosition),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_playbackDuration),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        if (_isRecording) ...[
          Expanded(
            child: CustomButton(
              text: 'Stop Recording',
              icon: Icons.stop,
              onPressed: _stopRecording,
              variant: ButtonVariant.secondary,
            ),
          ),
        ] else if (_audioPath != null) ...[
          Expanded(
            flex: 2,
            child: CustomButton(
              text: _isPlaying ? 'Stop Playback' : 'Play Recording',
              icon: _isPlaying ? Icons.stop : Icons.play_arrow,
              onPressed: _isPlaying ? _stopPlaying : _playRecording,
              variant: ButtonVariant.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomButton(
              text: 'Delete',
              icon: Icons.delete,
              onPressed: _deleteRecording,
              variant: ButtonVariant.secondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomButton(
              text: 'Record Again',
              icon: Icons.refresh,
              onPressed: _startRecording,
            ),
          ),
        ] else ...[
          Expanded(
            child: CustomButton(
              text: 'Start Recording',
              icon: Icons.mic,
              onPressed: _hasPermission ? _startRecording : _checkMicrophonePermission,
              isLoading: widget.isSubmitting,
            ),
          ),
        ],
      ],
    );
  }
}