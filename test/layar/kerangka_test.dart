import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/layar/input_sumbangan.dart';
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/layar/rekap.dart';
import 'package:mdonator/layar/tambah_donatur.dart';
import 'package:mdonator/tema.dart';

import 'bantu.dart';

void main() {
  testWidgets('kerangka 4 tab di 360×640 dp, textScaler 1,3, tanpa luapan', (tester) async {
    aturLayarKecil(tester);
    await pompaAplikasi(
      tester,
      server: serverInput(),
      simpanan: simpananMasuk(),
      kerangka: const LayarKerangka(),
    );
    expect(tester.takeException(), isNull);

    // Layar awal: tab Input berisi Input Sumbangan (docs/26_UI_CONVENTIONS.md §Layar → pola).
    expect(judulAppBar(tester), 'Input Sumbangan');
    expect(find.byType(LayarInputSumbangan), findsOneWidget);
    expect(tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex, 0);

    const tab = {
      'Donatur': 'Tambah Donatur',
      'Input Saya': 'Input Saya',
      'Rekap': 'Rekap',
      'Input': 'Input Sumbangan',
    };
    for (final MapEntry(key: label, value: judul) in tab.entries) {
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
      await tester.pumpAndSettle();
      expect(judulAppBar(tester), judul);
      if (label == 'Donatur') expect(find.byType(LayarTambahDonatur), findsOneWidget);
      if (label == 'Rekap') expect(find.byType(LayarRekap), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'tab $label');
    }
  });

  testWidgets('ikon tab sesuai token', (tester) async {
    await pompaAplikasi(tester, server: ServerTiruan(), simpanan: simpananMasuk());
    final ikon = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => (d.icon as Icon).icon)
        .toList();
    expect(ikon, [Icons.add_card, Icons.person_add_alt_1, Icons.receipt_long, Icons.bar_chart]);
  });

  testWidgets('IndexedStack menjaga keempat tab tetap hidup', (tester) async {
    await pompaAplikasi(tester, server: ServerTiruan(), simpanan: simpananMasuk());
    final tumpukan = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(tumpukan.children, hasLength(4));
    await tester.tap(find.text('Rekap'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);
  });

  testWidgets('tema dibangun eksplisit dari token, bukan fromSeed', (tester) async {
    await pompaAplikasi(tester, server: ServerTiruan(), simpanan: simpananMasuk());
    final tema = Theme.of(tester.element(find.byType(Scaffold)));
    final skema = tema.colorScheme;
    expect(skema.primary, Warna.primer);
    expect(skema.secondary, Warna.primer);
    expect(skema.onPrimary, Warna.diAtasPrimer);
    expect(skema.error, Warna.teksBahaya);
    expect(skema.surface, Warna.latar);
    expect(skema.surfaceTint, Warna.latar);
    expect(skema.onSurface, Warna.teks);
    expect(skema.onSurfaceVariant, Warna.teksLemah);
    expect(skema.outline, Warna.garis);
    expect(skema.outlineVariant, Warna.garis);
    expect(tema.appBarTheme.backgroundColor, Warna.primer);
    expect(tema.navigationBarTheme.indicatorColor, Colors.transparent);
    expect(tema.textTheme.bodyLarge?.fontSize, 16);
    expect(tema.textTheme.titleLarge?.fontWeight, FontWeight.w500);
    expect(tema.textTheme.headlineMedium?.fontSize, 32);
  });

  testWidgets('menu ⋮ berisi Pengaturan dan Keluar', (tester) async {
    await pompaAplikasi(tester, server: ServerTiruan(), simpanan: simpananMasuk());
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(judulAppBar(tester), 'Pengaturan');
  });
}
