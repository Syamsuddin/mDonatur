import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/main.dart';
import 'package:mdonator/tema.dart';

/// Layar 360×640 dp dengan textScaler 1,3 (docs/23_ACCEPTANCE_CRITERIA.md §Semua layar).
void aturLayarKecil(WidgetTester tester) {
  tester.view.physicalSize = const Size(360 * 3, 640 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = 1.3;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

String judulAppBar(WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: find.byType(AppBar), matching: find.byType(Text))).data!;

void main() {
  testWidgets('kerangka 4 tab di 360×640 dp, textScaler 1,3, tanpa luapan', (tester) async {
    aturLayarKecil(tester);
    await tester.pumpWidget(const AplikasiMDonator());
    expect(tester.takeException(), isNull);

    // Layar awal: tab Input (docs/26_UI_CONVENTIONS.md §Layar → pola).
    expect(judulAppBar(tester), 'Input Sumbangan');
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
      expect(tester.takeException(), isNull, reason: 'tab $label');
    }
  });

  testWidgets('ikon tab sesuai token', (tester) async {
    await tester.pumpWidget(const AplikasiMDonator());
    final ikon = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => (d.icon as Icon).icon)
        .toList();
    expect(ikon, [Icons.add_card, Icons.person_add_alt_1, Icons.receipt_long, Icons.bar_chart]);
  });

  testWidgets('IndexedStack menjaga keempat tab tetap hidup', (tester) async {
    await tester.pumpWidget(const AplikasiMDonator());
    final tumpukan = tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(tumpukan.children, hasLength(4));
    await tester.tap(find.text('Rekap'));
    await tester.pumpAndSettle();
    expect(tester.widget<IndexedStack>(find.byType(IndexedStack)).index, 3);
  });

  testWidgets('tema dibangun eksplisit dari token, bukan fromSeed', (tester) async {
    await tester.pumpWidget(const AplikasiMDonator());
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
}
