// Lencana bintang (docs/26_UI_CONVENTIONS.md §Lencana bintang): satu baris berisi lima ikon bintang
// emas, n terisi, lalu teks "Bintang {n}", dibacakan "Bintang {n} dari 5". Nilai bintang dihitung server.

import 'package:flutter/material.dart';

import '../tema.dart';

class LencanaBintang extends StatelessWidget {
  const LencanaBintang({super.key, required this.bintang});

  static const jumlahBintang = 5;

  final int bintang;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Bintang $bintang dari $jumlahBintang',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < jumlahBintang; i++)
            Icon(
              i < bintang ? Icons.star_rounded : Icons.star_outline_rounded,
              size: Bentuk.ikonBintang,
              color: Warna.emas,
            ),
          const SizedBox(width: Jarak.j4),
          Flexible(child: Text('Bintang $bintang', style: Theme.of(context).textTheme.labelMedium)),
        ],
      ),
    );
  }
}
