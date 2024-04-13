import 'dart:async';

StreamTransformer<dynamic, String> createTextCollector() {
  String combinedText = "";
  Timer? timer;

  return StreamTransformer.fromHandlers(
    handleData: (data, sink) {
      combinedText += data["text"] as String;
      timer?.cancel(); // 기존 타이머가 있으면 취소

      // 1초 동안 다른 데이터가 없으면, 최종 텍스트를 sink에 추가
      timer = Timer(Duration(seconds: 1), () {
        sink.add(combinedText);
        combinedText = ""; // 다음 입력을 위해 문자열 초기화
      });
    },
    handleError: (error, stacktrace, sink) {
      sink.addError(error, stacktrace);
    },
    handleDone: (sink) {
      timer?.cancel(); // 스트림이 종료될 때 타이머 취소
      sink.close();
    },
  );
}
