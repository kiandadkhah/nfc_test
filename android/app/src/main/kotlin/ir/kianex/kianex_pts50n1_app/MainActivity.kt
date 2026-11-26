package ir.kianex.kianex_pts50n1_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.nfc.NfcManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /// v4.1 system gate — opens the Android NFC settings panel, which no
    /// Flutter plugin exposes. Location/app settings are handled by
    /// geolocator; NFC needs this native channel.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kianex/system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNfcSettings" -> {
                        try {
                            startActivity(
                                Intent(Settings.ACTION_NFC_SETTINGS)
                                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            )
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("unavailable", e.message, null)
                        }
                    }
                    "hasNfcHardware" -> {
                        val manager = getSystemService(Context.NFC_SERVICE) as NfcManager
                        result.success(manager.defaultAdapter != null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
