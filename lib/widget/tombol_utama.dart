// Tombol utama (docs/26_UI_CONVENTIONS.md §Inventaris): FilledButton pil 52 dp di atas gradienTombol
// dengan bayangan; nonaktif berlatar garis dengan teks teksLemah. Dipakai untuk Simpan dan Masuk.
// Jenis tombolnya tetap FilledButton, sehingga semantik dan uji yang mencari FilledButton berlaku.

import 'package:flutter/material.dart';

import '../tema.dart';

class TombolUtama extends StatelessWidget {
  const TombolUtama({super.key, required this.onPressed, required this.child});

  /// `null` menonaktifkan tombol.
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final aktif = onPressed != null;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: Bentuk.pil,
        gradient: aktif ? Gradien.tombol : null,
        color: aktif ? null : Warna.garis,
        shadows: aktif ? Bayangan.tombol : null,
      ),
      child: FilledButton(style: GayaTombol.utama, onPressed: onPressed, child: child),
    );
  }
}
