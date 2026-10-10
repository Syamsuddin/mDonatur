// Kerangka memuat (docs/26_UI_CONVENTIONS.md §Inventaris): blok statis warna garis tanpa animasi,
// dan indikator 20 dp di dalam tombol nonaktif.

import 'package:flutter/material.dart';

import '../tema.dart';

class KerangkaMemuat extends StatelessWidget {
  const KerangkaMemuat({super.key, this.baris = 3});

  final int baris;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat',
      child: Column(
        children: [
          for (var i = 0; i < baris; i++)
            Container(
              height: Bentuk.tinggiTombol,
              margin: const EdgeInsets.only(bottom: Jarak.j8),
              decoration: BoxDecoration(
                color: Warna.garis,
                borderRadius: BorderRadius.circular(Bentuk.radius),
              ),
            ),
        ],
      ),
    );
  }
}

/// Isi tombol yang sedang menunggu jawaban; tombolnya sendiri dibuat nonaktif oleh pemanggil.
class IndikatorTombol extends StatelessWidget {
  const IndikatorTombol({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: Bentuk.indikatorTombol,
      child: CircularProgressIndicator(semanticsLabel: 'Memuat'),
    );
  }
}
