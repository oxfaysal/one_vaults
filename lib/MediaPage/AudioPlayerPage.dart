import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path/path.dart' as p;
import 'package:one_vaults/conts/Color.dart';

class AudioPlayerPage extends StatefulWidget {
  final List<File> playlist;
  final int initialIndex;

  const AudioPlayerPage({
    super.key,
    required this.playlist,
    required this.initialIndex,
  });

  @override
  State<AudioPlayerPage> createState() => _AudioPlayerPageState();
}

class _AudioPlayerPageState extends State<AudioPlayerPage> {
  // প্লেয়ারকে static রাখা হয়েছে যাতে পেজ থেকে বের হলেও অবজেক্ট মেমোরিতে থাকে
  static final AudioPlayer _player = AudioPlayer();
  late int _currentIndex;
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _setupAudioContext();
    _initAudio();

    // লিসেনার সেটআপ (mounted চেক করা হয়েছে যাতে মেমোরি লিক না হয়)
    _player.onPlayerComplete.listen((event) {
      if (mounted) _playNext();
    });

    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => duration = d);
    });

    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => position = pos);
    });

    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => isPlaying = state == PlayerState.playing);
    });
  }

  void _setupAudioContext() {
    AudioPlayer.global.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain,
      ),
    ));
  }

  void _initAudio() async {
    // নতুন গান প্লে করার আগে বর্তমান গান থামানো প্রয়োজন নেই যদি playlist থেকে আসে
    await _player.play(DeviceFileSource(widget.playlist[_currentIndex].path));
  }

  void _playNext() {
    if (_currentIndex < widget.playlist.length - 1) {
      setState(() {
        _currentIndex++;
        position = Duration.zero;
        duration = Duration.zero;
      });
      _initAudio();
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        position = Duration.zero;
        duration = Duration.zero;
      });
      _initAudio();
    }
  }

  @override
  void dispose() {
    // গুরুত্বপূর্ণ: এখান থেকে _player.dispose() সরিয়ে ফেলা হয়েছে।
    // এখন অ্যাপের অন্য পেজে গেলেও গান চলতে থাকবে।
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    File currentFile = widget.playlist[_currentIndex];
    String fileName = p.basename(currentFile.path).replaceFirst(RegExp(r'vault_\d+_'), '');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Now Playing", style: TextStyle(color: Colors.black, fontSize: 16)),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              height: 250, width: 250,
              decoration: BoxDecoration(
                color: APP_COLOR.primary2Color.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: APP_COLOR.primary2Color.withOpacity(0.1), width: 10),
              ),
              child: Icon(Icons.music_note_rounded, size: 100, color: APP_COLOR.primary2Color),
            ),
          ),
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              fileName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 40),

          // স্লাইডার ভ্যালু ক্ল্যাম্পিং করা হয়েছে যাতে এরর না আসে
          Slider(
            min: 0,
            max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
            value: position.inSeconds.toDouble().clamp(0.0, duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0),
            activeColor: APP_COLOR.primary2Color,
            onChanged: (value) async {
              await _player.seek(Duration(seconds: value.toInt()));
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatTime(position)),
                Text(_formatTime(duration)),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 45),
                onPressed: _currentIndex > 0 ? _playPrevious : null,
                color: _currentIndex > 0 ? Colors.black : Colors.grey,
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => isPlaying ? _player.pause() : _player.resume(),
                child: Container(
                  height: 70, width: 70,
                  decoration: BoxDecoration(
                      color: APP_COLOR.primary2Color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: APP_COLOR.primary2Color.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5)
                        )
                      ]
                  ),
                  child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 45),
                onPressed: _currentIndex < widget.playlist.length - 1 ? _playNext : null,
                color: _currentIndex < widget.playlist.length - 1 ? Colors.black : Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration d) {
    return d.toString().split('.').first.padLeft(8, "0").substring(3);
  }
}