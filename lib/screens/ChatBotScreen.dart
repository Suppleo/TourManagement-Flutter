import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tour_provider.dart';
import '../core/gemini_service.dart';
import '../models/tour.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _messages.add({
      'role': 'bot',
      'text': '👋 Chào bạn! Tôi là trợ lý du lịch AI. Bạn muốn hỏi gì về tour?',
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'text': input,
        'timestamp': DateTime.now(),
      });
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    String response;
    final location = _detectLocation(input);

    try {
      if (location != null) {
        final tours = await context.read<TourProvider>().searchToursByLocation(location);
        if (tours.isEmpty) {
          response = '😢 Không có tour nào đến $location. Bạn hãy thử địa điểm khác nhé!';
        } else {
          final prompt = _buildGeminiPromptForTours(tours, input);
          response = await GeminiService.sendMessage(prompt);
        }
      } else {
        response = await GeminiService.sendMessage(
          'Trả lời ngắn gọn dưới 100 từ: $input',
        );
      }
    } catch (e) {
      response = '❌ Đã xảy ra lỗi khi kết nối Gemini. Thử lại sau!';
    }

    setState(() {
      _messages.add({
        'role': 'bot',
        'text': response,
        'timestamp': DateTime.now(),
      });
      _isLoading = false;
    });

    _scrollToBottom();
  }

  String? _detectLocation(String text) {
    const locations = ['Đà Lạt', 'Hà Nội', 'Hạ Long', 'Phú Quốc', 'Đà Nẵng', 'Bali, Indonesia'];
    return locations.firstWhere(
          (loc) => text.toLowerCase().contains(loc.toLowerCase()),
      orElse: () => '',
    ).isEmpty
        ? null
        : locations.firstWhere((loc) => text.toLowerCase().contains(loc.toLowerCase()));
  }

  String _buildGeminiPromptForTours(List<Tour> tours, String question) {
    final info = tours.map((t) => '''
🏷️ ${t.title}
💰 Giá: ${t.price.toStringAsFixed(0)} VND
📍 Địa điểm: ${t.location ?? 'Không rõ'}
${t.itinerary != null ? '📅 Lịch trình: ${t.itinerary}' : ''}
''').join('\n');

    return '''
Dựa vào danh sách tour dưới đây, hãy trả lời câu hỏi sau: "$question"

$info

Trả lời ngắn gọn dưới 100 từ, bằng tiếng Việt, dễ hiểu, có cảm xúc và emoji nếu phù hợp.
''';
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              msg['text'] ?? '',
              style: TextStyle(color: isUser ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(msg['timestamp']),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: CircleAvatar(child: Icon(Icons.smart_toy)),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (_, __) {
            return Row(
              children: List.generate(3, (i) {
                final value = (_animation.value + i * 0.3) % 1;
                final opacity = (0.3 + 0.7 * value).clamp(0.0, 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(width: 8),
        const Text('Đang trả lời...', style: TextStyle(fontStyle: FontStyle.italic)),
      ],
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trợ lý Du lịch AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Bắt đầu lại',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'bot',
                  'text': '👋 Chào bạn! Tôi là trợ lý du lịch AI. Bạn muốn hỏi gì về tour?',
                  'timestamp': DateTime.now(),
                });
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Bạn muốn hỏi gì về tour?',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                      color: _isLoading ? Colors.grey : Colors.blue,
                    ),
                    onPressed: _isLoading ? null : _sendMessage,
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
