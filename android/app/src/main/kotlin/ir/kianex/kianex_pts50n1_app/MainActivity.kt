package ir.kianex.kianex_pts50n1_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.nfc.NfcAdapter
import android.nfc.NfcManager
import android.nfc.Tag
import android.nfc.tech.NfcV
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// v4.3 — exclusive NFC access while the app is in the foreground.
///
/// The adapter is switched to READER MODE (with SKIP_NDEF_CHECK) for the
/// whole time this activity is resumed. While reader mode is active the
/// Android tag-dispatch system is bypassed entirely: an NDEF tag tap no
/// longer produces an NDEF intent, so the onboarding product page
/// (https://kianex.co/products/…) can never open — neither between two
/// protocol sessions nor after a transfer completes (v4.1/v4.2 field
/// reports). When the app is paused the reader mode is released and the
/// system dispatch (browser / launcher app) behaves normally again.
///
/// The `kianex/nfc` channel exposes the raw ISO 15693 (NFC-V) transport the
/// Dart layer needs — poll / transceive / finish — replacing the third-party
/// flutter_nfc_kit plugin whose dispatch window was the hijack source.
class MainActivity : FlutterActivity() {
    private var nfcAdapter: NfcAdapter? = null
    private var nfcVSession: NfcV? = null
    private var pendingPoll: MethodChannel.Result? = null
    private var pollTimeout: Runnable? = null
    private var readerModeActive = false
    private var nfcChannel: MethodChannel? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // --- v4.1 system channel (settings panels) + v4.3 keep-screen-on ---
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
                    // Keeps the screen awake during a multi-minute NFC write —
                    // a screen-off would release reader mode and kill the tag
                    // session mid-protocol.
                    "setKeepScreenOn" -> {
                        val on = call.argument<Boolean>("on") ?: false
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // --- v4.3 raw NFC-V transport ---
        nfcChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "kianex/nfc")
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    when (call.method) {
                        "availability" -> {
                            val adapter = resolveAdapter()
                            when {
                                adapter == null -> result.success("not_supported")
                                !adapter.isEnabled -> result.success("disabled")
                                else -> result.success("available")
                            }
                        }
                        "enable" -> {
                            enableReaderMode()
                            result.success(readerModeActive)
                        }
                        "disable" -> {
                            disableReaderMode()
                            result.success(true)
                        }
                        "poll" -> {
                            val timeout = (call.argument<Number>("timeoutMs")?.toLong()) ?: 45000L
                            startPoll(timeout, result)
                        }
                        "transceive" -> {
                            val data = call.argument<ByteArray>("data")
                            val session = nfcVSession
                            if (session == null) {
                                result.error("no_session", "no ISO 15693 tag session", null)
                                return@setMethodCallHandler
                            }
                            try {
                                result.success(session.transceive(data))
                            } catch (e: Exception) {
                                result.error("io_error", e.message, null)
                            }
                        }
                        "finish" -> {
                            closeTagSession()
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                }
            }
    }

    private fun resolveAdapter(): NfcAdapter? {
        if (nfcAdapter == null) {
            val manager = getSystemService(Context.NFC_SERVICE) as? NfcManager
            nfcAdapter = manager?.defaultAdapter
        }
        return nfcAdapter
    }

    /// Reader mode with SKIP_NDEF_CHECK — the app owns every tag tap while
    /// it is in the foreground; no NDEF intent is produced at all.
    private fun enableReaderMode() {
        val adapter = resolveAdapter() ?: return
        if (readerModeActive) return
        try {
            adapter.enableReaderMode(
                this,
                { tag -> handleDiscoveredTag(tag) },
                NfcAdapter.FLAG_READER_NFC_A
                        or NfcAdapter.FLAG_READER_NFC_B
                        or NfcAdapter.FLAG_READER_NFC_F
                        or NfcAdapter.FLAG_READER_NFC_V
                        or NfcAdapter.FLAG_READER_SKIP_NDEF_CHECK,
                Bundle.EMPTY
            )
            readerModeActive = true
        } catch (_: Exception) {
            readerModeActive = false
        }
    }

    private fun disableReaderMode() {
        val adapter = nfcAdapter ?: return
        if (!readerModeActive) return
        try {
            adapter.disableReaderMode(this)
        } catch (_: Exception) {
            // already disabled
        }
        readerModeActive = false
    }

    /// Reader-callback thread → main thread. Completes a pending poll with a
    /// connected NfcV session, or — when no poll is pending — notifies Dart
    /// that a tag is present while the app keeps its exclusive access.
    private fun handleDiscoveredTag(tag: Tag) {
        val uidHex = (tag.id ?: ByteArray(0)).joinToString("") { "%02X".format(it) }
        val tech = if (tag.techList.any { it == NfcV::class.java.name }) NfcV.get(tag) else null
        mainHandler.post {
            val poll = pendingPoll
            if (poll != null) {
                pollTimeout?.let { mainHandler.removeCallbacks(it) }
                pollTimeout = null
                pendingPoll = null
                if (tech == null) {
                    poll.error("not_iso15693", "tag is not ISO 15693 / NFC Type 5", null)
                } else {
                    closeTagSession()
                    try {
                        tech.connect()
                        nfcVSession = tech
                        poll.success(uidHex)
                    } catch (e: Exception) {
                        poll.error("connect_failed", e.message, null)
                    }
                }
            } else {
                // Exclusive access held, no session requested — stay silent
                // (the tag is not handed to the system) and inform Dart.
                nfcChannel?.invokeMethod("tagPresented", uidHex)
            }
        }
    }

    private fun startPoll(timeoutMs: Long, result: MethodChannel.Result) {
        if (pendingPoll != null) {
            result.error("busy", "a poll is already running", null)
            return
        }
        // A stale session (tag still on the phone from a previous flow) is
        // released so the fresh poll re-discovers the tag cleanly.
        closeTagSession()
        enableReaderMode()
        pendingPoll = result
        val timeoutRunnable = Runnable {
            val poll = pendingPoll ?: return@Runnable
            pendingPoll = null
            pollTimeout = null
            poll.success(null) // timeout — the caller treats null as «no tag»
        }
        pollTimeout = timeoutRunnable
        mainHandler.postDelayed(timeoutRunnable, timeoutMs)
    }

    private fun closeTagSession() {
        val session = nfcVSession ?: return
        nfcVSession = null
        try {
            session.close()
        } catch (_: Exception) {
            // session already dead
        }
    }

    override fun onResume() {
        super.onResume()
        enableReaderMode()
    }

    override fun onPause() {
        // Cancel a pending poll (resolved as «no tag»), close the session and
        // release the adapter so background apps behave normally.
        mainHandler.post {
            val poll = pendingPoll
            if (poll != null) {
                pendingPoll = null
                pollTimeout?.let { mainHandler.removeCallbacks(it) }
                pollTimeout = null
                poll.success(null)
            }
            closeTagSession()
            disableReaderMode()
        }
        super.onPause()
    }
}
