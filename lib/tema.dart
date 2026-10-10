// Implementasi tunggal tabel token docs/26_UI_CONVENTIONS.md (tabel beku).
// Satu-satunya tempat Color(0x…), ukuran huruf, jarak, dan radius.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class Warna {
  static const primer = Color(0xFF046500);
  static const diAtasPrimer = Color(0xFFFFFFFF);
  static const primerGelap = Color(0xFF003300);
  static const aksen = Color(0xFFFFFF33);
  static const teks = Color(0xFF333333);
  static const teksLemah = Color(0xFF767676);
  static const latar = Color(0xFFFFFFFF);
  static const garis = Color(0xFFDDDDDD);
  static const aksi = Color(0xFF337AB7);
  static const teksSukses = Color(0xFF3C763D);
  static const teksInfo = Color(0xFF31708F);
  static const teksPeringatan = Color(0xFF8A6D3B);
  static const teksBahaya = Color(0xFFA94442);
  static const sukses = Color(0xFF5CB85C);
  static const info = Color(0xFF5BC0DE);
  static const peringatan = Color(0xFFF0AD4E);
}

abstract final class Huruf {
  static const label = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400);
  static const tombol = TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500);
  static const isi = TextStyle(fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400);
  static const judul = TextStyle(fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w500);
  static const nominal = TextStyle(fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w700);
  static const nomorRegister =
      TextStyle(fontSize: 32, height: 40 / 32, fontWeight: FontWeight.w700);

  /// Penanda note_n: berat 700 pada tanggal atau jam, ukuran tetap.
  static const penandaNote = TextStyle(fontWeight: FontWeight.w700);
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
  static const double antarTombol = j8;
}

abstract final class Bentuk {
  static const double radius = 8;
  static const double elevasiKartu = 1;
  static const double garisPemisah = 1;
  static const double targetSentuh = 48;
  static const double tinggiTombol = 48;
  static const double ikon = 24;
  static const double indikatorTombol = 20;

  /// Logo yayasan di kepala Masuk, di atas alas lingkaran `latar` (tepi alas [Jarak.j4]).
  static const double logoKepala = 56;

  /// Logo yayasan di layar memuat awal; sama dengan logo layar pembuka Android (launch_background.xml).
  static const double logoMemuat = 80;
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
    outline: Warna.garis,
    outlineVariant: Warna.garis,
  );
  final sudut = BorderRadius.circular(Bentuk.radius);
  final bentuk = RoundedRectangleBorder(borderRadius: sudut);
  const ukuranTombol = Size(Bentuk.targetSentuh, Bentuk.tinggiTombol);
  bool dipilih(Set<WidgetState> s) => s.contains(WidgetState.selected);

  return ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.latar,
    textTheme: const TextTheme(
      bodyMedium: Huruf.label,
      labelLarge: Huruf.tombol,
      bodyLarge: Huruf.isi,
      titleLarge: Huruf.judul,
      headlineSmall: Huruf.nominal,
      headlineMedium: Huruf.nomorRegister,
    ).apply(bodyColor: Warna.teks, displayColor: Warna.teks),
    appBarTheme: AppBarTheme(
      backgroundColor: Warna.primer,
      foregroundColor: Warna.diAtasPrimer,
      surfaceTintColor: Warna.primer,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: Huruf.judul.copyWith(color: Warna.diAtasPrimer),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Warna.primerGelap,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      elevation: 0,
      indicatorColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            size: Bentuk.ikon,
            color: dipilih(s) ? Warna.primer : Warna.teksLemah,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => dipilih(s)
          ? Huruf.tombol.copyWith(color: Warna.primer)
          : Huruf.label.copyWith(color: Warna.teksLemah)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.primer,
        foregroundColor: Warna.diAtasPrimer,
        minimumSize: ukuranTombol,
        shape: bentuk,
        textStyle: Huruf.tombol,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Warna.primer,
        minimumSize: ukuranTombol,
        shape: bentuk,
        side: const BorderSide(color: Warna.garis),
        textStyle: Huruf.tombol,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Warna.primer,
        minimumSize: ukuranTombol,
        shape: bentuk,
        textStyle: Huruf.tombol,
      ),
    ),
    // Segmen Rekap: radius 8 dan tinggi 48 seperti tombol lain, bukan pil 40 dp bawaan M3.
    // Segmen terpilih berlatar primer dengan teks diAtasPrimer.
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(ukuranTombol),
        shape: WidgetStatePropertyAll(bentuk),
        side: const WidgetStatePropertyAll(BorderSide(color: Warna.garis)),
        textStyle: const WidgetStatePropertyAll(Huruf.tombol),
        backgroundColor: WidgetStateProperty.resolveWith((s) => dipilih(s) ? Warna.primer : Warna.latar),
        foregroundColor:
            WidgetStateProperty.resolveWith((s) => dipilih(s) ? Warna.diAtasPrimer : Warna.teks),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      // Warna garis per state memakai bawaan Material 3 dari skema: outline = garis,
      // fokus = primer, galat = teksBahaya.
      border: OutlineInputBorder(borderRadius: sudut),
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
      elevation: Bentuk.elevasiKartu,
      shape: RoundedRectangleBorder(
        borderRadius: sudut,
        side: const BorderSide(color: Warna.garis),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      shape: bentuk,
    ),
    // Date picker Input Saya juga dialog: radius 8 dan latar tanpa rona, bukan bawaan M3.
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      shape: bentuk,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Warna.latar,
      surfaceTintColor: Warna.latar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Bentuk.radius)),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Warna.garis, thickness: Bentuk.garisPemisah),
  );
}
