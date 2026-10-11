// Kriteria F1 Masuk dan keluar (docs/23_ACCEPTANCE_CRITERIA.md), alur P0, P1, P7
// (docs/06_BUSINESS_PROCESS.md), dan tempat tampil galat (docs/14_ERROR_HANDLING.md).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mdonator/layar/kerangka.dart';
import 'package:mdonator/layar/masuk.dart';
import 'package:mdonator/main.dart';
import 'package:mdonator/state/sesi.dart';
import 'package:mdonator/tema.dart';
import 'package:mdonator/widget/logo_yayasan.dart';
import 'package:mdonator/widget/tombol_utama.dart';

import 'bantu.dart';

void main() {
  group('P1 masuk', () {
    testWidgets('password benar → token tersimpan → konfigurasi → tab Input', (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      final simpanan = <String, String>{};
      await pompaAplikasi(tester, server: server, simpanan: simpanan);
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.text("Yayasan Ibnu Atha'illah"), findsOneWidget);
      expect(find.text('mDonator'), findsOneWidget);
      // Logo di kepala, di sebelah kiri nama yayasan, beralas dan bercincin (docs/26_UI_CONVENTIONS.md, Logo).
      final logo = tester.getRect(find.byType(LogoYayasan));
      expect(logo.width, Bentuk.alasLogoKepala + 2 * Bentuk.cincinLogo);
      expect(logo.right, lessThan(tester.getRect(find.text("Yayasan Ibnu Atha'illah")).left));
      // Kepala gradien berpola bintang dan tombol utama Masuk (docs/26 §Layar → pola).
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LukisanPolaBintang), findsOneWidget);
      expect(find.ancestor(of: tombol<FilledButton>('Masuk'), matching: find.byType(TombolUtama)), findsOneWidget);
      expect(tester.takeException(), isNull);

      await isiDanMasuk(tester);

      expect(server.aksi, ['login', 'konfigurasi']);
      final login = server.permintaan.first;
      expect(jsonDecode(login.body), {'username': 'uji_operator', 'password': passwordUji});
      expect(login.headers.containsKey('Authorization'), isFalse);
      expect(server.permintaan.last.headers['Authorization'], 'Bearer $tokenUji');

      // Hanya token, kedaluwarsa, dan username terakhir; tanpa password dan tanpa pengguna/peran.
      expect(simpanan, {
        'token': tokenUji,
        'kedaluwarsa': kedaluwarsaUji,
        'username_terakhir': 'uji_operator',
      });
      expect(find.byType(LayarKerangka), findsOneWidget);
      expect(judulAppBar(tester), 'Input Sumbangan');
    });

    testWidgets('memuat: Masuk nonaktif dengan indikator, isian terkunci', (tester) async {
      final server = ServerTiruan();
      final jawaban = Completer<void>();
      server.penangan['login'] = (r) async {
        await jawaban.future;
        return jawabOk(loginUji());
      };
      await pompaAplikasi(tester, server: server);
      await tester.enterText(isian('Username'), 'uji_operator');
      await tester.enterText(isian('Password'), passwordUji);
      await tester.tap(tombol<FilledButton>('Masuk'));
      await tester.pump();

      final masuk = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(masuk.onPressed, isNull);
      expect(find.descendant(of: find.byType(FilledButton), matching: find.byType(CircularProgressIndicator)),
          findsOneWidget);
      expect(tester.widget<TextField>(isian('Username')).enabled, isFalse);

      jawaban.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LayarKerangka), findsOneWidget);
    });

    testWidgets('login_gagal → panel pesan server; Username tetap, Password dikosongkan', (tester) async {
      final server = ServerTiruan();
      server.penangan['login'] =
          (r) async => jawabGalat(401, 'login_gagal', 'Username dan Password anda salah!');
      final simpanan = <String, String>{};
      await pompaAplikasi(tester, server: server, simpanan: simpanan);

      await isiDanMasuk(tester, password: 'salah');

      expect(find.text('Username dan Password anda salah!'), findsOneWidget);
      expect(teksIsian(tester, 'Username'), 'uji_operator');
      expect(teksIsian(tester, 'Password'), isEmpty);
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(server.aksi, ['login'], reason: 'login gagal tidak memicu konfigurasi');
      expect(simpanan, isEmpty);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('login_terkunci → panel pesan server', (tester) async {
      final server = ServerTiruan();
      server.penangan['login'] = (r) async => jawabGalat(429, 'login_terkunci',
          'Terlalu banyak percobaan gagal. Coba lagi dalam 15 menit.', {'sisa_detik': 900});
      await pompaAplikasi(tester, server: server);
      await isiDanMasuk(tester);
      expect(find.text('Terlalu banyak percobaan gagal. Coba lagi dalam 15 menit.'), findsOneWidget);
      expect(teksIsian(tester, 'Username'), 'uji_operator');
    });

    testWidgets('api_mati → teks klien, bukan pesan server', (tester) async {
      final server = ServerTiruan();
      server.penangan['login'] = (r) async => jawabGalat(503, 'api_mati', 'APP_KEY kosong.');
      await pompaAplikasi(tester, server: server);
      await isiDanMasuk(tester);
      expect(find.text('Layanan mobile belum diaktifkan di server.'), findsOneWidget);
      expect(find.text('APP_KEY kosong.'), findsNothing);
    });

    testWidgets('tidak_valid → errorText per isian; kunci tanpa isian → panel', (tester) async {
      final server = ServerTiruan();
      server.penangan['login'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.', {
            'rincian': {'username': 'Username wajib diisi', 'password': 'Password wajib diisi'},
          });
      await pompaAplikasi(tester, server: server);
      await isiDanMasuk(tester, username: '', password: '');
      expect(galatIsian(tester, 'Username'), 'Username wajib diisi');
      expect(galatIsian(tester, 'Password'), 'Password wajib diisi');
      expect(find.text('Isian belum benar.'), findsNothing);

      server.penangan['login'] = (r) async => jawabGalat(422, 'tidak_valid', 'Isian belum benar.', {
            'rincian': {'lain': 'Ada yang salah'},
          });
      await isiDanMasuk(tester);
      expect(find.text('Ada yang salah'), findsOneWidget);
      expect(galatIsian(tester, 'Username'), isNull);
    });

    testWidgets('jaringan putus → panel Kirim ulang, isian tetap, kirim ulang isi yang sama',
        (tester) async {
      final server = ServerTiruan();
      server.penangan['login'] = (r) async => throw const SocketException('putus');
      await pompaAplikasi(tester, server: server);
      await isiDanMasuk(tester);

      expect(find.text('Tidak dapat terhubung ke server. Periksa sinyal, lalu tekan Kirim ulang.'),
          findsOneWidget);
      expect(teksIsian(tester, 'Username'), 'uji_operator');
      expect(teksIsian(tester, 'Password'), passwordUji);

      server.penangan['login'] = (r) async => jawabOk(loginUji());
      await tester.tap(tombol<OutlinedButton>('Kirim ulang'));
      await tester.pumpAndSettle();
      expect(server.aksi, ['login', 'login', 'konfigurasi']);
      expect(server.permintaan[1].body, server.permintaan[0].body);
      expect(find.byType(LayarKerangka), findsOneWidget);
    });

    testWidgets('galat server → pesan umum dan Coba lagi', (tester) async {
      final server = ServerTiruan();
      server.penangan['login'] = (r) async => jawabGalat(500, 'galat_server', 'Rincian internal');
      await pompaAplikasi(tester, server: server);
      await isiDanMasuk(tester);
      expect(find.text('Terjadi kesalahan. Coba lagi; bila berulang, hubungi admin.'), findsOneWidget);
      expect(find.text('Rincian internal'), findsNothing);
      expect(tombol<OutlinedButton>('Coba lagi'), findsOneWidget);
    });

    testWidgets('layar Masuk punya ikon Pengaturan', (tester) async {
      await pompaAplikasi(tester, server: ServerTiruan());
      await tester.tap(find.byTooltip('Pengaturan'));
      await tester.pumpAndSettle();
      expect(judulAppBar(tester), 'Pengaturan');
    });
  });

  group('P0 buka aplikasi', () {
    testWidgets('memuat: logo yayasan di tengah layar tanpa AppBar, lalu tab Input', (tester) async {
      aturLayarKecil(tester);
      aturHapusAnimasi(tester);
      final semantik = tester.ensureSemantics();
      final server = ServerTiruan();
      final jawaban = Completer<void>();
      server.penangan['konfigurasi'] = (r) async {
        await jawaban.future;
        return jawabOk(konfigurasiUji());
      };
      FlutterSecureStorage.setMockInitialValues(simpananMasuk());
      final sesi = Sesi(alamatBawaan: alamatBawaanUji, klienHttp: server.klien, rilis: false);
      await tester.pumpWidget(AplikasiMDonator(sesi: sesi, kerangka: const LayarKerangka()));
      final mulai = sesi.mulai();
      await tester.pump();

      expect(find.byType(LogoYayasan), findsOneWidget);
      expect(find.bySemanticsLabel("Yayasan Ibnu Atha'illah"), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      // Posisi dan ukuran sama dengan logo layar pembuka Android (launch_background.xml).
      expect(tester.getRect(find.byType(LogoYayasan)),
          Rect.fromCenter(center: const Offset(180, 320), width: 80, height: 80));
      expect(tester.takeException(), isNull);

      jawaban.complete();
      await mulai;
      await tester.pumpAndSettle();
      // Logo layar memuat hilang; yang tersisa hanya logo kecil di AppBar kerangka.
      expect(find.bySemanticsLabel("Yayasan Ibnu Atha'illah"), findsNothing);
      expect(
        tester.widgetList<LogoYayasan>(find.byType(LogoYayasan)).map((l) => l.ukuran),
        [Bentuk.logoBar],
      );
      expect(judulAppBar(tester), 'Input Sumbangan');
      semantik.dispose();
    });

    testWidgets('tanpa token → Masuk, Username terisi username terakhir', (tester) async {
      final server = ServerTiruan();
      await pompaAplikasi(tester, server: server, simpanan: {'username_terakhir': 'uji_operator'});
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(teksIsian(tester, 'Username'), 'uji_operator');
      expect(server.permintaan, isEmpty);
    });

    testWidgets('token dijawab 401 → Masuk dengan pesan server, token dihapus', (tester) async {
      final server = ServerTiruan();
      server.penangan['konfigurasi'] =
          (r) async => jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      final simpanan = simpananMasuk();
      await pompaAplikasi(tester, server: server, simpanan: simpanan);

      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.text('Sesi berakhir. Silakan masuk lagi.'), findsOneWidget);
      expect(simpanan.containsKey('token'), isFalse);
      expect(simpanan.containsKey('kedaluwarsa'), isFalse);
      expect(simpanan['username_terakhir'], 'uji_operator');
    });

    testWidgets('token sah → konfigurasi → tab Input tanpa login', (tester) async {
      final server = ServerTiruan();
      await pompaAplikasi(tester, server: server, simpanan: simpananMasuk());
      expect(server.aksi, ['konfigurasi']);
      expect(judulAppBar(tester), 'Input Sumbangan');
    });

    testWidgets('jaringan gagal → panel Coba lagi, token tidak dihapus', (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      server.penangan['konfigurasi'] = (r) async => throw const SocketException('putus');
      final simpanan = simpananMasuk();
      await pompaAplikasi(tester, server: server, simpanan: simpanan);

      expect(find.text('Tidak dapat terhubung ke server. Periksa sinyal, lalu tekan Coba lagi.'),
          findsOneWidget);
      expect(simpanan['token'], tokenUji);
      expect(find.byTooltip('Pengaturan'), findsOneWidget);
      expect(tester.takeException(), isNull);

      server.penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji());
      await tester.tap(tombol<OutlinedButton>('Coba lagi'));
      await tester.pumpAndSettle();
      expect(judulAppBar(tester), 'Input Sumbangan');
    });

    testWidgets('resume memanggil konfigurasi lagi dan memperbarui peran', (tester) async {
      final server = ServerTiruan();
      final sesi = await pompaAplikasi(tester, server: server, simpanan: simpananMasuk());
      expect(sesi.konfigurasi!.pengguna.peran, 'operator');

      server.penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji(peran: 'admin'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(server.aksi, ['konfigurasi', 'konfigurasi']);
      expect(sesi.konfigurasi!.pengguna.peran, 'admin');
    });
  });

  group('401 di tengah pemakaian (docs/08_ARCHITECTURE.md §Alur 401)', () {
    testWidgets('Masuk didorong di atas kerangka; setelah masuk, isian masih ada', (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      server.penangan['donatur'] =
          (r) async => jawabGalat(401, 'token_kedaluwarsa', 'Sesi berakhir. Silakan masuk lagi.');
      final simpanan = simpananMasuk();
      await pompaAplikasi(tester, server: server, simpanan: simpanan, kerangka: kerangkaDenganTabTiruan);

      await tester.enterText(isian('Isian Uji'), 'nomor 1234');
      await tester.tap(tombol<OutlinedButton>('Kirim Uji'));
      await tester.pumpAndSettle();

      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.text('Sesi berakhir. Silakan masuk lagi.'), findsOneWidget);
      expect(find.byType(LayarKerangka, skipOffstage: false), findsOneWidget);
      expect(simpanan.containsKey('token'), isFalse);
      expect(teksIsian(tester, 'Username'), 'uji_operator');
      expect(tester.takeException(), isNull);

      // Tanpa tombol kembali: tombol Back sistem tidak menutup layar Masuk.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LayarMasuk), findsOneWidget);

      server.penangan['login'] = (r) async => jawabOk(loginUji(token: tokenBaruUji));
      await tester.enterText(isian('Password'), passwordUji);
      await tester.tap(tombol<FilledButton>('Masuk'));
      await tester.pumpAndSettle();

      expect(find.byType(LayarMasuk), findsNothing);
      expect(teksIsian(tester, 'Isian Uji'), 'nomor 1234');
      expect(simpanan['token'], tokenBaruUji);
      expect(server.aksi, ['konfigurasi', 'donatur', 'login', 'konfigurasi']);
    });

    testWidgets('akun_nonaktif → pesan server di layar Masuk', (tester) async {
      final server = ServerTiruan();
      server.penangan['donatur'] =
          (r) async => jawabGalat(401, 'akun_nonaktif', 'Akun Anda tidak aktif. Hubungi admin.');
      await pompaAplikasi(tester, server: server, simpanan: simpananMasuk(), kerangka: kerangkaDenganTabTiruan);
      await tester.tap(tombol<OutlinedButton>('Kirim Uji'));
      await tester.pumpAndSettle();
      expect(find.text('Akun Anda tidak aktif. Hubungi admin.'), findsOneWidget);
    });
  });

  group('versi kontrak (§9)', () {
    testWidgets('versi_api "0.3.0" → layar blokir; hanya Pengaturan dan Keluar', (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      server.penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji(versi: '0.3.0'));
      final simpanan = simpananMasuk();
      await pompaAplikasi(tester, server: server, simpanan: simpanan);

      expect(find.text('Versi aplikasi tidak cocok dengan server. Perbarui aplikasi.'), findsOneWidget);
      expect(find.byType(LayarKerangka), findsNothing);
      expect(tombol<OutlinedButton>('Pengaturan'), findsOneWidget);
      expect(tombol<OutlinedButton>('Keluar'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(tombol<OutlinedButton>('Keluar'));
      await tester.pumpAndSettle();
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(simpanan.containsKey('token'), isFalse);
    });

    testWidgets('X-Api-Versi tidak cocok pada permintaan di kerangka → layar blokir', (tester) async {
      final server = ServerTiruan();
      server.penangan['donatur'] = (r) async =>
          jawabJson(200, {'ok': true, 'data': <String, Object?>{}}, versi: '0.3.0');
      await pompaAplikasi(tester, server: server, simpanan: simpananMasuk(), kerangka: kerangkaDenganTabTiruan);
      await tester.tap(tombol<OutlinedButton>('Kirim Uji'));
      await tester.pumpAndSettle();
      expect(find.text('Versi aplikasi tidak cocok dengan server. Perbarui aplikasi.'), findsOneWidget);
    });

    testWidgets('versi tidak cocok setelah login → layar blokir', (tester) async {
      final server = ServerTiruan();
      server.penangan['konfigurasi'] = (r) async => jawabOk(konfigurasiUji(versi: '0.3.0'));
      await pompaAplikasi(tester, server: server);
      await isiDanMasuk(tester);
      expect(find.text('Versi aplikasi tidak cocok dengan server. Perbarui aplikasi.'), findsOneWidget);
    });
  });

  group('P7 keluar', () {
    Future<void> bukaKeluar(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keluar'));
      await tester.pumpAndSettle();
    }

    testWidgets('ada isian → dialog; Batal tetap; Keluar menghapus token saja', (tester) async {
      aturLayarKecil(tester);
      final server = ServerTiruan();
      final simpanan = {...simpananMasuk(), 'alamat_server': 'http://host/donatur'};
      await pompaAplikasi(tester, server: server, simpanan: simpanan, kerangka: kerangkaDenganTabTiruan);
      await tester.enterText(isian('Isian Uji'), 'belum disimpan');

      await bukaKeluar(tester);
      expect(find.text('Isian yang belum disimpan akan hilang. Keluar?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(tombol<TextButton>('Batal'));
      await tester.pumpAndSettle();
      expect(find.byType(LayarKerangka), findsOneWidget);
      expect(teksIsian(tester, 'Isian Uji'), 'belum disimpan');
      expect(simpanan['token'], tokenUji);

      await bukaKeluar(tester);
      await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Keluar')));
      await tester.pumpAndSettle();

      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(find.byType(LayarKerangka, skipOffstage: false), findsNothing);
      expect(simpanan, {'alamat_server': 'http://host/donatur', 'username_terakhir': 'uji_operator'});
      expect(teksIsian(tester, 'Username'), 'uji_operator');
      expect(server.aksi, ['konfigurasi', 'logout'], reason: 'server diberi tahu (kontrak §6.11)');
      expect(server.permintaan.last.headers['Authorization'], 'Bearer $tokenUji');
    });

    testWidgets('Masuk tampil tanpa menunggu jawaban logout', (tester) async {
      final server = ServerTiruan();
      final jawaban = Completer<http.Response>();
      server.penangan['logout'] = (r) => jawaban.future;
      final simpanan = simpananMasuk();
      await pompaAplikasi(tester, server: server, simpanan: simpanan, kerangka: kerangkaDenganTabTiruan);
      await bukaKeluar(tester);
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(simpanan.containsKey('token'), isFalse);
      expect(server.aksi.last, 'logout');

      jawaban.complete(jawabOk(<String, Object?>{}));
      await tester.pumpAndSettle();
      expect(find.byType(LayarMasuk), findsOneWidget);
    });

    final galatLogout = <String, http.Response Function()>{
      'jaringan putus': () => throw const SocketException('putus'),
      '500 galat_server': () => jawabGalat(500, 'galat_server', 'Terjadi kesalahan.'),
      '401 token_tidak_sah': () => jawabGalat(401, 'token_tidak_sah', 'Sesi tidak sah. Silakan masuk lagi.'),
      '404 dari server lama (0.1.0)': () =>
          jawabJson(404, {'ok': false, 'kode': 'aksi_tidak_ada', 'pesan': 'Aksi API tidak dikenal.'}, versi: '0.1.0'),
    };
    for (final MapEntry(key: nama, value: jawab) in galatLogout.entries) {
      testWidgets('logout gagal ($nama) → tetap keluar, tanpa pesan maupun layar versi', (tester) async {
        final server = ServerTiruan();
        server.penangan['logout'] = (r) async => jawab();
        final sesi = await pompaAplikasi(tester, server: server, simpanan: simpananMasuk(),
            kerangka: kerangkaDenganTabTiruan);
        await bukaKeluar(tester);
        expect(server.aksi.last, 'logout');
        expect(sesi.fase, FaseSesi.perluMasuk);
        expect(sesi.pesanMasuk, isNull);
        expect(find.byType(LayarMasuk), findsOneWidget);
        expect(find.text('Sesi tidak sah. Silakan masuk lagi.'), findsNothing);
        expect(find.text('Versi aplikasi tidak cocok dengan server. Perbarui aplikasi.'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('tanpa isian → langsung keluar tanpa dialog', (tester) async {
      final server = ServerTiruan();
      final sesi = await pompaAplikasi(tester, server: server, simpanan: simpananMasuk(),
          kerangka: kerangkaDenganTabTiruan);
      await bukaKeluar(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LayarMasuk), findsOneWidget);
      expect(sesi.adaToken, isFalse);
      expect(sesi.konfigurasi, isNull);
      expect(sesi.fase, FaseSesi.perluMasuk);
    });
  });

  testWidgets('isian Masuk dibatasi panjang kontrak §6.1; Password tersamar', (tester) async {
    await pompaAplikasi(tester, server: ServerTiruan());
    expect(tester.widget<TextField>(isian('Username')).maxLength, 50);
    final password = tester.widget<TextField>(isian('Password'));
    expect(password.maxLength, 200);
    expect(password.obscureText, isTrue);
    // Tanpa autofill, agar Android tidak menawarkan menyimpan password (docs/21_SECURITY_RULES.md).
    expect(password.autofillHints, isNull);
    expect(tester.widget<TextField>(isian('Username')).autofillHints, isNull);
    expect(find.byType(AutofillGroup), findsNothing);
  });
}
