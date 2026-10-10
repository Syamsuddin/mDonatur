// Kartu hasil (docs/26_UI_CONVENTIONS.md §Inventaris): pesan sukses, Nomor Register bila donatur baru
// (Tambah Donatur), nama donatur, nominal, dan jam "HH:mm WITA". Label WITA hanya di sini, karena
// sumbangan baru pasti tercatat WITA (K1).

import 'package:flutter/material.dart';

import '../tema.dart';
import '../util/rupiah.dart';
import '../util/tanggal.dart';

class KartuHasil extends StatelessWidget {
  const KartuHasil({
    super.key,
    required this.pesan,
    required this.judul,
    required this.jumlah,
    required this.waktu,
    this.nomorRegister,
  });

  final String pesan;

  /// Nama donatur.
  final String judul;
  final int jumlah;

  /// "HH:MM:SS" dari server.
  final String waktu;

  /// Nomor donatur baru, ditampilkan besar (`nomorRegister`) di atas nama.
  final int? nomorRegister;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final lemah = teks.bodyMedium!.copyWith(color: Warna.teksLemah);
    return Semantics(
      liveRegion: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Jarak.isiKartu),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pesan, style: teks.bodyMedium!.copyWith(color: Warna.teksSukses)),
              const SizedBox(height: Jarak.j8),
              if (nomorRegister case final nomor?) ...[
                Text('Nomor Register', style: lemah),
                Text('$nomor', style: teks.headlineMedium),
                const SizedBox(height: Jarak.j4),
              ],
              Text(judul, style: teks.titleLarge),
              const SizedBox(height: Jarak.j4),
              Text(formatRupiah(jumlah), style: teks.headlineSmall),
              const SizedBox(height: Jarak.j4),
              Text('${formatJam(waktu)} WITA', style: lemah),
            ],
          ),
        ),
      ),
    );
  }
}
