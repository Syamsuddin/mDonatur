// Ringkasan hari ini di kepala tab Input (docs/26_UI_CONVENTIONS.md §Inventaris): label "Total input
// hari ini", nominal besar berwarna aksen, dan pil "{N} transaksi", semuanya dari server (P2.1, P2.5).
// Nominal mengecil bila tidak muat, sehingga tidak terlipat atau terpotong. Dibacakan sebagai satu
// kesatuan.

import 'package:flutter/material.dart';

import '../tema.dart';
import '../util/rupiah.dart';

class StripHariIni extends StatelessWidget {
  const StripHariIni({super.key, required this.total, required this.transaksi});

  final int total;
  final int transaksi;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total input hari ini', style: teks.bodyMedium!.copyWith(color: Warna.diAtasPrimer)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRupiah(total),
                    style: teks.displaySmall!.copyWith(color: Warna.aksen),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Jarak.j8),
          Padding(
            padding: const EdgeInsets.only(bottom: Jarak.j8),
            child: PilKepala('${formatRibuan(transaksi)} transaksi'),
          ),
        ],
      ),
    );
  }
}

/// Pil di kepala: latar pilKepala, teks `kecil` diAtasPrimer.
class PilKepala extends StatelessWidget {
  const PilKepala(this.teks, {super.key});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(shape: Bentuk.pil, color: Warna.pilKepala),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Jarak.j12, vertical: Jarak.j4),
        child: Text(
          teks,
          style: Theme.of(context).textTheme.labelMedium!.copyWith(color: Warna.diAtasPrimer),
        ),
      ),
    );
  }
}
