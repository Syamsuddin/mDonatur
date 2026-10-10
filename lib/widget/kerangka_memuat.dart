// Kerangka memuat (docs/26_UI_CONVENTIONS.md §Inventaris): Skeletonizer berisi tulang baris (Bone),
// tanpa teks tiruan. Tulang garisLembut berkilau ke latarDasbor (gerak kilau), statis bila Hapus
// animasi aktif; di kepala tulangnya pilKepala berkilau ke primerTerang. Juga indikator 20 dp di dalam
// tombol nonaktif.

import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../tema.dart';

class KerangkaMemuat extends StatelessWidget {
  /// [baris] baris daftar di dalam kartu: avatar, dua baris teks, dan nominal.
  const KerangkaMemuat({super.key, this.baris = 3}) : diKepala = false;

  /// Satu baris ringkasan di kepala (label dan nominal besar), di atas gradien.
  const KerangkaMemuat.kepala({super.key})
      : baris = 1,
        diKepala = true;

  final int baris;
  final bool diKepala;

  @override
  Widget build(BuildContext context) {
    final dasar = diKepala ? Warna.pilKepala : Warna.garisLembut;
    final sorot = diKepala ? Warna.primerTerang : Warna.latarDasbor;
    final PaintingEffect efek = Gerak.aktif(context)
        ? ShimmerEffect(baseColor: dasar, highlightColor: sorot, duration: Gerak.kilau)
        : SolidColorEffect(color: dasar);
    final teks = Theme.of(context).textTheme;
    final tulang = diKepala
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Bone.text(words: 3, style: teks.bodyMedium),
              const SizedBox(height: Jarak.j4),
              Bone.text(words: 2, style: teks.displaySmall),
            ],
          )
        : Column(
            children: [
              for (var i = 0; i < baris; i++)
                Padding(
                  padding: const EdgeInsets.all(Jarak.isiKartu),
                  child: Row(
                    children: [
                      const Bone.circle(size: Bentuk.avatar),
                      const SizedBox(width: Jarak.j12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(words: 3, style: teks.bodyLarge),
                            const SizedBox(height: Jarak.j4),
                            Bone.text(words: 2, style: teks.bodyMedium),
                          ],
                        ),
                      ),
                      const SizedBox(width: Jarak.j12),
                      Bone.text(words: 1, style: teks.bodyLarge),
                    ],
                  ),
                ),
            ],
          );
    // Kartu di luar Skeletonizer: hanya tulangnya yang berkilau, kartunya tetap putih.
    final kerangka = Skeletonizer(effect: efek, child: tulang);
    return Semantics(
      label: 'Memuat',
      child: ExcludeSemantics(child: diKepala ? kerangka : Card(child: kerangka)),
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
