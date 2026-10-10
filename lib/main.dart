import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'layar/awal.dart';
import 'layar/kerangka.dart';
import 'state/sesi.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Kepala dasbor digambar sampai ke tepi atas layar, juga di Android < 15 (docs/26 §Perangkat).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  daftarkanLisensiHuruf();
  // Alamat bawaan hanya dari --dart-define=SERVER_URL (docs/10_DEV_ENV.md); Pengaturan menang.
  final sesi = Sesi(alamatBawaan: const String.fromEnvironment('SERVER_URL'));
  runApp(AplikasiMDonator(sesi: sesi));
  await sesi.mulai();
}

/// Lisensi OFL 1.1 kedua huruf yang dibundel (docs/09_STACK.md) ikut tercatat di daftar lisensi aplikasi.
void daftarkanLisensiHuruf() {
  LicenseRegistry.addLicense(() async* {
    for (final (huruf, berkas) in const [
      ('Plus Jakarta Sans', 'assets/huruf/OFL-PlusJakartaSans.txt'),
      ('Outfit', 'assets/huruf/OFL-Outfit.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([huruf], await rootBundle.loadString(berkas));
    }
  });
}

class AplikasiMDonator extends StatelessWidget {
  const AplikasiMDonator({super.key, required this.sesi, this.kerangka = const LayarKerangka()});

  final Sesi sesi;

  /// Layar fase aktif; uji mengisinya dengan tab tiruan.
  final Widget kerangka;

  @override
  Widget build(BuildContext context) {
    // SesiScope di atas MaterialApp agar semua rute, termasuk dialog, bisa membaca Sesi.
    return SesiScope(
      sesi: sesi,
      child: MaterialApp(
        title: 'mDonator',
        debugShowCheckedModeBanner: false,
        theme: temaMDonator(),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LayarAwal(kerangka: kerangka),
      ),
    );
  }
}
