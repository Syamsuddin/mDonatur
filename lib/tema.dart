// Implementasi tunggal tabel token docs/26_UI_CONVENTIONS.md (tabel beku, arah C "Dasbor Yayasan").
// Satu-satunya tempat Color(0x…), TextStyle, keluarga huruf, jarak, radius, gradien, pola bintang,
// dan durasi gerak.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class Warna {
  static const primer = Color(0xFF046500);
  static const primerTua = Color(0xFF023F00);
  static const primerTerang = Color(0xFF0B7A2E);
  static const diAtasPrimer = Color(0xFFFFFFFF);

  /// `diAtasPrimer` alfa 38 %: ikon nonaktif di kepala (panah periode Rekap).
  static const diAtasPrimerNonaktif = Color(0x61FFFFFF);
  static const aksen = Color(0xFFFFFF33);
  static const pilKepala = Color(0xFF0F5F12);
  static const teks = Color(0xFF333333);
  static const teksLemah = Color(0xFF6B6B6B);
  static const latar = Color(0xFFFFFFFF);
  static const latarDasbor = Color(0xFFF1F5F0);
  static const garis = Color(0xFFDDDDDD);
  static const garisLembut = Color(0xFFE0E8DE);
  static const hijauLembut = Color(0xFFE3F0E1);
  static const kuningLembut = Color(0xFFFFF59A);
  static const emas = Color(0xFFB7791F);
  static const ungu = Color(0xFF6F42C1);
  static const hijauSedang = Color(0xFF43A047);
  static const aksi = Color(0xFF337AB7);
  static const teksSukses = Color(0xFF3C763D);
  static const teksInfo = Color(0xFF31708F);
  static const teksPeringatan = Color(0xFF8A6D3B);
  static const teksBahaya = Color(0xFFA94442);
  static const bayangan = Color(0x33043C00);
  static const pola = Color(0x1AFFFFFF);
  static const transparan = Color(0x00000000);

  /// Palet grafik, urut sesuai baris server lalu berulang. "User lama" selalu [teksLemah].
  static const paletGrafik = [primer, aksi, emas, ungu, hijauSedang, teksPeringatan];

  static Color grafik(int urutan) => paletGrafik[urutan % paletGrafik.length];
}

abstract final class Gradien {
  static const kepala = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Warna.primerTua, Warna.primerTerang],
  );

  static const tombol = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Warna.primerTua, Warna.primerTerang],
  );

  /// `primer` alfa 30 % → 0 %, di bawah garis grafik per hari.
  static const areaGrafik = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x4D046500), Color(0x00046500)],
  );
}

/// Jarak huruf 0 di semua token: jarak huruf bawaan Material 3 (0,1–0,5) dirancang untuk Roboto dan
/// melebarkan Plus Jakarta Sans sampai baris kartu donatur terlipat.
abstract final class Huruf {
  static const keluargaIsi = 'PlusJakartaSans';
  static const keluargaTampilan = 'Outfit';

