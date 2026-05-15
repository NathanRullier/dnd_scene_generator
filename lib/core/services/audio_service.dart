import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<RecordState>? _stateSubscription;
  Timer? _chunkTimer;
  bool _isListening = false;
  int _chunkIndex = 0;
  String? _tempDir;

  final StreamController<String> _audioChunkController =
      StreamController<String>.broadcast();

  Stream<String> get audioChunks => _audioChunkController.stream;
  bool get isListening => _isListening;

  Future<bool> hasPermission() async {
    return _recorder.hasPermission();
  }

  Future<void> startListening({
    Duration chunkDuration = const Duration(seconds: 5),
  }) async {
    if (_isListening) return;

    final hasPerms = await _recorder.hasPermission();
    if (!hasPerms) {
      throw Exception('Microphone permission not granted');
    }

    final dir = await getTemporaryDirectory();
    _tempDir = p.join(dir.path, 'audio_chunks');
    await Directory(_tempDir!).create(recursive: true);

    _isListening = true;
    _chunkIndex = 0;

    await _startRecordingChunk();

    _chunkTimer = Timer.periodic(chunkDuration, (_) async {
      if (!_isListening) return;
      await _cycleChunk();
    });
  }

  Future<void> _startRecordingChunk() async {
    final chunkPath = p.join(_tempDir!, 'chunk_$_chunkIndex.wav');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: chunkPath,
    );
  }

  Future<void> _cycleChunk() async {
    final completedPath = p.join(_tempDir!, 'chunk_$_chunkIndex.wav');
    await _recorder.stop();

    if (await File(completedPath).exists()) {
      _audioChunkController.add(completedPath);
    }

    _chunkIndex++;
    if (_isListening) {
      await _startRecordingChunk();
    }
  }

  Future<void> stopListening() async {
    _isListening = false;
    _chunkTimer?.cancel();
    _chunkTimer = null;
    await _recorder.stop();
  }

  Future<void> dispose() async {
    await stopListening();
    _stateSubscription?.cancel();
    await _audioChunkController.close();
    _recorder.dispose();
  }
}
