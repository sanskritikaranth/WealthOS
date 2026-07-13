import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Access .env strings
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http; // Safe direct web requests
import '../../core/database/hive_boxes.dart';
import '../expenses/expenses_provider.dart';
import '../portfolio/portfolio_provider.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text': 'Hello! I am your Command Center AI Advisor. Ask me anything about your current budget, investments, or long-term goals!'
    }
  ];

  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  void _sendMessage() async {
    final String userQuery = _textController.text.trim();
    if (userQuery.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': userQuery});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      // 1. Gather dynamic metrics from local background providers
      final transactions = ref.read(expensesProvider);
      final totalInvestments = ref.read(portfolioProvider.notifier).calculateTotalValue();
      final Box walletBox = Hive.box(HiveBoxes.userWalletBox);
      final double startBalance = walletBox.get('mock_bank_balance', defaultValue: 500000.0);
      final double totalSpent = transactions.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
      final double netWorth = (startBalance - totalSpent) + totalInvestments;
      final double currentLiquidCash = startBalance - totalSpent;

      // 2. Format the structured financial context system prompt instructions
      final String systemInstruction = 
          'You are the specialized AI Financial Assistant inside the "Smart Money Command Center" mobile app. '
          'Live financial snapshot context: '
          '- Net Worth: ₹${netWorth.toStringAsFixed(2)} '
          '- Liquid Bank Balance: ₹${currentLiquidCash.toStringAsFixed(0)} '
          '- Total Expenses: ₹${totalSpent.toStringAsFixed(0)} '
          '- Portfolio Valuation: ₹${totalInvestments.toStringAsFixed(0)}. '
          'Rules: Respond concisely (under 4 sentences), use ₹ symbols, and base answers explicitly on these metrics.';

      // 3. Securely grab your OpenAI Key from the Environment Registry map
      final String apiKey = dotenv.get('OPENAI_API_KEY', fallback: '');
      
      // Construct the direct OpenAI REST API endpoint URL path target
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');

      // 4. Fire a standard HTTP POST network payload to OpenAI's endpoint channel matrix
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey', // OpenAI utilizes Bearer token strings
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Lightweight, high-speed execution layer
          'messages': [
            {
              'role': 'system',
              'content': systemInstruction,
            },
            {
              'role': 'user',
              'content': userQuery,
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String aiReply = responseData['choices'][0]['message']['content'].toString().trim();

        setState(() {
          _messages.add({'role': 'assistant', 'text': aiReply});
        });
      } else {
        print("OPENAI DEPLOYMENT EXCEPTION: ${response.statusCode} -> ${response.body}");
        setState(() {
          _messages.add({
            'role': 'assistant', 
            'text': 'The OpenAI engine returned an authorization or balance code error: ${response.statusCode}'
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': 'Network Error. Check internet pipeline settings.'});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final bool isUser = msg['role'] == 'user';
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? (isDark ? const Color(0xFFFF8906) : const Color(0xFF6C5CE7)) 
                        : Theme.of(context).cardColor.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C5CE7))
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(hintText: 'Ask AI...', border: InputBorder.none),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFF6C5CE7)), 
                onPressed: _sendMessage
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}