import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'layar/kerangka.dart';
import 'tema.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AplikasiMDonator());
}

class AplikasiMDonator extends StatelessWidget {
  const AplikasiMDonator({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mDonator',
      debugShowCheckedModeBanner: false,
      theme: temaMDonator(),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const LayarKerangka(),
    );
  }
}
