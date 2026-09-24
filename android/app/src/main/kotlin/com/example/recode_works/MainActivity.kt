package com.example.recode_works

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_IDENTIFIER_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method != "getAndroidId") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val androidId = Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ANDROID_ID,
            )
            if (androidId.isNullOrBlank()) {
                result.error(
                    "ANDROID_ID_UNAVAILABLE",
                    "Android 기기 식별자를 읽을 수 없습니다.",
                    null,
                )
            } else {
                result.success(androidId)
            }
        }
    }

    private companion object {
        const val DEVICE_IDENTIFIER_CHANNEL = "recode_works/device_identifier"
    }
}
