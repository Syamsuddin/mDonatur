// Format rupiah (docs/26_UI_CONVENTIONS.md §Mikroteks). Widget tidak memanggil NumberFormat langsung.

import 'package:intl/intl.dart';

final _ribuan = NumberFormat('#,##0', 'id_ID');

/// "100.000": angka bertitik ribuan tanpa "Rp", untuk tombol nominal cepat.
String formatRibuan(int nilai) => _ribuan.format(nilai);

/// "Rp 100.000".
String formatRupiah(int nilai) => 'Rp ${formatRibuan(nilai)}';

/// Isi isian angka → bilangan bulat, atau `null` bila kosong atau ada karakter selain digit.
/// Rentang nilai diperiksa server, bukan di sini.
int? bacaAngka(String teks) {
  if (!RegExp(r'^[0-9]+$').hasMatch(teks)) return null;
  return int.tryParse(teks);
}
