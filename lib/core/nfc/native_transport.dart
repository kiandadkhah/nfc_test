/// Native NFC-V transport — the Dart side of the `kianex/nfc` platform
/// channel implemented in MainActivity.kt (v4.3).
///
/// Why a dedicated channel instead of the flutter_nfc_kit plugin:
/// the app needs EXCLUSIVE access to the NFC adapter for its whole
/// foreground lifetime (v4.1/v4.2 field reports: Android kept opening the
/// NDEF product URL in the browser during and after the transfer). The
/// native layer keeps the adapter in reader mode with SKIP_NDEF_CHECK from
/// onResume to onPause, so the tag-dispatch system is bypassed completely
/// while the app is running — and this channel provides poll / transceive /
/// finish with the exact semantics the previous plugin had:
///   · poll(timeout)  → raw tag id hex (LSB-first) or null on timeout;
///   · transceive     → raw ISO 15693 frame exchange, response INCLUDING
///                      the trailing CRC-16 (stripped by the link layer);
///   · finish()       → closes the tag session, reader mode stays on.
library;

import 'dart:async';

import 'package:flutter/services.dart';

import 'tag_link.dart';

class NativeNfcTransport {
  NativeNfcTransport._();

  static final NativeNfcTransport instance = NativeNfcTransport._();

  static const MethodChannel _channel = MethodChannel('kianex/nfc');

  /// Diagnostics sink — wired by the tag link to the app logger.
  void Function(String event)? onEvent;

  bool _listening = false;

  void _ensureListener() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'tagPresented') {
        final uid = call.arguments as String?;
        onEvent?.call('native: tag presented while idle (uid=${uid ?? '-'}), '
            'exclusive access held — nothing dispatched to the system');
      }
      return null;
    });
  }

  /// 'available' | 'disabled' | 'not_supported'; never throws for the
  /// missing-platform case (unit tests / desktop) — returns 'not_supported'.
  Future<String> availability() async {
    try {
      final r = await _channel.invokeMethod<String>('availability');
      return r ?? 'not_supported';
    } on MissingPluginException {
      return 'not_supported';
    } on PlatformException {
      return 'not_supported';
    }
  }

  /// Idempotent — the native layer keeps one reader-mode registration.
  Future<void> enable() async {
    try {
      await _channel.invokeMethod<bool>('enable');
    } on MissingPluginException {
      // unit-test / desktop environment
    }
  }

  Future<void> disable() async {
    try {
      await _channel.invokeMethod<void>('disable');
    } on MissingPluginException {
      // unit-test / desktop environment
    }
  }

  /// Waits for an ISO 15693 tag. Returns the raw tag id hex (LSB-first) or
  /// null when no compatible tag was presented within [timeout].
  /// Throws [TagLinkException]('not_iso15693') for a non-Type-5 tag.
  Future<String?> poll(Duration timeout) async {
    _ensureListener();
    try {
      return await _channel.invokeMethod<String>('poll', {
        'timeoutMs': timeout.inMilliseconds,
      });
    } on MissingPluginException {
      throw const TagLinkException('no_tag');
    } on PlatformException catch (e) {
      if (e.code == 'not_iso15693') {
        throw const TagLinkException('not_iso15693');
      }
      if (e.code == 'busy') {
        throw const TagLinkException('poll_busy');
      }
      throw TagLinkException('io_poll_error:${e.message ?? e.code}');
    }
  }

  Future<Uint8List> transceive(List<int> frame) async {
    final resp = await _channel.invokeMethod<Uint8List>('transceive', {
      'data': Uint8List.fromList(frame),
    });
    return resp ?? Uint8List(0);
  }

  Future<void> finish() async {
    try {
      await _channel.invokeMethod<void>('finish');
    } on MissingPluginException {
      // unit-test / desktop environment
    } on PlatformException {
      // session already closed by the platform
    }
  }
}
