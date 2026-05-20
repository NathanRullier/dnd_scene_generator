import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Diagnostic page to verify the platform speech recognition stack is wired up
/// and producing results. Independent of the full session pipeline so it can
/// be used to isolate STT issues from NLP/SD generation issues.
class SpeechTestScreen extends StatefulWidget {
  const SpeechTestScreen({super.key});

  @override
  State<SpeechTestScreen> createState() => _SpeechTestScreenState();
}

class _SpeechTestScreenState extends State<SpeechTestScreen> {
  final SpeechToText _stt = SpeechToText();

  bool _initialized = false;
  bool _available = false;
  bool _listening = false;
  double _level = 0;
  String _status = 'idle';
  String _lastError = '';
  String _committed = '';
  String _partial = '';
  List<String> _locales = const [];
  String? _selectedLocale;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _stt.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    try {
      final ok = await _stt.initialize(
        onStatus: (s) => setState(() {
          _status = s;
          _listening = s == SpeechToText.listeningStatus;
        }),
        onError: (e) => setState(() => _lastError = _formatError(e)),
        debugLogging: true,
      );
      final locales = await _stt.locales();
      final defaultLocale = await _stt.systemLocale();
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _available = ok;
        _locales = locales.map((l) => l.localeId).toList();
        _selectedLocale = defaultLocale?.localeId ?? _locales.firstOrNull;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialized = true;
        _available = false;
        _lastError = 'initialize() threw: $e';
      });
    }
  }

  String _formatError(SpeechRecognitionError e) =>
      '${e.errorMsg}${e.permanent ? ' (permanent)' : ''}';

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stt.stop();
      return;
    }
    setState(() {
      _partial = '';
      _lastError = '';
    });
    await _stt.listen(
      onResult: _onResult,
      onSoundLevelChange: (l) => setState(() => _level = l),
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 6),
      partialResults: true,
      localeId: _selectedLocale,
      listenMode: ListenMode.dictation,
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    final words = result.recognizedWords;
    setState(() {
      if (result.finalResult) {
        _committed = _committed.isEmpty ? words : '$_committed $words';
        _partial = '';
      } else {
        _partial = words;
      }
    });
  }

  void _clear() => setState(() {
        _committed = '';
        _partial = '';
        _lastError = '';
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Recognition Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-initialize',
            onPressed: _initialize,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusCard(
            initialized: _initialized,
            available: _available,
            status: _status,
            listening: _listening,
            level: _level,
            lastError: _lastError,
          ),
          const SizedBox(height: 16),
          if (_locales.isNotEmpty) ...[
            Text('Locale', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _selectedLocale,
              isExpanded: true,
              items: _locales
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: _listening
                  ? null
                  : (v) => setState(() => _selectedLocale = v),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _available ? _toggleListening : null,
                  icon: Icon(_listening ? Icons.stop : Icons.mic),
                  label: Text(_listening ? 'Stop' : 'Start listening'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _listening
                        ? Colors.red.shade700
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TranscriptionCard(committed: _committed, partial: _partial),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool initialized;
  final bool available;
  final String status;
  final bool listening;
  final double level;
  final String lastError;

  const _StatusCard({
    required this.initialized,
    required this.available,
    required this.status,
    required this.listening,
    required this.level,
    required this.lastError,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Engine status', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _Row('Initialized', initialized.toString()),
            _Row('Available', available.toString()),
            _Row('Status', status),
            _Row('Listening', listening.toString()),
            _Row('Sound level', level.toStringAsFixed(1)),
            if (lastError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lastError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade200,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptionCard extends StatelessWidget {
  final String committed;
  final String partial;
  const _TranscriptionCard({required this.committed, required this.partial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = committed.isEmpty && partial.isEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recognised text', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 120),
              child: empty
                  ? Text(
                      'Nothing recognised yet. Press Start listening and speak.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white38,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : RichText(
                      text: TextSpan(
                        children: [
                          if (committed.isNotEmpty)
                            TextSpan(
                              text: committed,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          if (partial.isNotEmpty)
                            TextSpan(
                              text: '${committed.isNotEmpty ? ' ' : ''}$partial',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
