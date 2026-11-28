package com.mibolsillo.app

import android.app.Activity
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.hardware.biometrics.BiometricManager
import android.hardware.biometrics.BiometricPrompt
import android.os.Build
import android.os.CancellationSignal
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel

internal class DeviceAuthentication(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null
    private var cancellation: CancellationSignal? = null
    private val keyguard get() = activity.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
    fun handle(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "configured" -> result.success(keyguard.isDeviceSecure)
                "settings" -> { activity.startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS)); result.success(null) }
                "databaseKey" -> result.success(LocalVault.databaseKey(activity))
                "authenticate" -> authenticate((call.arguments as? String)?.take(120) ?: "Confirma tu identidad", result)
                else -> result.notImplemented()
            }
        } catch (_: Exception) {
            pending = null
            result.error("security_unavailable", "No se pudo verificar la seguridad del dispositivo", null)
        }
    }
    private fun authenticate(reason: String, result: MethodChannel.Result) {
        if (pending != null || !keyguard.isDeviceSecure) { result.success(false); return }
        pending = result
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            cancellation = CancellationSignal()
            BiometricPrompt.Builder(activity)
                .setTitle("Mi Bolsillo").setSubtitle(reason)
                .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_STRONG or BiometricManager.Authenticators.DEVICE_CREDENTIAL)
                .build().authenticate(cancellation!!, activity.mainExecutor, object : BiometricPrompt.AuthenticationCallback() {
                    override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) { finish(true) }
                    override fun onAuthenticationError(errorCode: Int, errString: CharSequence) { finish(false) }
                })
        } else {
            @Suppress("DEPRECATION")
            val intent = keyguard.createConfirmDeviceCredentialIntent("Mi Bolsillo", reason)
            if (intent == null) finish(false) else activity.startActivityForResult(intent, REQUEST)
        }
    }
    fun activityResult(request: Int, result: Int): Boolean {
        if (request != REQUEST) return false
        finish(result == Activity.RESULT_OK)
        return true
    }
    private fun finish(accepted: Boolean) {
        val result = pending
        pending = null
        cancellation = null
        result?.success(accepted)
    }
    fun dispose() { cancellation?.cancel(); finish(false) }
    companion object { private const val REQUEST = 8274 }
}
