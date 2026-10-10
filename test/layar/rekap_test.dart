// Kriteria F7 (docs/23_ACCEPTANCE_CRITERIA.md), alur P5 (docs/06_BUSINESS_PROCESS.md), tempat tampil
// galat (docs/14_ERROR_HANDLING.md), dan empat state Rekap (docs/26_UI_CONVENTIONS.md).

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdonator/api/model.dart';
import 'package:mdonator/layar/masuk.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/grafik_rekap.dart';
import 'package:mdonator/widget/kerangka_memuat.dart';
import 'package:mdonator/widget/latar_dasbor.dart';
import 'package:mdonator/widget/panel_galat.dart';

import 'bantu.dart';

/// Kartu ringkasan (Total, Transaksi, Donatur). Rincian per operator dan per hari juga berupa kartu
/// sejak S7, dan totalnya bisa sama dengan Total, jadi kartu ringkasan dikenali dari label "Total".
Finder get _kartu => find.ancestor(of: find.text('Total'), matching: find.byType(Card));

Finder _diKartu(String teks) => find.descendant(of: _kartu, matching: find.text(teks));

Finder _baris(String judul) => find.ancestor(of: find.text(judul), matching: find.byType(ListTile));

Finder _diBaris(String judul, String teks) => find.descendant(of: _baris(judul), matching: find.text(teks));

Finder get _panahKiri => find.widgetWithIcon(IconButton, Icons.chevron_left);

Finder get _panahKanan => find.widgetWithIcon(IconButton, Icons.chevron_right);

bool _aktif(WidgetTester tester, Finder panah) => tester.widget<IconButton>(panah).onPressed != null;

Set<Periode> _periodeTerpilih(WidgetTester tester) =>
    tester.widget<SegmentedButton<Periode>>(find.byType(SegmentedButton<Periode>)).selected;

Set<Cakupan> _cakupanTerpilih(WidgetTester tester) =>
    tester.widget<SegmentedButton<Cakupan>>(find.byType(SegmentedButton<Cakupan>)).selected;

/// Parameter query permintaan `rekap` ke-[i] (negatif dihitung dari belakang).
Map<String, String> _kirimanRekap(ServerTiruan server, [int i = -1]) {
  final semua = kirimanKe(server, 'rekap');
  return semua[i < 0 ? semua.length + i : i].url.queryParameters;
}

