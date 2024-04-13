package com.example.gemma

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.collect

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.llm_inference"
    private val STREAM_CHANNEL = "com.example.llm_inference/stream"
    private var inferenceModel: InferenceModel? = null
    private val coroutineScope = CoroutineScope(Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel 설정
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "generateText" -> {
                    val prompt = call.argument<String>("prompt")!!
                    inferenceModel?.generateResponseAsync(prompt)
                    result.success("메시지 응답 대기중") // 응답이 스트림을 통해 전송됨
                }
                "initializeModel" -> {
                    initializeModel()
                    result.success("모델 초기화 완료")
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel 설정
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM_CHANNEL).setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        coroutineScope.launch {
                            inferenceModel?.partialResults?.collect { (response, done) ->
                                events?.success(mapOf("text" to response, "done" to done))
                            }
                        }
                    }

                    override fun onCancel(arguments: Any?) {
                        // 스트림 취소 로직 (필요한 경우)
                    }
                }
        )
    }

    private fun initializeModel() {
        // InferenceModel 인스턴스 초기화
        inferenceModel = InferenceModel.getInstance(this)
    }

    override fun onDestroy() {
        coroutineScope.cancel() // CoroutineScope 정리
        super.onDestroy()
    }
}
