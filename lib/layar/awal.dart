// Gerbang P0 (docs/06_BUSINESS_PROCESS.md): memilih layar menurut FaseSesi, mendorong Masuk di atas
// kerangka saat 401 tanpa membuang isi tab (docs/08_ARCHITECTURE.md §Alur 401), dan memanggil
// konfigurasi lagi setiap kali aplikasi kembali ke depan.

import 'package:flutter/material.dart';

import '../state/sesi.dart';
import '../tema.dart';
import '../widget/latar_dasbor.dart';
import '../widget/logo_yayasan.dart';
import '../widget/panel_galat.dart';
import 'kerangka.dart';
import 'masuk.dart';
import 'pengaturan.dart';

class LayarAwal extends StatefulWidget {
  const LayarAwal({super.key, this.kerangka = const LayarKerangka()});

  /// Layar fase aktif.
  final Widget kerangka;

  @override
  State<LayarAwal> createState() => _LayarAwalState();
}

class _LayarAwalState extends State<LayarAwal> {
  late final AppLifecycleListener _siklus;
  Sesi? _sesi;
  FaseSesi? _fase;
  Route<void>? _ruteMasukUlang;

  @override
  void initState() {
    super.initState();
    _siklus = AppLifecycleListener(onResume: () => _sesi?.segarkan());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sesi = SesiScope.baca(context);
    if (sesi == _sesi) return;
    _sesi?.removeListener(_sesiBerubah);
    _sesi = sesi..addListener(_sesiBerubah);
    _fase = sesi.fase;
  }

  @override
  void dispose() {
    _sesi?.removeListener(_sesiBerubah);
    _siklus.dispose();
    super.dispose();
  }

  void _sesiBerubah() {
    final sesi = _sesi!;
    final navigator = Navigator.of(context);
    if (sesi.fase != _fase) {
      // Fase baru = layar akar baru; rute di atasnya (Masuk ulang, Pengaturan, dst.) ditutup.
      _fase = sesi.fase;
      _tutupMasukUlang(navigator);
      navigator.popUntil((rute) => rute.isFirst);
    }
    if (sesi.perluMasukUlang && _ruteMasukUlang == null) {
      final rute = MaterialPageRoute<void>(
        builder: (_) => const PopScope(canPop: false, child: LayarMasuk()),
      );
      _ruteMasukUlang = rute;
      navigator.push(rute);
    } else if (!sesi.perluMasukUlang) {
      _tutupMasukUlang(navigator);
    }
  }

  void _tutupMasukUlang(NavigatorState navigator) {
    final rute = _ruteMasukUlang;
    _ruteMasukUlang = null;
    if (rute != null && rute.isActive) navigator.removeRoute(rute);
  }

  @override
  Widget build(BuildContext context) {
    final sesi = SesiScope.of(context);
    return switch (sesi.fase) {
      FaseSesi.memuat => const _LayarMemuat(),
      FaseSesi.perluMasuk => const LayarMasuk(),
      FaseSesi.aktif => widget.kerangka,
      FaseSesi.gagal => _LayarGagal(galat: sesi.galatAwal),
      FaseSesi.versiTidakCocok => const _LayarBlokirVersi(),
    };
  }
}

void _bukaPengaturan(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LayarPengaturan()),
    );

/// Logo di tengah latar putih tanpa AppBar, sama dengan layar pembuka Android < 12
/// (launch_background.xml), sehingga peralihan dari layar pembuka tidak berkedip. Status bar berikon gelap.
class _LayarMemuat extends StatelessWidget {
  const _LayarMemuat();

  @override
  Widget build(BuildContext context) {
    return const AnnotatedRegion(
      value: GayaSistem.diAtasLatar,
      child: Scaffold(
        backgroundColor: Warna.latar,
        body: Center(
          child: LogoYayasan(ukuran: Bentuk.logoMemuat, label: "Yayasan Ibnu Atha'illah"),
        ),
      ),
    );
  }
}

/// `konfigurasi` gagal saat aplikasi dibuka: token tetap, Coba lagi; Pengaturan untuk alamat salah.
class _LayarGagal extends StatelessWidget {
  const _LayarGagal({required this.galat});

  final Object? galat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('mDonator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Pengaturan',
            onPressed: () => _bukaPengaturan(context),
          ),
        ],
      ),
      body: LatarDasbor(
        isi: ListView(
          padding: const EdgeInsets.all(Jarak.tepiLayar),
          children: [
            PanelGalat(
              pesan: teksGalat(galat ?? const Object(), post: false),
              labelTombol: 'Coba lagi',
              padaTombol: SesiScope.baca(context).cobaLagi,
            ),
          ],
        ),
      ),
    );
  }
}

/// Versi kontrak tidak cocok (kontrak §9): hanya Pengaturan dan Keluar yang aktif.
class _LayarBlokirVersi extends StatelessWidget {
  const _LayarBlokirVersi();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('mDonator')),
      body: LatarDasbor(
        isi: ListView(
          padding: const EdgeInsets.all(Jarak.tepiLayar),
          children: [
            const PanelGalat(pesan: TeksGalat.versi),
            const SizedBox(height: Jarak.antarIsian),
            OutlinedButton(onPressed: () => _bukaPengaturan(context), child: const Text('Pengaturan')),
            const SizedBox(height: Jarak.antarTombol),
            OutlinedButton(onPressed: SesiScope.baca(context).keluar, child: const Text('Keluar')),
          ],
        ),
      ),
    );
  }
}
