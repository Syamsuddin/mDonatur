// Strip hari ini (docs/26_UI_CONVENTIONS.md §Inventaris): satu baris teksLemah
// "Total input hari ini (N×): Rp X" dari server (P2.1, P2.5). Huruf mengecil bila tidak muat,
// sehingga baris tidak terlipat dan nominal tidak terpotong.

import 'package:flutter/material.dart';

import '../tema.dart';
import '../util/rupiah.dart';

class StripHariIni extends StatelessWidget {
  const StripHariIni({super.key, required this.total, required this.transaksi});

  final int total;
  final int transaksi;

  @override
  Widget build(BuildContext context) {
    final gaya = Theme.of(context).textTheme.bodyMedium!.copyWith(color: Warna.teksLemah);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        'Total input hari ini ($transaksi×): ${formatRupiah(total)}',
        style: gaya,
        maxLines: 1,
      ),
    );
  }
}
