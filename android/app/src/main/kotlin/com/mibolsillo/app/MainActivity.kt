package com.mibolsillo.app

import android.content.ComponentName
import android.content.Intent
import android.provider.Settings
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val authentication by lazy { DeviceAuthentication(this) }
    override fun onCreate(savedInstanceState: Bundle?) {
        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        super.onCreate(savedInstanceState)
    }
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!authentication.activityResult(requestCode, resultCode)) super.onActivityResult(requestCode, resultCode, data)
    }
    private fun granted(): Boolean {
        val permitted = Settings.Secure.getString(contentResolver, "enabled_notification_listeners").orEmpty()
        val component = ComponentName(this, PurchaseListener::class.java)
        return permitted.split(':').any { ComponentName.unflattenFromString(it) == component }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mibolsillo.app/security")
            .setMethodCallHandler(authentication::handle)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.mibolsillo.app/detections")
        DetectionQueue.onArrival = { channel.invokeMethod("arrival", null) }
        channel.setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "enabled" -> result.success(DetectionQueue.optedIn(this) && granted())
                    "setEnabled" -> {
                        val enable = call.arguments == true
                        DetectionQueue.enable(this, enable)
                        if (enable && !granted()) startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    "peek" -> result.success(DetectionQueue.peek(this))
                    "ack" -> {
                        DetectionQueue.ack(this, (call.arguments as List<*>).filterIsInstance<String>())
                        result.success(null)
                    }
                    "erase" -> { DetectionQueue.erase(this); result.success(null) }
                    else -> result.notImplemented()
                }
            } catch (_: Exception) {
                result.error("local_detection", "No se pudo completar la operación local", null)
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        authentication.dispose()
        DetectionQueue.onArrival = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
