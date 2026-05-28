import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../imports/imports.dart';
import '../../data/drug_repository.dart';

/// Gemini tabanlı eczacı asistanı sohbet ekranı.
/// Kullanıcı mesajları ile model yanıtlarını baloncuk UI'ında gösterir.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Her mesaj: {'role': 'user'|'model', 'content': '...'}
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Klavyeyi kapat
    FocusManager.instance.primaryFocus?.unfocus();
    _inputController.clear();

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });

    _scrollToBottom();

    // Gemini'ye gönderilecek geçmiş: yeni eklenen kullanıcı mesajı hariç.
    final historyToSend = _messages.sublist(0, _messages.length - 1);

    final result =
        await DrugRepository.instance.sendChatMessage(text, historyToSend);

    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _messages.add({
            'role': 'model',
            'content': 'ai_chat.error'.tr(),
          });
        });
      },
      (reply) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _messages.add({'role': 'model', 'content': reply});
        });
        // Yanıt gelince listeyi en alta kaydır.
        _scrollToBottom();
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.smart_toy_rounded, size: 28),
            SizedBox(width: AppSpacing.sm),
            Text(
              'ai_chat.title'.tr(),
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // AI kimlik bandı
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            color: const Color(0xFF6750A4).withValues(alpha: 0.08),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFF6750A4),
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'ai_chat.powered_by'.tr(),
                    style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF6750A4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState(colorScheme, textTheme)
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        // Yükleniyor göstergesi (typing indicator)
                        return const _TypingIndicator(color: Color(0xFF6750A4));
                      }
                      final msg = _messages[index];
                      return _ChatBubble(
                        message: msg['content'] ?? '',
                        isUser: msg['role'] == 'user',
                        accentColor: const Color(0xFF6750A4),
                      );
                    },
                  ),
          ),
          // Disclaimer
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Text(
              'ai_chat.disclaimer'.tr(),
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Mesaj giriş alanı
          _MessageInputBar(
            controller: _inputController,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 52,
              color: Color(0xFF6750A4),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            'ai_chat.empty_title'.tr(),
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'ai_chat.empty_subtitle'.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
          // Örnek sorular
          ...[
            'ai_chat.example_1',
            'ai_chat.example_2',
            'ai_chat.example_3',
          ].map(
            (key) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () {
                  _inputController.text = key.tr();
                  _sendMessage();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF6750A4).withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: Color(0xFF6750A4),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          key.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6750A4),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tek bir sohbet balonu.
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.isUser,
    required this.accentColor,
  });

  final String message;
  final bool isUser;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.md,
        left: isUser ? AppSpacing.xxl : 0,
        right: isUser ? 0 : AppSpacing.xxl,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI avatar ikonu
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color:
                    isUser ? accentColor : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
              ),
              // Kullanıcı mesajı düz metin; AI yanıtı markdown olarak render edilir
              child: isUser
                  ? Text(
                      message,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: message,
                      styleSheet: MarkdownStyleSheet(
                        p: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.6,
                        ),
                        strong: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                        em: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontStyle: FontStyle.italic,
                        ),
                        h1: textTheme.titleMedium?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                        h2: textTheme.titleSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                        h3: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                        listBullet: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.6,
                        ),
                        // Satır içi kod
                        code: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: accentColor,
                          backgroundColor: accentColor.withValues(alpha: 0.08),
                        ),
                        blockSpacing: 10,
                        listIndent: 20,
                        blockquotePadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                      shrinkWrap: true,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Üç nokta typing indicator animasyonu.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});
  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  // Her nokta için aşamalı animasyon
                  final offset = ((_animation.value * 3) - i).clamp(0.0, 1.0);
                  final opacity = (offset < 0.5 ? offset : 1.0 - offset) * 2;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Opacity(
                      opacity: opacity.clamp(0.3, 1.0),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alt mesaj giriş çubuğu.
class _MessageInputBar extends StatefulWidget {
  const _MessageInputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  State<_MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<_MessageInputBar> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _speech.cancel();
    super.dispose();
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
          widget.controller.text = result.recognizedWords;
          // İmleci metnin sonuna taşı
          widget.controller.selection = TextSelection.fromPosition(
            TextPosition(offset: widget.controller.text.length),
          );
        },
        localeId: 'tr_TR',
        listenOptions: SpeechListenOptions(partialResults: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                enabled: !widget.isLoading,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => widget.onSend(),
                decoration: InputDecoration(
                  hintText: 'ai_chat.input_hint'.tr(),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            // Mikrofon butonu — sadece cihaz ses tanımayı destekliyorsa gösterilir
            if (_speechEnabled)
              IconButton(
                onPressed: widget.isLoading ? null : _toggleListening,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    key: ValueKey(_isListening),
                  ),
                ),
                color: _isListening ? Colors.red : const Color(0xFF6750A4),
                tooltip: _isListening ? 'Kaydı durdur' : 'Sesle yaz',
              ),
            SizedBox(width: AppSpacing.xs),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 48,
                      height: 48,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF6750A4),
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: widget.onSend,
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        minimumSize: const Size(48, 48),
                      ),
                      tooltip: 'ai_chat.send'.tr(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
