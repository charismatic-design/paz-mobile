import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/paz_theme.dart';
import '../../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> suggestions;
  final bool isQuotaLimit;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.suggestions = const [],
    this.isQuotaLimit = false,
  });
}

class AskPazScreen extends StatefulWidget {
  final List<ChatMessage>? initialMessages;
  const AskPazScreen({super.key, this.initialMessages});

  @override
  State<AskPazScreen> createState() => _AskPazScreenState();
}

class _AskPazScreenState extends State<AskPazScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  final List<String> _defaultSuggestions = [
    'Best bank for \$1,000 today',
    'Compare NBE T-Bills vs Physical Gold',
    'Physical Gold 24K price per gram',
    'Explain the floating exchange rate reform',
  ];

  static final Set<String> _staticStarterPrompts = {
    'best bank for 1000 today',
    'estimate my portfolio value',
    'compare nbe tbills vs physical gold',
    'compare nbe t bills vs physical gold',
    'physical gold 24k price per gram',
    'explain the floating exchange rate reform',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialMessages != null) {
      _messages.addAll(widget.initialMessages!);
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static String _normalizePrompt(String s) {
    return s
        .toLowerCase()
        .replaceAll(r'$', '')
        .replaceAll(r'\$', '')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<String> _filterDynamicSuggestions(List<String> incoming, String userPrompt) {
    final normUser = _normalizePrompt(userPrompt);
    final List<String> result = [];
    final seen = <String>{};

    for (final s in incoming) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) continue;

      final norm = _normalizePrompt(trimmed);
      if (norm.isEmpty) continue;

      // Filter out if matches any static starter prompt
      if (_staticStarterPrompts.contains(norm)) continue;

      // Filter out if duplicates the user's last prompt
      if (norm == normUser) continue;

      // Filter out duplicates within the suggestions list
      if (!seen.add(norm)) continue;

      result.add(trimmed);
    }
    return result;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String messageText) async {
    final text = messageText.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();

    final userMsg = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final res = await _apiService.sendAiChat(text);
      final reply = res['reply'] as String? ?? 'No response received from PAZ.';
      final rawSuggestions = res['suggestions'] as List? ?? [];
      final incoming = rawSuggestions.map((e) => e.toString()).toList();
      final dynamicSuggestions = _filterDynamicSuggestions(incoming, text);

      final agentMsg = ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
        suggestions: dynamicSuggestions,
      );

      if (mounted) {
        setState(() {
          _messages.add(agentMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } on ApiException catch (e) {
      if (mounted) {
        final isRateLimit = e.statusCode == 429;
        final isAuthError = e.statusCode == 401;
        final String displayText;
        if (isRateLimit) {
          displayText = e.message.isNotEmpty
              ? e.message
              : "You've reached your daily Ask PAZ limit. Your quota resets at midnight UTC.";
        } else if (isAuthError) {
          displayText = 'Please sign in to your PAZ account to use Ask PAZ.';
        } else {
          displayText = 'Error contacting PAZ agent: ${e.message}\nPlease verify network connection.';
        }

        final noticeMsg = ChatMessage(
          text: displayText,
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: const [],
          isQuotaLimit: isRateLimit || isAuthError,
        );
        setState(() {
          _messages.add(noticeMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = ChatMessage(
          text: 'Error contacting PAZ agent: $e\nPlease verify network connection.',
          isUser: false,
          timestamp: DateTime.now(),
          suggestions: const [],
        );
        setState(() {
          _messages.add(errorMsg);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PazColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _messages.isEmpty ? _buildWelcomeState() : _buildMessageList(),
            ),
            if (_isLoading) _buildThinkingIndicator(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: PazColors.canvas,
        border: Border(bottom: BorderSide(color: PazColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PazColors.cardElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: PazColors.cardBorderStrong),
            ),
            child: const Icon(
              LucideIcons.terminal,
              size: 16,
              color: PazColors.emerald,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ASK PAZ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: PazColors.textPrimary,
                  ),
                ),
                Text(
                  'ETHIOPIAN MACRO-FINANCIAL INTELLIGENCE AGENT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: PazColors.textDim,
                  ),
                ),
              ],
            ),
          ),
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.rotateCcw, size: 16, color: PazColors.textDim),
              tooltip: 'Clear conversation',
              onPressed: _clearChat,
              splashRadius: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: PazTheme.cardDecoration(glow: true),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: PazColors.emerald,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PazColors.emerald,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PAZ FINANCIAL AGENT READY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: PazColors.emerald,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Institutional Macro Analysis On Demand',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: PazColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Query live floating interbank benchmarks, commercial bank FX margins, 24K gold valuations, and National Bank of Ethiopia policy shifts. Concise, zero fluff.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: PazColors.textMuted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'RECOMMENDED INQUIRIES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: PazColors.textDim,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _defaultSuggestions.map((suggestion) {
              return InkWell(
                onTap: () => _sendMessage(suggestion),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: PazColors.card,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: PazColors.cardBorderStrong),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.arrowUpRight, size: 12, color: PazColors.emerald),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          suggestion,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: PazColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isLatest = (index == _messages.length - 1);
        return _buildMessageBubble(msg, isLatest: isLatest);
      },
    );
  }

  MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext context) {
    return MarkdownStyleSheet(
      p: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: PazColors.textPrimary,
        height: 1.45,
      ),
      h1: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: PazColors.textPrimary,
      ),
      h2: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: PazColors.textPrimary,
      ),
      h3: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: PazColors.textPrimary,
      ),
      h4: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: PazColors.textSecondary,
      ),
      strong: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: PazColors.textPrimary,
      ),
      em: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: PazColors.textSecondary,
      ),
      listBullet: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: PazColors.emerald,
      ),
      listBulletPadding: const EdgeInsets.only(right: 6),
      code: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        color: PazColors.emerald,
        backgroundColor: PazColors.canvas,
      ),
      codeblockPadding: const EdgeInsets.all(10),
      codeblockDecoration: BoxDecoration(
        color: PazColors.canvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: PazColors.cardBorder),
      ),
      blockquote: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: PazColors.textSecondary,
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: PazColors.emerald, width: 3)),
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: PazColors.cardBorderStrong, width: 1)),
      ),
      a: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: PazColors.emerald,
        decoration: TextDecoration.underline,
      ),
      tableHead: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: PazColors.textPrimary,
      ),
      tableBody: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: PazColors.textSecondary,
      ),
      tableBorder: TableBorder.all(color: PazColors.cardBorder, width: 1),
      blockSpacing: 8,
      listIndent: 16,
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, {bool isLatest = false}) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PazColors.cardElevated,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(2),
            ),
            border: Border.all(color: PazColors.cardBorderStrong),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: PazColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.88,
          ),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: msg.isQuotaLimit ? PazColors.amberMuted : PazColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: msg.isQuotaLimit
                  ? PazColors.amber.withValues(alpha: 0.35)
                  : PazColors.cardBorder,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3.5,
                  child: Container(
                    color: msg.isQuotaLimit ? PazColors.amber : PazColors.emerald,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            msg.isQuotaLimit ? LucideIcons.clock : LucideIcons.terminal,
                            size: 12,
                            color: msg.isQuotaLimit ? PazColors.amber : PazColors.emerald,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              msg.isQuotaLimit ? 'DAILY QUOTA NOTICE' : 'PAZ INTELLIGENCE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: msg.isQuotaLimit ? PazColors.amber : PazColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: msg.text.trim(),
                        selectable: true,
                        styleSheet: _buildMarkdownStyleSheet(context),
                      ),
                      if (isLatest && !msg.isUser && msg.suggestions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 12, color: PazColors.cardBorder),
                        const SizedBox(height: 4),
                        Text(
                          'FOLLOW-UP SUGGESTIONS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: PazColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: msg.suggestions.map((suggestion) {
                            return InkWell(
                              onTap: () => _sendMessage(suggestion),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: PazColors.canvas,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: PazColors.cardBorderStrong),
                                ),
                                child: Text(
                                  suggestion,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: PazColors.emerald,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildThinkingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: PazColors.emerald,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'PAZ is analyzing market data...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: PazColors.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: PazColors.surface,
        border: Border(top: BorderSide(color: PazColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_isLoading,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: PazColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Ask about floating rates, banks, gold...',
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: PazColors.textDim,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: _isLoading ? PazColors.cardElevated : PazColors.emerald,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(
                LucideIcons.arrowUp,
                size: 18,
                color: _isLoading ? PazColors.textDim : PazColors.canvas,
              ),
              onPressed: _isLoading ? null : () => _sendMessage(_inputController.text),
              splashRadius: 20,
            ),
          ),
        ],
      ),
    );
  }
}
