// Tanggal dan jam (docs/26_UI_CONVENTIONS.md §Mikroteks). Widget tidak memanggil DateFormat langsung.
// Tanggal dari server disimpan sebagai DateTime UTC tengah malam, sehingga zona waktu HP
// tidak pernah menggeser harinya. "Hari ini" selalu dari konfigurasi.hari_ini, bukan dari jam HP.

const _namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

const _namaBulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _dua(int n) => n.toString().padLeft(2, '0');

/// "YYYY-MM-DD" dari server → tanggal. Melempar FormatException bila bukan tanggal sah.
DateTime bacaTanggal(String teks) {
  final cocok = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(teks);
  if (cocok == null) throw FormatException('Tanggal tidak sah: $teks');
  final tahun = int.parse(cocok.group(1)!);
  final bulan = int.parse(cocok.group(2)!);
  final hari = int.parse(cocok.group(3)!);
  final tanggal = DateTime.utc(tahun, bulan, hari);
  if (tanggal.year != tahun || tanggal.month != bulan || tanggal.day != hari) {
    throw FormatException('Tanggal tidak sah: $teks');
  }
  return tanggal;
}

/// Tanggal → "YYYY-MM-DD" untuk parameter permintaan.
String tulisTanggal(DateTime tanggal) =>
    '${tanggal.year.toString().padLeft(4, '0')}-${_dua(tanggal.month)}-${_dua(tanggal.day)}';

/// "Senin" … "Minggu".
String namaHari(DateTime tanggal) => _namaHari[tanggal.weekday - 1];

/// "Minggu, 11/10/2026".
String formatTanggal(DateTime tanggal) =>
    '${namaHari(tanggal)}, ${_dua(tanggal.day)}/${_dua(tanggal.month)}/${tanggal.year}';

/// "Senin, 05/10/2026 – Minggu, 11/10/2026".
String formatRentang(DateTime dari, DateTime sampai) =>
    '${formatTanggal(dari)} – ${formatTanggal(sampai)}';

/// "Oktober 2026".
String formatBulan(DateTime tanggal) => '${_namaBulan[tanggal.month - 1]} ${tanggal.year}';

/// "HH:MM:SS" dari server → "HH:mm", tanpa konversi zona (K1).
String formatJam(String waktu) => waktu.length >= 5 ? waktu.substring(0, 5) : waktu;
