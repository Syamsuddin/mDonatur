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
  // Alamat bawaan hanya dari --dart-define=SERVER_URL (docs/10_DEV_ENV.md); Pengaturan menang.
  final sesi = Sesi(alamatBawaan: const String.fromEnvironment('SERVER_URL'));
  runApp(AplikasiMDonator(sesi: sesi));
  await sesi.mulai();
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