  static const label = TextStyle(
    fontFamily: keluargaIsi,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const kecil = TextStyle(
    fontFamily: keluargaIsi,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const tombol = TextStyle(
    fontFamily: keluargaIsi,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const isi = TextStyle(
    fontFamily: keluargaIsi,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  static const judulKartu = TextStyle(
    fontFamily: keluargaTampilan,
    fontSize: 16,
    height: 22 / 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
  );
  static const judul = TextStyle(
    fontFamily: keluargaTampilan,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );
  static const nominal = TextStyle(
    fontFamily: keluargaTampilan,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
  static const angkaKepala = TextStyle(
    fontFamily: keluargaTampilan,
    fontSize: 30,
    height: 38 / 30,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );
  static const nomorRegister = TextStyle(
    fontFamily: keluargaTampilan,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  /// Inisial avatar: Outfit 800 15 sp.
  static const inisial = TextStyle(
    fontFamily: keluargaTampilan,
    fontSize: 15,
    height: 1,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
  );

  /// Penanda note_n: berat 700 pada tanggal atau jam yang dasarnya 400, ukuran tetap.
  static const penandaNote = TextStyle(fontWeight: FontWeight.w700);

  /// Jumlah di baris daftar dan "Total Rp X" di kartu donatur.
  static const tebal = TextStyle(fontWeight: FontWeight.w700);

  /// Teks yang menandai pilihan (nominal cepat terpilih, segmen terpilih).
  static const tebalPilihan = TextStyle(fontWeight: FontWeight.w800);
}

abstract final class Jarak {
  static const double j4 = 4;
  static const double j8 = 8;
  static const double j12 = 12;
  static const double j16 = 16;
  static const double j24 = 24;

  static const double tepiLayar = j16;
  static const double antarIsian = j16;

  /// Layar Input Sumbangan: rapat agar muat satu layar tanpa digulir (keputusan pemilik 10 Okt 2026).
  static const double antarIsianRapat = j8;
  static const double isiKartu = j12;
  static const double antarKartu = j12;
  static const double antarTombol = j8;
  static const double bawahKepala = j12;

  /// Antar-baris riwayat di kartu donatur: rapat, agar layar Input muat tanpa digulir.
  static const double antarBarisRiwayat = 2;

  /// Navigasi mengambang: jarak kiri-kanan dan bawah (di atas inset sistem).
  static const double sisiNavigasi = j12;
  static const double bawahNavigasi = j8;
}

abstract final class Bentuk {
  static const double radiusKartu = 18;
  static const double radiusIsian = 12;
  static const double radiusLembar = 24;
  static const double elevasiKartu = 2;
  static const double elevasiNavigasi = 3;
  static const double garisPemisah = 1;
  static const double garisFokus = 2;
  static const double garisTerpilih = 1.5;
  static const double targetSentuh = 48;
  static const double tinggiTombol = 48;
  static const double tinggiTombolUtama = 52;
  static const double tinggiNavigasi = 64;
  static const double ikon = 24;
  static const double ikonBintang = 16;
  static const double ikonKosong = 40;
  static const double ikonCek = 32;
  static const double indikatorTombol = 20;
  static const double avatar = 40;
  static const double lingkaranCek = 56;
  static const double cincinCek = 6;
  static const double cincinLogo = 2;
  static const double titikLegenda = 12;
  static const double tinggiGrafik = 160;
  static const double garisGrafik = 3;
  static const double titikHariIni = 5;
  static const double cincinHariIni = 2;
  static const double donat = 120;

  /// Lubang donat: 60 % dari jari-jarinya.
  static const double lubangDonat = 0.6;

  /// Logo yayasan di kepala Masuk dan alasnya (tepi 4).
  static const double logoKepala = 56;
  static const double alasLogoKepala = 64;

  /// Logo di AppBar kerangka dan alasnya (tepi 2).
  static const double logoBar = 28;
  static const double alasLogoBar = 32;

  /// Logo di layar memuat awal; sama dengan logo layar pembuka Android (launch_background.xml).
  static const double logoMemuat = 80;

  static const double ubinPola = 44;
  static const double sisiPola = 20;
  static const double lingkaranPola = 4;
  static const double garisPola = 1;
  static const double naikMuncul = 8;

  static const pil = StadiumBorder();
}

abstract final class Bayangan {
  static const tombol = [BoxShadow(color: Warna.bayangan, offset: Offset(0, 6), blurRadius: 16)];
}

/// Token gerak. Semua gerak dicek lewat [aktif]: Hapus animasi Android mematikannya.
abstract final class Gerak {
  static const cepat = Duration(milliseconds: 200);
  static const pop = Duration(milliseconds: 450);
  static const hitung = Duration(milliseconds: 700);
  static const kilau = Duration(milliseconds: 1500);
  static const grafik = Duration(milliseconds: 300);
  static const kurva = Curves.easeOutCubic;
  static const kurvaPop = Curves.easeOutBack;

  /// Skala awal lingkaran cek pada gerak `pop`.
  static const skalaAwalPop = 0.3;

  static bool aktif(BuildContext context) => !MediaQuery.disableAnimationsOf(context);
}

/// Gaya status bar: transparan, karena kepala dasbor digambar sampai ke tepi atas layar.
abstract final class GayaSistem {
  /// Di atas gradien kepala: ikon terang.
  static const diAtasKepala = SystemUiOverlayStyle(
    statusBarColor: Warna.transparan,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Warna.transparan,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  /// Di atas latar putih (layar memuat awal): ikon gelap.
  static const diAtasLatar = SystemUiOverlayStyle(
    statusBarColor: Warna.transparan,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Warna.transparan,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );
}

abstract final class GayaTombol {
  /// Cek: OutlinedButton bergaya isi (latar primer, radius isian).
  static final cek = OutlinedButton.styleFrom(
    backgroundColor: Warna.primer,
    foregroundColor: Warna.diAtasPrimer,
    disabledBackgroundColor: Warna.garis,
    disabledForegroundColor: Warna.teksLemah,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Bentuk.radiusIsian)),
  );

  /// Tombol utama: FilledButton tembus pandang di atas gradienTombol yang dilukis TombolUtama.
  static final utama = FilledButton.styleFrom(
    backgroundColor: Warna.transparan,
    disabledBackgroundColor: Warna.transparan,
    foregroundColor: Warna.diAtasPrimer,
    disabledForegroundColor: Warna.teksLemah,
    shadowColor: Warna.transparan,
    minimumSize: const Size(Bentuk.targetSentuh, Bentuk.tinggiTombolUtama),
    shape: Bentuk.pil,
    textStyle: Huruf.tombol,
  );

  /// Nominal cepat: radius isian; yang terpilih berlatar kuningLembut dengan garis emas.
  static ButtonStyle nominal({required bool terpilih}) => OutlinedButton.styleFrom(
        backgroundColor: terpilih ? Warna.kuningLembut : Warna.latar,
        foregroundColor: terpilih ? Warna.teks : Warna.primer,
        side: terpilih
            ? const BorderSide(color: Warna.emas, width: Bentuk.garisTerpilih)
            : const BorderSide(color: Warna.garisLembut),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Bentuk.radiusIsian)),
        textStyle: terpilih ? Huruf.tombol.merge(Huruf.tebalPilihan) : Huruf.tombol,
        padding: const EdgeInsets.symmetric(horizontal: Jarak.j4),
      );
}

/// Isian di kepala (cari, Tanggal): gaya terisi tanpa garis, label melayang di dalam kotak putih,
/// fokus garis bawah 2 dp primer. Galat berwarna aksen karena teksnya jatuh di atas gradien.
InputDecoration dekorasiIsianKepala({
  required String label,
  String? errorText,
  Widget? suffixIcon,
  bool enabled = true,
}) {
  final sudut = BorderRadius.circular(Bentuk.radiusIsian);
  UnderlineInputBorder bawah(BorderSide sisi) => UnderlineInputBorder(borderRadius: sudut, borderSide: sisi);
  return InputDecoration(
    labelText: label,
    errorText: errorText,
    errorMaxLines: 3,
    enabled: enabled,
    filled: true,
    fillColor: Warna.latar,
    suffixIcon: suffixIcon,
    border: bawah(BorderSide.none),
    enabledBorder: bawah(BorderSide.none),
    disabledBorder: bawah(BorderSide.none),
    focusedBorder: bawah(const BorderSide(color: Warna.primer, width: Bentuk.garisFokus)),
    errorBorder: bawah(const BorderSide(color: Warna.teksBahaya, width: Bentuk.garisFokus)),
    focusedErrorBorder: bawah(const BorderSide(color: Warna.teksBahaya, width: Bentuk.garisFokus)),
    errorStyle: Huruf.label.copyWith(color: Warna.aksen),
  );
}

/// Pola bintang delapan di atas gradien kepala: ubin 44 dp, dua persegi 20 dp (satu diputar 45°)
/// dan lingkaran 4 dp, garis 1 dp warna pola. Ubin berpangkal di tepi atas layar.
class LukisanPolaBintang extends CustomPainter {
  const LukisanPolaBintang();

  @override
  void paint(Canvas canvas, Size size) {
    final kuas = Paint()
      ..color = Warna.pola
      ..style = PaintingStyle.stroke
      ..strokeWidth = Bentuk.garisPola;
    final persegi = Rect.fromCenter(center: Offset.zero, width: Bentuk.sisiPola, height: Bentuk.sisiPola);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var y = 0.0; y < size.height; y += Bentuk.ubinPola) {
      for (var x = 0.0; x < size.width; x += Bentuk.ubinPola) {
        final pusat = Offset(x + Bentuk.ubinPola / 2, y + Bentuk.ubinPola / 2);
        canvas.save();
        canvas.translate(pusat.dx, pusat.dy);
        canvas.drawRect(persegi, kuas);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(persegi, kuas);
        canvas.restore();
        canvas.drawCircle(pusat, Bentuk.lingkaranPola, kuas);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LukisanPolaBintang lama) => false;
}

ThemeData temaMDonator() {
  // Dibangun eksplisit dari token, bukan ColorScheme.fromSeed; surfaceTint = latar agar
  // elevasi tidak mendapat rona hijau.
  const skema = ColorScheme(
    brightness: Brightness.light,
    primary: Warna.primer,
    onPrimary: Warna.diAtasPrimer,
    secondary: Warna.primer,
    onSecondary: Warna.diAtasPrimer,
    error: Warna.teksBahaya,
    onError: Warna.diAtasPrimer,
    surface: Warna.latar,
    onSurface: Warna.teks,
    onSurfaceVariant: Warna.teksLemah,
    surfaceTint: Warna.latar,
    outline: Warna.garisLembut,
    outlineVariant: Warna.garis,
    shadow: Warna.bayangan,
  );
  final sudutIsian = BorderRadius.circular(Bentuk.radiusIsian);
  final sudutKartu = BorderRadius.circular(Bentuk.radiusKartu);
  final sudutLembar = BorderRadius.circular(Bentuk.radiusLembar);
  const ukuranTombol = Size(Bentuk.targetSentuh, Bentuk.tinggiTombol);
  bool dipilih(Set<WidgetState> s) => s.contains(WidgetState.selected);
  OutlineInputBorder garisIsian(Color warna, [double tebal = Bentuk.garisPemisah]) =>
      OutlineInputBorder(borderRadius: sudutIsian, borderSide: BorderSide(color: warna, width: tebal));

  // Slot yang tidak dipetakan token tetap memakai Plus Jakarta Sans. ThemeData.fontFamily tidak
  // dipakai karena menimpa Outfit di slot judul dan angka.
  final teksDasar = Typography.material2021().black.apply(fontFamily: Huruf.keluargaIsi);
  final teksTema = teksDasar
      .merge(const TextTheme(
        bodyMedium: Huruf.label,
        labelMedium: Huruf.kecil,
        labelLarge: Huruf.tombol,
        bodyLarge: Huruf.isi,
        titleMedium: Huruf.judulKartu,
        titleLarge: Huruf.judul,
        headlineSmall: Huruf.nominal,
        displaySmall: Huruf.angkaKepala,
        headlineMedium: Huruf.nomorRegister,
      ))
      .apply(bodyColor: Warna.teks, displayColor: Warna.teks);

  return ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.latarDasbor,
    textTheme: teksTema,
    appBarTheme: AppBarTheme(
      backgroundColor: Warna.transparan,
      foregroundColor: Warna.diAtasPrimer,
      surfaceTintColor: Warna.transparan,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: Huruf.judul.copyWith(color: Warna.diAtasPrimer),
      iconTheme: const IconThemeData(color: Warna.diAtasPrimer, size: Bentuk.ikon),
      actionsIconTheme: const IconThemeData(color: Warna.diAtasPrimer, size: Bentuk.ikon),
      systemOverlayStyle: GayaSistem.diAtasKepala,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      elevation: 0,
      height: Bentuk.tinggiNavigasi,
      indicatorColor: Warna.primer,
      indicatorShape: Bentuk.pil,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: Bentuk.ikon,
            color: dipilih(s) ? Warna.diAtasPrimer : Warna.teksLemah,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => Huruf.kecil.copyWith(color: dipilih(s) ? Warna.primer : Warna.teksLemah)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.primer,
        foregroundColor: Warna.diAtasPrimer,
        disabledBackgroundColor: Warna.garis,
        disabledForegroundColor: Warna.teksLemah,
        minimumSize: ukuranTombol,
        shape: Bentuk.pil,
        textStyle: Huruf.tombol,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: Warna.latar,
        foregroundColor: Warna.primer,
        disabledForegroundColor: Warna.teksLemah,
        minimumSize: ukuranTombol,
        shape: Bentuk.pil,
        side: const BorderSide(color: Warna.garisLembut),
        textStyle: Huruf.tombol,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Warna.primer,
        minimumSize: ukuranTombol,
        shape: Bentuk.pil,
        textStyle: Huruf.tombol,
      ),
    ),
    // Segmen di kepala Rekap: wadah pilKepala bertepi sewarna, terpilih aksen dengan teks primerTua.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(ukuranTombol),
        shape: const WidgetStatePropertyAll(Bentuk.pil),
        side: const WidgetStatePropertyAll(BorderSide(color: Warna.pilKepala)),
        textStyle: WidgetStateProperty.resolveWith(
            (s) => dipilih(s) ? Huruf.tombol.merge(Huruf.tebalPilihan) : Huruf.tombol),
        backgroundColor: WidgetStateProperty.resolveWith((s) => dipilih(s) ? Warna.aksen : Warna.pilKepala),
        foregroundColor:
            WidgetStateProperty.resolveWith((s) => dipilih(s) ? Warna.primerTua : Warna.diAtasPrimer),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Warna.latar,
      border: garisIsian(Warna.garisLembut),
      enabledBorder: garisIsian(Warna.garisLembut),
      disabledBorder: garisIsian(Warna.garis),
      focusedBorder: garisIsian(Warna.primer, Bentuk.garisFokus),
      errorBorder: garisIsian(Warna.teksBahaya),
      focusedErrorBorder: garisIsian(Warna.teksBahaya, Bentuk.garisFokus),
      labelStyle: WidgetStateTextStyle.resolveWith((s) => Huruf.label.copyWith(
            color: s.contains(WidgetState.error)
                ? Warna.teksBahaya
                : s.contains(WidgetState.focused)
                    ? Warna.primer
                    : Warna.teksLemah,
          )),
    ),
    cardTheme: CardThemeData(
      color: Warna.latar,
      surfaceTintColor: Warna.latar,
      shadowColor: Warna.bayangan,
      elevation: Bentuk.elevasiKartu,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: sudutKartu),
    ),
    listTileTheme: const ListTileThemeData(
      titleTextStyle: Huruf.isi,
      subtitleTextStyle: Huruf.label,
      textColor: Warna.teks,
      iconColor: Warna.primer,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      shape: RoundedRectangleBorder(borderRadius: sudutLembar),
      titleTextStyle: Huruf.judul.copyWith(color: Warna.teks),
      contentTextStyle: Huruf.label.copyWith(color: Warna.teks),
    ),
    // Date picker Input Saya juga dialog: radius lembar, kepala primer, latar tanpa rona.
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      headerBackgroundColor: Warna.primer,
      headerForegroundColor: Warna.diAtasPrimer,
      shape: RoundedRectangleBorder(borderRadius: sudutLembar),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Bentuk.radiusLembar)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Warna.latar,
      surfaceTintColor: Warna.latar,
      shadowColor: Warna.bayangan,
      elevation: Bentuk.elevasiNavigasi,
      shape: RoundedRectangleBorder(borderRadius: sudutIsian),
      labelTextStyle: WidgetStatePropertyAll(Huruf.isi.copyWith(color: Warna.teks)),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Warna.primer,
      refreshBackgroundColor: Warna.latar,
    ),
    dividerTheme: const DividerThemeData(color: Warna.garis, thickness: Bentuk.garisPemisah),
  );
}