void main() {
  group('rekap', () {
    testWidgets('saat tab dibuka: hari, saya, tanggal hari_ini; Total, Transaksi, dan Donatur tampil',
        (tester) async {
      final semantik = tester.ensureSemantics();
      final server = serverRekap();
      await pompaInput(tester, server);
      // Tab Rekap belum dibuka: tidak ada permintaan rekap.
      expect(kirimanKe(server, 'rekap'), isEmpty);

      await pilihTab(tester, 'Rekap');
      expect(judulAppBar(tester), 'Rekap');
      expect(kirimanKe(server, 'rekap'), hasLength(1));
      // Tanpa `tanggal` = hari ini menurut server (konfigurasi.hari_ini 2026-10-12).
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'hari', 'cakupan': 'saya'});
      expect(_periodeTerpilih(tester), {Periode.hari});
      expect(_cakupanTerpilih(tester), {Cakupan.saya});

      expect(find.text('Senin, 12/10/2026'), findsOneWidget);
      expect(_diKartu('Total'), findsOneWidget);
      expect(_diKartu('Rp 27.000.000'), findsOneWidget);
      expect(_diKartu('Transaksi'), findsOneWidget);
      expect(_diKartu('146'), findsOneWidget);
      expect(_diKartu('Donatur'), findsOneWidget);
      expect(_diKartu('139'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Total\nRp 27\.000\.000$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Transaksi\n146$')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Donatur\n139$')), findsOneWidget);

      // Hari: tanpa rincian per hari; Input saya: tanpa rincian per operator.
      expect(find.text('Rincian per hari'), findsNothing);
      expect(find.text('Rincian per operator'), findsNothing);
      expect(find.byType(ListTile), findsNothing);
      semantik.dispose();
    });

    testWidgets('mengganti segmen memanggil rekap dengan tanggal yang sama', (tester) async {
      final server = serverRekap();
      await pompaTabRekap(tester, server);

      await ketuk(tester, find.text('Minggu'));
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'minggu', 'cakupan': 'saya'});
      expect(_periodeTerpilih(tester), {Periode.minggu});
      expect(find.text('Senin, 12/10/2026 – Minggu, 18/10/2026'), findsOneWidget);

      await ketuk(tester, _panahKiri);
      expect(_kirimanRekap(server)['tanggal'], '2026-10-05');
      expect(find.text('Senin, 05/10/2026 – Minggu, 11/10/2026'), findsOneWidget);

      await ketuk(tester, find.text('Hari'));
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'hari', 'tanggal': '2026-10-05', 'cakupan': 'saya'});
      expect(find.text('Senin, 05/10/2026'), findsOneWidget);

      await ketuk(tester, find.text('Semua operator'));
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'hari', 'tanggal': '2026-10-05', 'cakupan': 'semua'});
      expect(_cakupanTerpilih(tester), {Cakupan.semua});

      await ketuk(tester, find.text('Bulan'));
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'bulan', 'tanggal': '2026-10-05', 'cakupan': 'semua'});
      expect(find.text('Oktober 2026'), findsOneWidget);

      // Segmen yang sudah terpilih diketuk lagi: tanpa permintaan.
      final jumlah = kirimanKe(server, 'rekap').length;
      await ketuk(tester, find.text('Bulan'));
      expect(kirimanKe(server, 'rekap'), hasLength(jumlah));
    });

    testWidgets('panah ← memuat navigasi.sebelum; → memuat navigasi.sesudah dan nonaktif bila null',
        (tester) async {
      final server = serverRekap();
      await pompaTabRekap(tester, server);
      // Hari ini: periode berikutnya dimulai setelah hari ini → sesudah null.
      expect(_aktif(tester, _panahKiri), isTrue);
      expect(_aktif(tester, _panahKanan), isFalse);
      await tester.tap(_panahKanan);
      await tester.pumpAndSettle();
      expect(kirimanKe(server, 'rekap'), hasLength(1));

      await ketuk(tester, _panahKiri);
      expect(_kirimanRekap(server)['tanggal'], '2026-10-11');
      expect(find.text('Minggu, 11/10/2026'), findsOneWidget);
      expect(_aktif(tester, _panahKanan), isTrue);

      await ketuk(tester, _panahKanan);
      expect(_kirimanRekap(server)['tanggal'], '2026-10-12');
      expect(find.text('Senin, 12/10/2026'), findsOneWidget);
      expect(_aktif(tester, _panahKanan), isFalse);

      // Bulan: ← memuat tanggal 1 bulan sebelumnya.
      await ketuk(tester, find.text('Bulan'));
      await ketuk(tester, _panahKiri);
      expect(_kirimanRekap(server)['tanggal'], '2026-09-01');
      expect(find.text('September 2026'), findsOneWidget);
    });

    testWidgets('Semua operator: rincian per operator dengan baris "User lama (sudah dihapus)"', (tester) async {
      final server = serverRekap();
      await pompaTabRekap(tester, server);
      await ketuk(tester, find.text('Semua operator'));

      expect(find.text('Rincian per operator'), findsOneWidget);
      expect(_diBaris('operator1', '80 transaksi'), findsOneWidget);
      expect(_diBaris('operator1', 'Rp 15.000.000'), findsOneWidget);
      expect(_diBaris('operator2', 'Rp 11.950.000'), findsOneWidget);
      // Baris id_user null dari server, urutan dari server (terakhir).
      expect(_diBaris('User lama (sudah dihapus)', '1 transaksi'), findsOneWidget);
      expect(_diBaris('User lama (sudah dihapus)', 'Rp 50.000'), findsOneWidget);
      final judul = [
        for (final tile in tester.widgetList<ListTile>(find.byType(ListTile))) (tile.title! as Text).data,
      ];
      expect(judul, ['operator1', 'operator2', 'User lama (sudah dihapus)']);

      await ketuk(tester, find.text('Input saya'));
      expect(_kirimanRekap(server)['cakupan'], 'saya');
      expect(find.text('Rincian per operator'), findsNothing);
      expect(find.text('operator1'), findsNothing);
      expect(find.text('User lama (sudah dihapus)'), findsNothing);
    });

    testWidgets('Minggu dan Bulan: rincian per hari; Semua operator: per operator lalu per hari', (tester) async {
      final server = serverRekap();
      await pompaTabRekap(tester, server);
      await ketuk(tester, find.text('Minggu'));

      expect(find.text('Rincian per hari'), findsOneWidget);
      expect(_diBaris('Senin, 05/10/2026', '98 transaksi'), findsOneWidget);
      expect(_diBaris('Senin, 05/10/2026', 'Rp 18.100.000'), findsOneWidget);
      expect(_diBaris('Kamis, 08/10/2026', 'Rp 8.900.000'), findsOneWidget);
      expect(find.text('Rincian per operator'), findsNothing);

      await ketuk(tester, find.text('Semua operator'));
      final operator = tester.getTopLeft(find.text('Rincian per operator')).dy;
      final hari = tester.getTopLeft(find.text('Rincian per hari')).dy;
      expect(operator, lessThan(hari));

      await ketuk(tester, find.text('Bulan'));
      expect(find.text('Oktober 2026'), findsOneWidget);
      expect(find.text('Rincian per hari'), findsOneWidget);
      expect(find.text('Rincian per operator'), findsOneWidget);
    });

    testWidgets('transaksi 0 → "Tidak ada sumbangan pada periode ini"', (tester) async {
      final server = serverRekap();
      server.penangan['rekap'] = penanganRekap(total: 0, transaksi: 0, donatur: 0);
      await pompaTabRekap(tester, server);
      expect(find.text('Tidak ada sumbangan pada periode ini'), findsOneWidget);
      expect(_kartu, findsNothing);
      expect(find.byType(ListTile), findsNothing);
      // Kontrol tetap bisa dipakai pada state kosong.
      expect(find.text('Senin, 12/10/2026'), findsOneWidget);
      expect(_aktif(tester, _panahKiri), isTrue);

      await ketuk(tester, find.text('Semua operator'));
      expect(find.text('Tidak ada sumbangan pada periode ini'), findsOneWidget);
      expect(find.text('Rincian per operator'), findsNothing);
    });

    testWidgets('memuat → kerangka kartu; galat jaringan → panel Coba lagi → rekap', (tester) async {
      final server = serverRekap();
      await pompaInput(tester, server);
      final tahan = Completer<http.Response>();
      server.penangan['rekap'] = (r) => tahan.future;
      await pilihTab(tester, 'Rekap');
      expect(find.byType(KerangkaMemuat), findsOneWidget);
      expect(_aktif(tester, _panahKiri), isFalse);
      expect(_aktif(tester, _panahKanan), isFalse);

      tahan.completeError(http.ClientException('putus'));
      await tester.pumpAndSettle();
      expect(find.byType(KerangkaMemuat), findsNothing);
      expect(find.descendant(of: find.byType(PanelGalat), matching: find.text(TeksGalat.jaringanGet)), findsOneWidget);

      server.penangan['rekap'] = penanganRekap();
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      expect(find.byType(PanelGalat), findsNothing);
      expect(_diKartu('Rp 27.000.000'), findsOneWidget);
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'hari', 'cakupan': 'saya'});
    });

    testWidgets('500 → pesan umum + Coba lagi; 422 tidak_valid → rincian di panel', (tester) async {
      final server = serverRekap();
      await pompaInput(tester, server);
      server.penangan['rekap'] = (r) async => jawabGalat(500, 'galat_server', 'Terjadi galat di server.');
      await pilihTab(tester, 'Rekap');
      expect(find.text(TeksGalat.umum), findsOneWidget);
      expect(tombol<OutlinedButton>('Coba lagi'), findsOneWidget);

      server.penangan['rekap'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian tidak valid.', {
            'rincian': {'periode': 'Periode harus hari, minggu, atau bulan.'},
          });
      await ketuk(tester, tombol<OutlinedButton>('Coba lagi'));
      expect(
        find.descendant(of: find.byType(PanelGalat), matching: find.text('Periode harus hari, minggu, atau bulan.')),
        findsOneWidget,
      );
    });

    testWidgets('401 → Masuk; setelah masuk rekap dimuat ulang', (tester) async {
      final server = serverRekap();
      await pompaInput(tester, server);
      server.penangan['rekap'] =
          (r) async => jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      await pilihTab(tester, 'Rekap');
      expect(find.byType(LayarMasuk), findsOneWidget);

      server.penangan['rekap'] = penanganRekap();
      await isiDanMasuk(tester);
      expect(find.byType(LayarMasuk), findsNothing);
      expect(judulAppBar(tester), 'Rekap');
      expect(_diKartu('Rp 27.000.000'), findsOneWidget);
      expect(kirimanKe(server, 'rekap').last.headers['Authorization'], 'Bearer $tokenUji');
    });

    testWidgets('tab dibuka lagi → dimuat ulang dengan pilihan yang sama; tarik ke bawah → dimuat ulang',
        (tester) async {
      final server = serverRekap();
      await pompaTabRekap(tester, server);
      await ketuk(tester, find.text('Minggu'));
      await ketuk(tester, find.text('Semua operator'));
      await ketuk(tester, _panahKiri);
      expect(kirimanKe(server, 'rekap'), hasLength(4));

      await pilihTab(tester, 'Input');
      await pilihTab(tester, 'Rekap');
      expect(kirimanKe(server, 'rekap'), hasLength(5));
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'minggu', 'tanggal': '2026-10-05', 'cakupan': 'semua'});
      expect(_periodeTerpilih(tester), {Periode.minggu});
      expect(_cakupanTerpilih(tester), {Cakupan.semua});

      server.penangan['rekap'] = penanganRekap(total: 30000000, transaksi: 150, donatur: 141);
      await tester.fling(_kartu, const Offset(0, 800), 1000);
      await tester.pump();
      // Selesaikan animasi gulir, lalu animasi indikator menetap dan menghilang.
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();
      expect(kirimanKe(server, 'rekap'), hasLength(6));
      expect(_kirimanRekap(server), {'aksi': 'rekap', 'periode': 'minggu', 'tanggal': '2026-10-05', 'cakupan': 'semua'});
      expect(_diKartu('Rp 30.000.000'), findsOneWidget);
      expect(_diKartu('141'), findsOneWidget);
    });

    testWidgets('jawaban pilihan lama yang datang belakangan dibuang', (tester) async {
      final server = serverRekap();
      await pompaInput(tester, server);
      final tahan = Completer<http.Response>();
      final cepat = penanganRekap();
      server.penangan['rekap'] = (r) => r.url.queryParameters['periode'] == 'hari' ? tahan.future : cepat(r);
      await pilihTab(tester, 'Rekap');
      await ketuk(tester, find.text('Minggu'));
      expect(find.text('Senin, 12/10/2026 – Minggu, 18/10/2026'), findsOneWidget);

      tahan.complete(await penanganRekap(total: 1000, transaksi: 1, donatur: 1)(kirimanKe(server, 'rekap').first));
      await tester.pumpAndSettle();
      expect(find.text('Senin, 12/10/2026 – Minggu, 18/10/2026'), findsOneWidget);
      expect(_diKartu('Rp 27.000.000'), findsOneWidget);
      expect(_periodeTerpilih(tester), {Periode.minggu});
    });

    testWidgets('hari_ini berganti saat resume → rekap hari baru dimuat', (tester) async {
      final server = serverRekap();
      final sesi = await pompaTabRekap(tester, server);
      server.penangan['konfigurasi'] = (r) async => jawabOk({...konfigurasiUji(), 'hari_ini': '2026-10-13'});
      server.penangan['rekap'] = penanganRekap(hariIni: '2026-10-13', total: 0, transaksi: 0, donatur: 0);
      await sesi.segarkan();
      await tester.pumpAndSettle();
      expect(find.text('Selasa, 13/10/2026'), findsOneWidget);
      expect(find.text('Tidak ada sumbangan pada periode ini'), findsOneWidget);
      expect(_kirimanRekap(server).containsKey('tanggal'), isFalse);
    });

    testWidgets('grafik: donat per operator dan area per hari, hanya dari angka server, berhenti di hari_ini',
        (tester) async {
      final semantik = tester.ensureSemantics();
      final server = serverRekap();
      await pompaTabRekap(tester, server);
      // Segmen dan navigasi periode berada di kepala dasbor.
      final kepala = find.byWidgetPredicate((w) => w is LatarDasbor && w.kepala != null);
      for (final f in [find.byType(SegmentedButton<Periode>), find.byType(SegmentedButton<Cakupan>), _panahKiri]) {
        expect(find.descendant(of: kepala, matching: f), findsOneWidget);
      }
      // Hari × Input saya: tanpa grafik.
      expect(find.byType(GrafikPerHari), findsNothing);
      expect(find.byType(DonatOperator), findsNothing);

      List<double> garis() =>
          [for (final t in tester.widget<LineChart>(find.byType(LineChart)).data.lineBarsData.single.spots) t.y];

      await ketuk(tester, find.text('Minggu'));
      await ketuk(tester, find.text('Semua operator'));
      // Pekan 12–18/10 dengan hari_ini 12/10 (Senin): garis berhenti di hari ini, satu titik.
      expect(garis(), hasLength(1));

      // Pekan 05–11/10: tujuh titik; tanggal tanpa baris per_hari bernilai 0 (kontrak §6.9).
      await ketuk(tester, _panahKiri);
      expect(garis(), [18100000, 0, 0, 8900000, 0, 0, 0]);
      expect(find.bySemanticsLabel('Grafik rincian per hari'), findsOneWidget);

      final bagian = tester.widget<PieChart>(find.byType(PieChart)).data.sections;
      expect([for (final b in bagian) b.value], [15000000, 11950000, 50000]);
      expect([for (final b in bagian) b.color], [Warna.primer, Warna.aksi, Warna.teksLemah]);
      expect(find.bySemanticsLabel('Grafik rincian per operator'), findsOneWidget);
      // Baris rincian per operator menjadi legenda: titiknya berwarna sama dengan bagiannya.
      for (final (nama, warna) in [
        ('operator1', Warna.primer),
        ('operator2', Warna.aksi),
        ('User lama (sudah dihapus)', Warna.teksLemah),
      ]) {
        final titik = find.descendant(of: _baris(nama), matching: find.byType(TitikLegenda));
        expect(tester.widget<TitikLegenda>(titik).warna, warna, reason: nama);
      }
      // Grafik dan donat berada di kartu rinciannya masing-masing, bukan di kartu ringkasan.
      expect(find.descendant(of: _kartu, matching: find.byType(LineChart)), findsNothing);

      // Bulan Oktober, hari_ini 12/10: dua belas titik.
      await ketuk(tester, find.text('Bulan'));
      expect(garis(), hasLength(12));
      semantik.dispose();
    });

    testWidgets('segmen di kepala: tinggi 48 dp, pil, wadah pilKepala, terpilih aksen dengan teks primerTua',
        (tester) async {
      await pompaTabRekap(tester, serverRekap());
      for (final segmen in [find.byType(SegmentedButton<Periode>), find.byType(SegmentedButton<Cakupan>)]) {
        expect(tester.getSize(segmen).height, greaterThanOrEqualTo(Bentuk.tinggiTombol));
      }
      final gaya = Theme.of(tester.element(find.byType(SegmentedButton<Periode>))).segmentedButtonTheme.style!;
      const terpilih = {WidgetState.selected};
      expect(gaya.backgroundColor!.resolve(terpilih), Warna.aksen);
      expect(gaya.foregroundColor!.resolve(terpilih), Warna.primerTua);
      expect(gaya.backgroundColor!.resolve({}), Warna.pilKepala);
      expect(gaya.foregroundColor!.resolve({}), Warna.diAtasPrimer);
      expect(gaya.shape!.resolve({}), isA<StadiumBorder>());
    });
  });

  testWidgets('360×640 dp, textScaler 1,3: bulan × semua, 31 hari, nominal besar, nama panjang → tanpa luapan',
      (tester) async {
    final server = serverRekap();
    server.penangan['rekap'] = penanganRekap(
      total: 2000000000,
      transaksi: 12345,
      donatur: 9876,
      perHari: [
        for (var i = 1; i <= 31; i++)
          {'tanggal': '2026-10-${i.toString().padLeft(2, '0')}', 'transaksi': 999, 'total': 2000000000},
      ],
      perOperator: [
        for (var i = 0; i < 8; i++)
          {'id_user': 100 + i, 'nama': 'operator_dengan_nama_panjang_sekali_$i', 'transaksi': 1234, 'total': 2000000000},
        {'id_user': null, 'nama': 'User lama (sudah dihapus)', 'transaksi': 1, 'total': 2000000000},
      ],
    );
    await pompaTabRekap(tester, server, layarKecil: true);
    expect(tester.takeException(), isNull);
    for (final segmen in ['Minggu', 'Bulan', 'Semua operator']) {
      await ketuk(tester, find.text(segmen));
      expect(tester.takeException(), isNull, reason: segmen);
    }
    expect(_diKartu('Rp 2.000.000.000'), findsOneWidget);
    expect(_diKartu('12.345'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Sabtu, 31/10/2026'), 300);
    expect(tester.takeException(), isNull);

    await ketuk(tester, find.text('Minggu'));
    expect(find.text('Senin, 12/10/2026 – Minggu, 18/10/2026'), findsOneWidget);
    expect(tester.takeException(), isNull);

    server.penangan['rekap'] = (r) async => jawabGalat(500, 'galat_server', 'Terjadi galat di server.');
    await ketuk(tester, _panahKiri);
    expect(find.byType(PanelGalat), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
