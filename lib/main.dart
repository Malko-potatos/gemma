import 'package:flutter/material.dart';
import 'LlmInferenceStream.dart'; // LLMService 정의를 포함한 Dart 파일을
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController controller = TextEditingController();
  final LlmInferenceStream llmInferenceStream = LlmInferenceStream();
  final List<Map<String, dynamic>> messages = [];
  late stt.SpeechToText speech;
  late FlutterTts flutterTts;

  bool isListening = false;

  @override
  void initState() {
    super.initState();
    initializeModel();
    speech = stt.SpeechToText();
    flutterTts = FlutterTts();
  }

  Future speak(String text) async {
    await flutterTts.speak(text);
  }

  void listen() async {
    if (!isListening) {
      bool available = await speech.initialize(
          onStatus: (val) => print('onStatus: $val'),
          onError: (val) => print('onError: $val'));
      if (available) {
        setState(() => isListening = true);
        speech.listen(
            onResult: (val) => setState(() {
                  controller.text = val.recognizedWords;
                  if (val.hasConfidenceRating && val.confidence > 0) {
                    // STT 처리 완료 후 자동으로 메시지 전송
                    sendMessage();
                  }
                }));
      }
    } else {
      setState(() => isListening = false);
      speech.stop();
    }
  }

  void initializeModel() async {
    final result = await LLMService.initializeModel();
    print(result);
  }

  void sendMessage() {
    final text = controller.text;
    if (text.isNotEmpty) {
      // 사용자가 입력한 프롬프트를 메시지 목록에 추가
      setState(() {
        messages.insert(0, {"text": text, "isUser": true});
      });
      // Android 네이티브 코드로 프롬프트 전송 및 처리 요청
      LLMService.generateText(text);
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LLM Chat')),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<Map<String, dynamic>>(
              stream: llmInferenceStream.partialResultsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final data = snapshot.data!;
                  final text = data["text"] as String;
                  // 생성된 텍스트를 메시지 목록에 추가
                  if (!messages.contains(data)) {
                    messages.insert(0, {"text": text, "isUser": false});
                  }
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    print(message);
                    // speak(messages[index] as String);
                    return ListTile(
                      title: Text(message["text"]),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration:
                        const InputDecoration(hintText: "Enter your prompt"),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                IconButton(onPressed: listen, icon: const Icon(Icons.mic)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
