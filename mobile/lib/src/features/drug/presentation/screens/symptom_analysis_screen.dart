import 'package:speech_to_text/speech_to_text.dart';

import '../../../../imports/imports.dart';
import '../../data/drug_repository.dart';

/// Gemini tabanlı semptom analiz ekranı.
/// Kullanıcı semptomlarını yazar; AI olası nedenleri ve tavsiyeleri döndürür.
class SymptomAnalysisScreen extends StatefulWidget {
  const SymptomAnalysisScreen({super.key});

  @override
  State<SymptomAnalysisScreen> createState() => _SymptomAnalysisScreenState();
}

class _SymptomAnalysisScreenState extends State<SymptomAnalysisScreen> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          _controller.text = result.recognizedWords;
          // İmleci metnin sonuna taşı
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        },
        localeId: 'tr_TR',
        listenOptions: SpeechListenOptions(partialResults: true),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _speech.cancel();
    super.dispose();
  }

  Future<void> _analyze() async {
    // Klavyeyi kapat
    FocusManager.instance.primaryFocus?.unfocus();
    final description = _controller.text.trim();
    if (description.isEmpty) {
      setState(() => _error = 'symptom_analysis.empty_error'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    final result = await DrugRepository.instance.analyzeSymptoms(description);

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'symptom_analysis.generic_error'.tr();
        });
      },
      (data) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _result = data;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.health_and_safety_rounded, size: 26),
            SizedBox(width: AppSpacing.sm),
            Text(
              'symptom_analysis.title'.tr(),
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Giriş kartı
            _buildInputCard(colorScheme, textTheme),
            SizedBox(height: AppSpacing.xl),
            // Hata mesajı
            if (_error != null)
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: colorScheme.onErrorContainer),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _error!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Yükleniyor
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF00897B),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        'symptom_analysis.loading'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Sonuç
            if (_result != null) ...[
              _buildResultSection(colorScheme, textTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFF00897B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF00897B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: Color(0xFF00897B)),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'symptom_analysis.input_title'.tr(),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF00897B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'symptom_analysis.input_subtitle'.tr(),
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'symptom_analysis.input_hint'.tr(),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: const Color(0xFF00897B).withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF00897B),
                  width: 2,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          // Sesle yazma butonu
          if (_speechEnabled)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isLoading ? null : _toggleListening,
                icon: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  size: 20,
                ),
                label: Text(
                  _isListening ? 'Kaydı durdur' : 'Sesle yaz',
                  style: const TextStyle(fontSize: 13),
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                      _isListening ? Colors.red : const Color(0xFF00897B),
                ),
              ),
            ),
          SizedBox(height: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _analyze,
            icon: const Icon(Icons.search_rounded),
            label: Text(
              'symptom_analysis.button'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(ColorScheme colorScheme, TextTheme textTheme) {
    final result = _result!;
    final isEmergency = result['acil_durum'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Acil durum banner'ı
        if (isEmergency)
          Container(
            padding: EdgeInsets.all(AppSpacing.lg),
            margin: EdgeInsets.only(bottom: AppSpacing.xl),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.emergency_rounded,
                    color: colorScheme.onErrorContainer, size: 32),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'symptom_analysis.emergency_title'.tr(),
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'symptom_analysis.emergency_subtitle'.tr(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        // Özet
        _ResultCard(
          icon: Icons.summarize_rounded,
          title: 'symptom_analysis.summary_title'.tr(),
          color: const Color(0xFF00897B),
          child: Text(
            result['semptomlar_ozeti'] as String? ?? '',
            style: textTheme.bodyMedium,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        // Olası nedenler
        _ResultCard(
          icon: Icons.search_rounded,
          title: 'symptom_analysis.causes_title'.tr(),
          color: const Color(0xFF1565C0),
          child: Column(
            children: ((result['olasilik_nedenler'] as List?) ?? [])
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(item.toString())),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        // Tavsiyeler
        _ResultCard(
          icon: Icons.tips_and_updates_rounded,
          title: 'symptom_analysis.advice_title'.tr(),
          color: const Color(0xFF6750A4),
          child: Column(
            children: ((result['tavsiyeler'] as List?) ?? [])
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontSize: 16)),
                        Expanded(child: Text(item.toString())),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        // Doktora ne zaman
        _ResultCard(
          icon: Icons.local_hospital_rounded,
          title: 'symptom_analysis.doctor_when_title'.tr(),
          color: const Color(0xFFE65100),
          child: Text(
            result['doktora_ne_zaman'] as String? ?? '',
            style: textTheme.bodyMedium,
          ),
        ),
        SizedBox(height: AppSpacing.lg),
        // Disclaimer
        Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: colorScheme.onSurfaceVariant, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  result['disclaimer'] as String? ??
                      'symptom_analysis.disclaimer'.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Sonuç bölümü için tekrar kullanılabilir kart widget'ı.
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}
