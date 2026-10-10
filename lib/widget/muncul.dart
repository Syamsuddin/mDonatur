// Gerak "cepat" (docs/26_UI_CONVENTIONS.md §Token gerak): kartu muncul memudar dari 0 dan naik 8 dp.
// Mati bila Hapus animasi aktif. Pemanggil memberi kunci baru agar gerak diulang untuk isi baru.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../tema.dart';

class Muncul extends StatelessWidget {
  const Muncul({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!Gerak.aktif(context)) return child;
    return child
        .animate()
        .fadeIn(duration: Gerak.cepat, curve: Gerak.kurva)
        .move(begin: const Offset(0, Bentuk.naikMuncul), end: Offset.zero, duration: Gerak.cepat, curve: Gerak.kurva);
  }
}
