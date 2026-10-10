import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mdonator/layar/input_saya.dart';
import 'package:mdonator/layar/input_sumbangan.dart';
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/layar/rekap.dart';
import 'package:mdonator/layar/tambah_donatur.dart';
import 'package:mdonator/main.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/latar_dasbor.dart';
import 'package:mdonator/widget/logo_yayasan.dart';

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
    expect(skema.outline, Warna.garisLembut);
    expect(skema.outlineVariant, Warna.garis);
    expect(skema.shadow, Warna.bayangan);
    expect(tema.scaffoldBackgroundColor, Warna.latarDasbor);
    expect(tema.appBarTheme.backgroundColor, Warna.transparan);
    expect(tema.navigationBarTheme.indicatorColor, Warna.primer);
    expect(tema.navigationBarTheme.height, Bentuk.tinggiNavigasi);
    // Dua keluarga huruf docs/26: Plus Jakarta Sans untuk isi, Outfit untuk judul dan angka.
    expect(tema.textTheme.bodyLarge?.fontFamily, Huruf.keluargaIsi);
    expect(tema.textTheme.bodyLarge?.fontSize, 16);
    expect(tema.textTheme.labelMedium?.fontFamily, Huruf.keluargaIsi);
    expect(tema.textTheme.titleLarge?.fontFamily, Huruf.keluargaTampilan);
    expect(tema.textTheme.titleLarge?.fontWeight, FontWeight.w600);
    expect(tema.textTheme.headlineMedium?.fontFamily, Huruf.keluargaTampilan);
    expect(tema.textTheme.headlineMedium?.fontSize, 32);
    expect(tema.textTheme.displaySmall?.fontSize, 30);
    expect(tema.textTheme.displaySmall?.fontWeight, FontWeight.w800);
    // Slot yang tidak dipetakan token tetap Plus Jakarta Sans, bukan Roboto.
    expect(tema.textTheme.bodySmall?.fontFamily, Huruf.keluargaIsi);
  });

  testWidgets('kerangka dasbor: AppBar transparan berlogo, navigasi mengambang, tab di latar dasbor', (tester) async {
    await pompaAplikasi(tester, server: serverInput(), simpanan: simpananMasuk(), kerangka: const LayarKerangka());
    final appBar = find.byType(AppBar);
    expect(tester.widget<AppBar>(appBar).backgroundColor ?? Theme.of(tester.element(appBar)).appBarTheme.backgroundColor,
        Warna.transparan);
    final logo = tester.widget<LogoYayasan>(find.descendant(of: appBar, matching: find.byType(LogoYayasan)));
    expect((logo.ukuran, logo.alas, logo.cincin), (Bentuk.logoBar, Bentuk.alasLogoBar, true));
    // Kepala dasbor dimulai dari tepi atas layar, di belakang status bar dan AppBar.
    expect(tester.getTopLeft(find.byType(LatarDasbor).first).dy, 0);

    final kotakNavigasi = tester.widget<Material>(
        find.ancestor(of: find.byType(NavigationBar), matching: find.byType(Material)).first);
    expect(kotakNavigasi.elevation, Bentuk.elevasiNavigasi);
    expect(kotakNavigasi.borderRadius, BorderRadius.circular(Bentuk.radiusLembar));
    final navigasi = tester.getRect(find.byType(NavigationBar));
    final layar = tester.getRect(find.byType(Scaffold).first);
    expect(navigasi.left, Jarak.sisiNavigasi);
    expect(layar.right - navigasi.right, Jarak.sisiNavigasi);
    expect(layar.bottom - navigasi.bottom, Jarak.bawahNavigasi);

    // Setiap tab memakai latar dasbor; gerak tab tersembunyi dihentikan.
    for (final (i, jenis) in [LayarInputSumbangan, LayarTambahDonatur, LayarInputSaya, LayarRekap].indexed) {
      final tab = find.byType(jenis, skipOffstage: false);
      expect(find.descendant(of: tab, matching: find.byType(LatarDasbor, skipOffstage: false)), findsOneWidget,
          reason: '$jenis');
      expect(TickerMode.valuesOf(tester.element(tab)).enabled, i == 0, reason: '$jenis');
    }
  });

  testWidgets('lisensi OFL Plus Jakarta Sans dan Outfit terdaftar di LicenseRegistry', (tester) async {
    daftarkanLisensiHuruf();
    final lisensi = await tester.runAsync(() => LicenseRegistry.licenses.toList());
    for (final huruf in ['Plus Jakarta Sans', 'Outfit']) {
      final entri = lisensi!.where((l) => l.packages.contains(huruf)).toList();
      expect(entri, isNotEmpty, reason: huruf);
      expect(entri.first.paragraphs.map((p) => p.text).join(' '), contains('SIL Open Font License'),
          reason: huruf);
    }
  });

  testWidgets('menu ⋮ berisi Ganti Password, Pengaturan, dan Keluar, berurutan', (tester) async {
    await pompaAplikasi(tester, server: ServerTiruan(), simpanan: simpananMasuk());
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    final butir = find.byWidgetPredicate((w) => w is PopupMenuItem);
    final menu = [
      for (final b in tester.widgetList<PopupMenuItem<Object?>>(butir)) (b.child! as Text).data,
    ];
    expect(menu, ['Ganti Password', 'Pengaturan', 'Keluar']);

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(judulAppBar(tester), 'Pengaturan');
  });
}
