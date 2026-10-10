// Lencana bintang (docs/26_UI_CONVENTIONS.md §Lencana bintang): "Bintang {n}" bergaya tombol, warna
// latar dan teks dari tabel token, dibacakan "Bintang {n} dari 5". Nilai bintang dihitung server.

import 'package:flutter/material.dart';

import '../tema.dart';

class LencanaBintang extends StatelessWidget {
  const LencanaBintang({super.key, required this.bintang});

  final int bintang;

  /// (latar, teks) per bintang. Teks putih hanya di atas aksi dan teksBahaya (kontras AA).
  static (Color, Color) warna(int bintang) => switch (bintang) {
        <= 1 => (Warna.info, Warna.teks),
        2 => (Warna.sukses, Warna.teks),
        3 => (Warna.aksi, Warna.diAtasPrimer),
        4 => (Warna.peringatan, Warna.teks),
        _ => (Warna.teksBahaya, Warna.diAtasPrimer),
      };

  @override
  Widget build(BuildContext context) {
    final (latar, teks) = warna(bintang);
    return Semantics(
      container: true,
      label: 'Bintang $bintang dari 5',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: latar, borderRadius: BorderRadius.circular(Bentuk.radius)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Jarak.j8, vertical: Jarak.j4),
          child: Text(
            'Bintang $bintang',
            style: Theme.of(context).textTheme.labelLarge!.copyWith(color: teks),
          ),
        ),
      ),
    );
  }
}
