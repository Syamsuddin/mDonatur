// Latar dasbor (docs/26_UI_CONVENTIONS.md §Inventaris): gradien kepala berpola bintang dari tepi atas
// layar, di belakang status bar dan AppBar transparan, lalu isi kepala opsional; di bawahnya lembar
// isi latarDasbor bersudut atas 24. Dipakai di Scaffold ber-extendBodyBehindAppBar, sehingga padding
// atas MediaQuery sudah memuat status bar dan AppBar. Kepala diam; yang menggulir isi lembarnya.
// Scaffold membuang inset keyboard dari MediaQuery isi, tetapi memperkecil isinya saat keyboard
// muncul; karena itu inset keyboard dibaca dari View di dalam LayoutBuilder.

import 'package:flutter/material.dart';

import '../tema.dart';

class LatarDasbor extends StatelessWidget {
  const LatarDasbor({super.key, this.kepala, this.lipatSaatKeyboard = false, required this.isi});

  /// Isi kepala di bawah AppBar, mis. ringkasan hari ini atau segmen Rekap.
  final Widget? kepala;

  /// Melipat [kepala] dengan gerak cepat selama keyboard terbuka (Input Sumbangan), agar isian tetap
  /// mendapat ruang.
  final bool lipatSaatKeyboard;

  final Widget isi;

  @override
  Widget build(BuildContext context) {
    if (!lipatSaatKeyboard) return _bangun(context, kepalaTampil: true);
    return LayoutBuilder(
      builder: (context, _) => _bangun(
        context,
        kepalaTampil: MediaQueryData.fromView(View.of(context)).viewInsets.bottom == 0,
      ),
    );
  }

  Widget _bangun(BuildContext context, {required bool kepalaTampil}) {
    final atas = MediaQuery.paddingOf(context).top;
    final kepala = this.kepala;
    const kosong = SizedBox(width: double.infinity);
    Widget isiKepala = kepala == null || !kepalaTampil
        ? kosong
        : Padding(
            padding: const EdgeInsets.fromLTRB(Jarak.tepiLayar, 0, Jarak.tepiLayar, Jarak.bawahKepala),
            child: kepala,
          );
    // AnimatedSize berdurasi nol melempar galat tata letak saat ukurannya berubah, jadi tanpa gerak
    // kepala langsung berganti.
    if (kepala != null && lipatSaatKeyboard && Gerak.aktif(context)) {
      isiKepala = AnimatedSize(
        duration: Gerak.cepat,
        curve: Gerak.kurva,
        alignment: Alignment.topCenter,
        child: isiKepala,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(gradient: Gradien.kepala),
          child: CustomPaint(
            painter: const LukisanPolaBintang(),
            child: Padding(padding: EdgeInsets.only(top: atas), child: isiKepala),
          ),
        ),
        Expanded(
          // Sudut atas lembar berlatar ujung bawah gradien, sehingga lembar tampak menumpang di kepala.
          child: ColoredBox(
            color: Warna.primerTerang,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(Bentuk.radiusLembar)),
              child: ColoredBox(
                color: Warna.latarDasbor,
                child: MediaQuery.removePadding(context: context, removeTop: true, child: isi),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
