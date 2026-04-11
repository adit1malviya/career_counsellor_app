import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../theme/app_theme.dart';
import '../services/assessment_service.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final bool isMe;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.sentAt,
    required this.isMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, String currentUserId) {
    return ChatMessage(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['sender_id'] ?? '',
      message: json['message'] ?? '',
      sentAt: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : (json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at']) ?? DateTime.now()
          : DateTime.now()),
      isMe: (json['is_me'] == true) ||
          (json['sender_id'] != null && json['sender_id'] == currentUserId),
    );
  }
}

enum WsState { connecting, connected, error, disconnected }

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole;
  final String avatarUrl;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    required this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final AssessmentService _apiService = AssessmentService();

  String get _wsBaseUrl => _apiService.baseUrl
      .replaceFirst(RegExp(r'^https://'), 'wss://')
      .replaceFirst(RegExp(r'^http://'), 'ws://');

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;

  final List<ChatMessage> _messages = [];
  WsState _wsState = WsState.connecting;
  String _errorMessage = '';

  String _currentUserId = '';
  bool _isLoadingHistory = true;
  bool _otherUserOnline = false;
  String? _cachedToken;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _dotAnimController;

  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _initChat();
  }

  @override
  void dispose() {
    _dotAnimController.dispose();
    _wsSub?.cancel();
    _channel?.sink.close(ws_status.goingAway);
    _scrollController.dispose();
    _msgController.dispose();
    _reconnectTimer?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    try {
      final profile = await _apiService.getUserProfile();
      _currentUserId = profile['user_id']?.toString() ?? '';
      _cachedToken = await _apiService.getAuthToken();
      await _fetchHistory();
      _connectWebSocket(_cachedToken!);
    } catch (e) {
      if (mounted) {
        setState(() {
          _wsState = WsState.error;
          _errorMessage = 'Failed to initialise chat. Please try again.';
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final history = await _apiService.getChatMessages(widget.otherUserId);
      if (mounted) {
        setState(() {
          _messages.clear();
          for (final m in history) {
            _messages.add(
              ChatMessage.fromJson(m as Map<String, dynamic>, _currentUserId),
            );
          }
          _isLoadingHistory = false;
        });
        _scrollToBottom(animate: false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  void _connectWebSocket(String token) {
    if (!mounted) return;
    setState(() => _wsState = WsState.connecting);

    final uri = Uri.parse(
      '$_wsBaseUrl/api/v1/mentorship/chat/${widget.otherUserId}/?token=$token',
    );

    try {
      _channel = WebSocketChannel.connect(uri);
      setState(() {
        _wsState = WsState.connected;
        _reconnectAttempts = 0;
      });
      _wsSub = _channel!.stream.listen(
        _onWsMessage,
        onError: _onWsError,
        onDone: _onWsDone,
      );
    } catch (e) {
      _handleWsFailure('Could not connect to chat server.');
    }
  }

  void _onWsMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = data['event'] as String?;

      switch (event) {
        case 'NEW_MESSAGE':
          final msg = ChatMessage.fromJson(data, _currentUserId);
          if (mounted) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
          break;
        case 'ERROR':
          _handleWsFailure(data['message']?.toString() ?? 'An error occurred.');
          break;
        case 'USER_ONLINE':
          if (mounted) setState(() => _otherUserOnline = true);
          break;
        case 'USER_OFFLINE':
          if (mounted) setState(() => _otherUserOnline = false);
          break;
      }
    } catch (e) {
      debugPrint('WS parse error: $e');
    }
  }

  void _onWsError(dynamic error) {
    _handleWsFailure('Connection error. Reconnecting…');
  }

  void _onWsDone() {
    if (mounted) {
      setState(() {
        _wsState = WsState.disconnected;
        _otherUserOnline = false;
      });
      _scheduleReconnect();
    }
  }

  void _handleWsFailure(String message) {
    if (!mounted) return;
    setState(() {
      _wsState = WsState.error;
      _errorMessage = message;
    });
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      if (mounted) {
        setState(() {
          _wsState = WsState.error;
          _errorMessage = 'Connection lost. Please go back and try again.';
        });
      }
      return;
    }
    _reconnectAttempts++;
    _reconnectTimer =
        Timer(Duration(seconds: 2 * _reconnectAttempts), () async {
          try {
            final token = _cachedToken ?? await _apiService.getAuthToken();
            _connectWebSocket(token);
          } catch (_) {
            _handleWsFailure('Reconnection failed.');
          }
        });
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty || _wsState != WsState.connected) return;

    try {
      _channel?.sink.add(jsonEncode({'message': text}));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to send message.'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        id: 'opt_${DateTime.now().millisecondsSinceEpoch}',
        senderId: _currentUserId,
        message: text,
        sentAt: DateTime.now(),
        isMe: true,
      ));
    });
    _msgController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildAppBar(),
          _buildConnectionBanner(),
          Expanded(child: _buildBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        left: 8,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.student,
            AppTheme.student.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.student.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                backgroundImage: NetworkImage(widget.avatarUrl),
              ),
              if (_otherUserOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _wsState == WsState.connected
                      ? (_otherUserOnline ? 'Online' : 'Connected')
                      : (_wsState == WsState.connecting
                      ? 'Connecting…'
                      : 'Offline'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner() {
    if (_wsState == WsState.connected) return const SizedBox.shrink();

    late Color bg;
    late String label;
    Widget? trailing;

    switch (_wsState) {
      case WsState.connecting:
        bg = Colors.orange.shade600;
        label = 'Connecting to chat…';
        trailing = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        );
        break;
      case WsState.disconnected:
        bg = Colors.grey.shade700;
        label = 'Reconnecting…';
        trailing = const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        );
        break;
      case WsState.error:
      default:
        bg = Colors.red.shade600;
        label = _errorMessage;
        trailing = TextButton(
          onPressed: _initChat,
          child: const Text('Retry',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        );
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingHistory) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.student));
    }
    if (_messages.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final prev = index > 0 ? _messages[index - 1] : null;
        return Column(
          children: [
            if (_shouldShowDateChip(prev, msg)) _buildDateChip(msg.sentAt),
            _buildMessageBubble(msg, index),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.student.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                size: 40, color: AppTheme.student.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            'Start your conversation with\n${widget.otherUserName}',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey.shade500, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 6),
                Text(
                  'Messages disappear after 24 hours',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateChip(ChatMessage? prev, ChatMessage curr) {
    if (prev == null) return true;
    return prev.sentAt.year != curr.sentAt.year ||
        prev.sentAt.month != curr.sentAt.month ||
        prev.sentAt.day != curr.sentAt.day;
  }

  Widget _buildDateChip(DateTime date) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    final isMe = msg.isMe;
    final isLast =
        index == _messages.length - 1 || _messages[index + 1].isMe != isMe;

    final timeStr =
        '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(top: 2, bottom: isLast ? 8 : 2),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            isLast
                ? CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(widget.avatarUrl),
            )
                : const SizedBox(width: 32),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                  colors: [
                    AppTheme.student,
                    AppTheme.student.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: isMe ? null : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe
                      ? const Radius.circular(20)
                      : (isLast
                      ? const Radius.circular(4)
                      : const Radius.circular(20)),
                  bottomRight: isMe
                      ? (isLast
                      ? const Radius.circular(4)
                      : const Radius.circular(20))
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? AppTheme.student.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey.shade400,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.7)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    final bool canSend = _wsState == WsState.connected;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F4F8),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: canSend,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: canSend ? 'Message…' : 'Connecting…',
                        hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4, bottom: 4),
                    child: IconButton(
                      icon: Icon(Icons.attach_file_rounded,
                          color: Colors.grey.shade500),
                      onPressed: canSend ? () {} : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: canSend ? _sendMessage : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: canSend
                    ? LinearGradient(
                  colors: [
                    AppTheme.student,
                    AppTheme.student.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: canSend ? null : Colors.grey.shade300,
                shape: BoxShape.circle,
                boxShadow: canSend
                    ? [
                  BoxShadow(
                      color: AppTheme.student.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
                    : [],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}