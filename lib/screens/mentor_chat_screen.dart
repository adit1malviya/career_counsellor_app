import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import '../theme/app_theme.dart';
import '../services/chat_service.dart';

// --- Data Model ---
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
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: json['sender_id']?.toString() ?? '',
      message: json['message'] ?? '',
      sentAt: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : (json['sent_at'] != null ? DateTime.tryParse(json['sent_at']) ?? DateTime.now() : DateTime.now()),
      isMe: (json['is_me'] == true) || (json['sender_id'] != null && json['sender_id'] == currentUserId),
    );
  }
}

class MentorChatScreen extends StatefulWidget {
  final Function(bool)? onChatToggle;
  const MentorChatScreen({super.key, this.onChatToggle});

  @override
  State<MentorChatScreen> createState() => _MentorChatScreenState();
}

class _MentorChatScreenState extends State<MentorChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  WebSocketChannel? _channel;
  StreamSubscription? _wsSub;
  bool _isConnected = false;

  bool _isViewingIndividualChat = false;
  String _currentChatPartner = "";
  String _currentChatPartnerId = "";
  String _currentUserId = "";
  String _inputText = "";

  List<dynamic> _pendingRequests = [];
  List<dynamic> _activeChats = [];
  List<ChatMessage> _messages = [];

  bool _isLoadingRequests = false;
  bool _isLoadingChats = false;
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _initMentorData();
  }

  @override
  void dispose() {
    _disconnectWebSocket();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initMentorData() async {
    try {
      final token = await _chatService.getAuthToken();
      if (token != null) {
        await _fetchInitialData();
      }
    } catch (e) {
      debugPrint("Init Error: $e");
    }
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchRequests(), _fetchActiveChats()]);
  }

  Future<void> _fetchActiveChats() async {
    if (mounted) setState(() => _isLoadingChats = true);
    try {
      final data = await _chatService.getChatConnections();
      if (mounted) {
        setState(() {
          _activeChats = data;
          _isLoadingChats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingChats = false);
    }
  }

  Future<void> _fetchRequests({Function? onUpdate}) async {
    if (mounted) setState(() => _isLoadingRequests = true);
    try {
      final data = await _chatService.getPendingRequests();
      if (mounted) {
        setState(() {
          _pendingRequests = data;
          _isLoadingRequests = false;
        });
        if (onUpdate != null) onUpdate();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  void _connectWebSocket(String studentUserId) async {
    _disconnectWebSocket();
    final token = await _chatService.getAuthToken();
    if (token == null) return;
    final wsUrl = _chatService.baseUrl.replaceFirst('http', 'ws');
    final uri = Uri.parse('$wsUrl/api/v1/mentorship/chat/$studentUserId/?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      setState(() => _isConnected = true);
      _wsSub = _channel!.stream.listen((raw) {
        final data = jsonDecode(raw);
        if (data['event'] == 'NEW_MESSAGE') {
          setState(() {
            _messages.add(ChatMessage.fromJson(data, _currentUserId));
          });
          _scrollToBottom();
        }
      }, onDone: () => setState(() => _isConnected = false));
    } catch (e) {
      debugPrint("WebSocket Connection Error: $e");
    }
  }

  void _disconnectWebSocket() {
    _wsSub?.cancel();
    _channel?.sink.close(ws_status.goingAway);
    _isConnected = false;
  }

  Future<void> _loadHistory(String studentUserId) async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _chatService.getChatMessages(studentUserId);
      setState(() {
        _messages = history.map((m) => ChatMessage.fromJson(m, _currentUserId)).toList();
        _isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  void _handleSendMessage() {
    if (_inputText.trim().isEmpty || !_isConnected) return;
    final payload = jsonEncode({'message': _inputText.trim()});
    _channel?.sink.add(payload);
    _messageController.clear();
    setState(() => _inputText = "");
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

  void _handleRequestAction(String requestId, bool isAccept) async {
    final backupList = List.from(_pendingRequests);
    setState(() => _pendingRequests.removeWhere((req) => req['request_id'] == requestId));
    final success = isAccept
        ? await _chatService.acceptRequest(requestId)
        : await _chatService.rejectRequest(requestId);
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAccept ? "Request Accepted!" : "Request Rejected"),
            backgroundColor: isAccept ? Colors.green : Colors.redAccent));
      }
      _fetchRequests();
      _fetchActiveChats();
    } else {
      if (mounted) setState(() => _pendingRequests = backupList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isViewingIndividualChat,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_isViewingIndividualChat) {
          _disconnectWebSocket();
          setState(() => _isViewingIndividualChat = false);
          widget.onChatToggle?.call(false);
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: _buildChatListAppBar(),
            body: _buildChatListView(),
          ),
          if (_isViewingIndividualChat)
            Positioned.fill(
              child: Material(
                child: Scaffold(
                  backgroundColor: const Color(0xFFF5F7F9),
                  appBar: _buildChatDetailAppBar(),
                  body: _buildIndividualChatView(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildChatListAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text("Messages",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 26)),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.person_add_outlined, color: Colors.black87, size: 28),
              onPressed: () => _showRequestsOverlay(context),
            ),
            if (_pendingRequests.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text("${_pendingRequests.length}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PreferredSizeWidget _buildChatDetailAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          _disconnectWebSocket();
          setState(() => _isViewingIndividualChat = false);
          widget.onChatToggle?.call(false);
        },
      ),
      title: Row(
        children: [
          CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$_currentChatPartnerId')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentChatPartner, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(_isConnected ? "online" : "offline", style: TextStyle(color: _isConnected ? Colors.green : Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_rounded, color: AppTheme.mentor, size: 26),
          onPressed: () {},
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildChatListView() {
    if (_isLoadingChats) return const Center(child: CircularProgressIndicator(color: AppTheme.mentor));
    if (_activeChats.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchActiveChats,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(child: Text("No active students yet", style: TextStyle(color: Colors.grey))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchActiveChats,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _activeChats.length,
        itemBuilder: (context, index) {
          final student = _activeChats[index];
          final String sId = student['user_id'].toString();
          final String sName = student['full_name'] ?? "Student";

          // ✅ Updated UI: White card with thin green border
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                  color: AppTheme.mentor.withValues(alpha: 0.15),
                  width: 1.5
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.mentor.withValues(alpha: 0.1), width: 2),
                ),
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$sId'),
                ),
              ),
              title: Text(sName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF172B4D))),
              subtitle: Text("Tap to view messages", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              trailing: Icon(Icons.chevron_right, color: AppTheme.mentor.withValues(alpha: 0.5)),
              onTap: () {
                setState(() {
                  _isViewingIndividualChat = true;
                  _currentChatPartner = sName;
                  _currentChatPartnerId = sId;
                });
                widget.onChatToggle?.call(true);
                _loadHistory(sId);
                _connectWebSocket(sId);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndividualChatView() {
    return Column(
      children: [
        Expanded(
          child: _isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
            color: msg.isMe ? AppTheme.mentor : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(msg.isMe ? 15 : 0),
              bottomRight: Radius.circular(msg.isMe ? 0 : 15),
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2)
              )
            ]),
        child: Text(msg.message,
            style: TextStyle(fontSize: 15, color: msg.isMe ? Colors.white : Colors.black87)),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2)
            )
          ]),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: (v) => setState(() => _inputText = v),
                decoration: const InputDecoration(
                    hintText: "Type a message...", border: InputBorder.none, hintStyle: TextStyle(color: Colors.grey)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSendMessage,
            child: CircleAvatar(
              backgroundColor: AppTheme.mentor,
              radius: 24,
              child: Icon(_inputText.trim().isEmpty ? Icons.mic : Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestsOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text("Student Requests", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (_isLoadingRequests && _pendingRequests.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_pendingRequests.isEmpty)
              const Expanded(child: Center(child: Text("No pending requests")))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final req = _pendingRequests[index];
                    return Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: AppTheme.mentor.withValues(alpha: 0.1))
                      ),
                      child: ListTile(
                        leading: CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${req['student_id']}')),
                        title: Text(req['student_name'] ?? "New Student", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(req['message'] ?? "Wants mentorship"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                onPressed: () => _handleRequestAction(req['request_id'], true)),
                            IconButton(
                                icon: const Icon(Icons.cancel, color: Colors.redAccent),
                                onPressed: () => _handleRequestAction(req['request_id'], false)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}