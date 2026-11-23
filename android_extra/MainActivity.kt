package com.dizs.dizsware

import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import rikka.shizuku.Shizuku
import java.io.BufferedReader
import java.io.InputStreamReader

class MainActivity : FlutterActivity() {
    private val channelName = "dizs/core"
    private val reqCode = 4242
    private var pendingResult: MethodChannel.Result? = null

    private val permListener = Shizuku.OnRequestPermissionResultListener { code, grant ->
        if (code == reqCode) {
            pendingResult?.success(grant == PackageManager.PERMISSION_GRANTED)
            pendingResult = null
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Shizuku.addRequestPermissionResultListener(permListener)
    }

    override fun onDestroy() {
        Shizuku.removeRequestPermissionResultListener(permListener)
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "info" -> result.success(deviceInfo())
                    "requestShizuku" -> requestShizuku(result)
                    "exec" -> {
                        val cmd = call.argument<String>("cmd") ?: ""
                        Thread {
                            val out = exec(cmd)
                            runOnUiThread { result.success(out) }
                        }.start()
                    }
                    "launch" -> {
                        val pkg = call.argument<String>("pkg") ?: ""
                        val intent = packageManager.getLaunchIntentForPackage(pkg)
                        if (intent == null) {
                            result.success(false)
                        } else {
                            startActivity(intent)
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun shizukuState(): String = when {
        !Shizuku.pingBinder() -> "tidak aktif"
        Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED -> "aktif, izin ok"
        else -> "aktif, izin belum"
    }

    private fun deviceInfo(): Map<String, Any> {
        val bm = getSystemService(BATTERY_SERVICE) as BatteryManager
        val level = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return mapOf(
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "android" to Build.VERSION.RELEASE,
            "sdk" to Build.VERSION.SDK_INT.toString(),
            "battery" to "$level%",
            "androidId" to (Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: "-"),
            "shizuku" to shizukuState()
        )
    }

    private fun requestShizuku(result: MethodChannel.Result) {
        if (!Shizuku.pingBinder()) {
            result.success(false)
            return
        }
        if (Shizuku.checkSelfPermission() == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
            return
        }
        pendingResult = result
        Shizuku.requestPermission(reqCode)
    }

    private fun exec(cmd: String): String {
        if (!Shizuku.pingBinder()) return "Shizuku belum aktif"
        if (Shizuku.checkSelfPermission() != PackageManager.PERMISSION_GRANTED) {
            return "Izin Shizuku belum diberikan"
        }
        return try {
            val m = Shizuku::class.java.getDeclaredMethod(
                "newProcess",
                Array<String>::class.java,
                Array<String>::class.java,
                String::class.java
            )
            m.isAccessible = true
            val p = m.invoke(null, arrayOf("sh", "-c", cmd), null, null) as Process
            val out = BufferedReader(InputStreamReader(p.inputStream)).readText()
            val err = BufferedReader(InputStreamReader(p.errorStream)).readText()
            p.waitFor()
            (out + err).trim()
        } catch (e: Exception) {
            "error: ${e.message}"
        }
    }
}
