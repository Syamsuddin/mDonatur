// Kunci kirim ulang (Idempotency-Key, API_CONTRACT.md §7): UUID v4 dari Random.secure.

import 'dart:math';

final _acak = Random.secure();

/// UUID v4 baru, mis. "3f2b8c1e-9d4a-4f6b-8e2c-1a7d5b9c0e3f".
String kunciBaru() {
  final b = List<int>.generate(16, (_) => _acak.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // versi 4
  b[8] = (b[8] & 0x3f) | 0x80; // varian RFC 4122
  final hex = [for (final x in b) x.toRadixString(16).padLeft(2, '0')].join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
