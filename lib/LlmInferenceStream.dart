import 'package:flutter/services.dart';

class LlmInferenceStream {
  static const _streamChannel = EventChannel('com.example.llm_inference/stream');

  Stream<Map<String, dynamic>> get partialResultsStream {
    return _streamChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event));
  }
}

class LLMService {
  // Android 측에서 생성한 MethodChannel과 동일한 이름을 사용합니다.
  static const MethodChannel _channel = MethodChannel('com.example.llm_inference');

  // Android 측의 generateText 메서드를 호출합니다.
  static Future<String> generateText(String prompt) async {
    try {
      // MethodChannel을 통해 Android 측의 메서드를 호출하고 결과를 받습니다.
      final String response = await _channel.invokeMethod('generateText', {'prompt': prompt});
      return response;
    } on PlatformException catch (e) {
      // 예외 처리: Android 측에서 메서드 호출에 실패한 경우
      print("Failed to generate text: '${e.message}'.");
      return "Error generating text.";
    }
  }
   static Future<String> initializeModel() async {
    try {
      final String result = await _channel.invokeMethod('initializeModel');
      return result; // Android로부터 받은 응답 메시지를 반환
    } on PlatformException catch (e) {
      print("Failed to initialize model: '${e.message}'.");
      return "모델 초기화 실패"; // 오류 발생 시 반환할 메시지
    }
  }
}
