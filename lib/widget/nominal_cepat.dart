// Nominal cepat (docs/26_UI_CONVENTIONS.md §Inventaris): kisi 3 kolom berisi OutlinedButton "100.000"
// tanpa "Rp", urut seperti nilai yang diberikan layar. Dibacakan sebagai "Rp 100.000". Tombol yang
// nilainya sama dengan isian Sumbangan tampil terpilih (kuningLembut, garis emas).

import 'package:flutter/material.dart';

import '../tema.dart';
import '../util/rupiah.dart';

class NominalCepat extends StatelessWidget {
  const NominalCepat({super.key, required this.nominal, required this.padaPilih, this.terpilih});

  static const kolom = 3;

  final List<int> nominal;

  /// `null` menonaktifkan semua tombol.
  final ValueChanged<int>? padaPilih;

  /// Nilai isian Sumbangan saat ini; tombol bernilai sama tampil terpilih.
  final int? terpilih;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var awal = 0; awal < nominal.length; awal += kolom) ...[
          if (awal > 0) const SizedBox(height: Jarak.antarTombol),
          Row(
            children: [
              for (var i = awal; i < awal + kolom; i++) ...[
                if (i > awal) const SizedBox(width: Jarak.antarTombol),
                Expanded(
                  child: i < nominal.length
                      ? _Tombol(nilai: nominal[i], terpilih: nominal[i] == terpilih, padaPilih: padaPilih)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _Tombol extends StatelessWidget {
  const _Tombol({required this.nilai, required this.terpilih, required this.padaPilih});

  final int nilai;
  final bool terpilih;
  final ValueChanged<int>? padaPilih;

  @override
  Widget build(BuildContext context) {
    // Satu node: tombol, labelnya, dan status terpilih dibacakan bersama.
    return MergeSemantics(
      child: Semantics(
        selected: terpilih,
        child: OutlinedButton(
          style: GayaTombol.nominal(terpilih: terpilih),
          onPressed: padaPilih == null ? null : () => padaPilih!(nilai),
          // Mengecil bila kolom terlalu sempit (skala huruf besar), agar label tetap satu baris.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(formatRibuan(nilai), semanticsLabel: formatRupiah(nilai)),
          ),
        ),
      ),
    );
  }
}
