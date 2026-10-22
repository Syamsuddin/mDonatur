// Kartu hasil (docs/26_UI_CONVENTIONS.md §Inventaris): lingkaran cek bergradien (gerak pop), pesan
// sukses, Nomor Register bila donatur baru (Tambah Donatur), nama donatur, nominal yang menghitung naik
// (gerak hitung), dan jam "HH:mm WITA", tebal bila note_n. Label WITA hanya di sini, karena sumbangan
// baru pasti tercatat WITA (K1). Pembaca layar selalu menerima nominal akhir. Pemanggil memberi kunci
// baru per hasil, agar gerak diulang untuk setiap simpan.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../tema.dart';
import '../util/rupiah.dart';
import '../util/tanggal.dart';
import 'muncul.dart';

class KartuHasil extends StatelessWidget {
  const KartuHasil({
    super.key,
    required this.pesan,
    required this.judul,
    required this.jumlah,
    required this.waktu,
    this.nomorRegister,
    this.noteN = false,
  });

  final String pesan;

  /// Nama donatur.
  final String judul;
  final int jumlah;

  /// "HH:MM:SS" dari server.
  final String waktu;

  /// Nomor donatur baru, ditampilkan besar (`nomorRegister`) di atas nama.
  final int? nomorRegister;

  /// Sumbangan Note n (hanya admin): jam tebal, seperti penanda `note_n` di daftar.
  final bool noteN;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final lemah = teks.bodyMedium!.copyWith(color: Warna.teksLemah);
    final gerak = Gerak.aktif(context);
    Widget cek = const _LingkaranCek();
    if (gerak) {
      cek = cek.animate().scale(
            begin: const Offset(Gerak.skalaAwalPop, Gerak.skalaAwalPop),
            end: const Offset(1, 1),
            duration: Gerak.pop,
            curve: Gerak.kurvaPop,
          );
    }
    return Semantics(
      liveRegion: true,
      child: Muncul(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(Jarak.isiKartu),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                cek,
                const SizedBox(height: Jarak.j8),
                Text(pesan, textAlign: TextAlign.center, style: teks.bodyMedium!.copyWith(color: Warna.teksSukses)),
                if (nomorRegister case final nomor?) ...[
                  const SizedBox(height: Jarak.j4),
                  Text('Nomor Register', style: lemah),
                  Text('$nomor', style: teks.headlineMedium),
                ],
                const SizedBox(height: Jarak.j4),
                Text(judul, textAlign: TextAlign.center, style: teks.titleLarge),
                _Nominal(jumlah: jumlah, gerak: gerak),
                Text('${formatJam(waktu)} WITA', style: noteN ? lemah.merge(Huruf.penandaNote) : lemah),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LingkaranCek extends StatelessWidget {
  const _LingkaranCek();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Warna.hijauLembut, shape: BoxShape.circle),
      child: Padding(
        padding: const EdgeInsets.all(Bentuk.cincinCek),
        child: Container(
          width: Bentuk.lingkaranCek,
          height: Bentuk.lingkaranCek,
          decoration: const BoxDecoration(gradient: Gradien.kepala, shape: BoxShape.circle),
          child: const Icon(Icons.check_rounded, size: Bentuk.ikonCek, color: Warna.diAtasPrimer),
        ),
      ),
    );
  }
}

/// Nominal `nominal` primer. Dengan gerak, angkanya naik dari Rp 0 dan dibulatkan ke bawah ke ribuan
/// selama berjalan, sehingga tidak pernah melampaui nilai akhir; label Semantics selalu nilai akhir.
class _Nominal extends StatelessWidget {
  const _Nominal({required this.jumlah, required this.gerak});

  static const _ribu = 1000;

  final int jumlah;
  final bool gerak;

  @override
  Widget build(BuildContext context) {
    final gaya = Theme.of(context).textTheme.headlineSmall!.copyWith(color: Warna.primer);
    Widget tulis(int nilai) => FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(formatRupiah(nilai), style: gaya, maxLines: 1),
        );
    if (!gerak) return tulis(jumlah);
    return Semantics(
      container: true,
      label: formatRupiah(jumlah),
      child: ExcludeSemantics(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: jumlah.toDouble()),
          duration: Gerak.hitung,
          curve: Gerak.kurva,
          builder: (context, nilai, _) =>
              tulis(nilai >= jumlah ? jumlah : nilai ~/ _ribu * _ribu),
        ),
      ),
    );
  }
}
