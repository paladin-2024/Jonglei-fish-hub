import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  final String threadId;
  final String otherName;
  final String species;

  const ChatScreen({
    super.key,
    required this.threadId,
    required this.otherName,
    required this.species,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  final _msgCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final api = context.read<AuthProvider>().api;
      final data =
          await api.getList('/messaging/threads/${widget.threadId}/messages/');
      if (mounted) {
        setState(() {
          _messages = data.map((e) => e as Map<String, dynamic>).toList();
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _msgCtrl.text.trim();
    if (body.isEmpty) return;
    _msgCtrl.clear();
    setState(() => _sending = true);
    try {
      final api = context.read<AuthProvider>().api;
      final msg = await api.post(
        '/messaging/threads/${widget.threadId}/send/',
        {'body': body},
      ) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _messages.add(msg);
          _sending = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().currentUser;
    final myId = me?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.surfaceLow,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.onSurface, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherName,
                style: AppTextStyles.ui(15, weight: FontWeight.w800)),
            if (widget.species.isNotEmpty)
              Text(widget.species,
                  style: AppTextStyles.label(10,
                      color: AppColors.primary, weight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.onSurfaceVariant, size: 20),
            onPressed: _load,
          ),
        ],
      ),

      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 48, color: AppColors.onSurfaceFaint),
                            const SizedBox(height: 12),
                            Text('No messages yet',
                                style: AppTextStyles.ui(14,
                                    color: AppColors.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Say hello!',
                                style: AppTextStyles.ui(12,
                                    color: AppColors.onSurfaceFaint)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) {
                          final m = _messages[i];
                          final senderId = m['sender']?.toString() ?? '';
                          final isMe = senderId == myId;
                          final body = m['body']?.toString() ?? '';
                          final time = m['created_at']?.toString() ?? '';

                          return _MessageBubble(
                            body: body,
                            isMe: isMe,
                            time: time.length >= 16 ? time.substring(11, 16) : '',
                          );
                        },
                      ),
          ),

          // Input bar
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(context).padding.bottom +
                    8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppTextStyles.ui(14),
                    decoration: InputDecoration(
                      hintText: 'Type a message…',
                      hintStyle: AppTextStyles.ui(14,
                          color: AppColors.onSurfaceFaint),
                      filled: true,
                      fillColor: AppColors.surfaceLow,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Message bubble ────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String body;
  final bool isMe;
  final String time;
  const _MessageBubble(
      {required this.body, required this.isMe, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    body,
                    style: AppTextStyles.ui(14,
                        color: isMe ? Colors.white : AppColors.onSurface),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      time,
                      style: AppTextStyles.data(10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.onSurfaceFaint),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
