# 13 — TESTING

Uji unit dan widget berjalan **tanpa jaringan** memakai `MockClient` dari `package:http/testing.dart`. Tidak ada uji yang memanggil server selain server lokal. Perintahnya di docs/11_COMMANDS.md.

| Jenis | Berkas | Yang wajib diuji |
|---|---|---|
| Unit util | `test/util/rupiah_test.dart`, `tanggal_test.dart` | Rupiah untuk 0, 1, 999, 1000, 100000, dan 2147483647 → "Rp …" bertitik ribuan; isian angka hanya digit; tanggal "Minggu, 12/10/2026"; nama hari Senin–Minggu; teks rentang pekan |
| Unit API | `test/api/klien_api_test.dart` | Lihat daftar di bawah tabel |
| Kepatuhan kontrak | `test/api/kontrak_test.dart` | Membaca `API_CONTRACT.md` dari root paket; setiap blok ```` ```json ```` di §5–§6 di-parse oleh model aksi pada bagian itu tanpa galat. Kontrak berubah → uji ini memaksa model ikut berubah |
| Widget | `test/layar/<layar>_test.dart` | Kriteria antarmuka setiap fitur di docs/23_ACCEPTANCE_CRITERIA.md: empat state, dialog, `boleh_ubah`, `note_n`, isi otomatis saran |
| Tata letak | `test/layar/<layar>_test.dart` | Setiap layar dirender di 360×640 dp dengan `textScaler` 1,3 tanpa galat overflow |
| Muat satu layar | `test/layar/input_sumbangan_muat_test.dart` | Input Sumbangan di Pixel 5 tanpa digulir, dengan huruf aplikasi dari `assets/huruf/` |
| Gerak | `test/layar/gerak_test.dart` | Dengan animasi aktif: kartu hasil mencapai nominal akhir, `Semantics` selalu nilai akhir, kerangka memuat berkilau. Dengan Hapus animasi: nilai akhir langsung dan kerangka statis |
| Integrasi (opsional) | `integration_test/alur_test.dart` | Lihat bagian di bawah |

**Hapus animasi di uji widget.** `pompaAplikasi` di `bantu.dart` menyalakan Hapus animasi (`accessibilityFeaturesTestValue`). Tanpa itu, kilau kerangka memuat berulang tanpa henti dan `pumpAndSettle` tidak pernah selesai selama kerangka tampil. Gerak dengan animasi aktif diuji tersendiri di `gerak_test.dart` memakai `pump(durasi)`.

**Unit API** (`klien_api_test.dart`) wajib mencakup:

- setiap baris katalog kontrak §8 → jenis galat, `kode`, dan field yang benar;
- 401 memanggil `padaTidakSah`, kecuali pada `login`;
- header `Authorization`, `Content-Type`, dan `Idempotency-Key` hanya muncul di aksi yang mewajibkannya;
- kunci baru per simpan, dan kunci sama saat `kirimUlang`;
- timeout → `GalatJaringan`;
- `X-Api-Versi` yang tidak cocok → `GalatVersi`;
- `"ulang": true` dianggap sukses;
- field jawaban yang tidak dikenal diabaikan;
- jawaban bukan JSON ditangani menurut status HTTP.

**Uji integrasi** (opsional per slice; target server lokal dengan `uji_operator`):

1. Alurnya: masuk → tambah donatur `UJI-MOBILE <waktu>` → input sumbangan ke donatur itu dua kali (yang kedua memicu K5 lalu dikonfirmasi) → ubah di Input Saya → rekap hari.
2. **Hanya** donatur `UJI-MOBILE …` yang dibuat uji itu sendiri yang boleh ditulisi.
3. Sebelum uji, rekam sidik data. Sesudah uji, jalankan perintah "Bersihkan data uji integrasi"; sidik data harus sama.
4. Emulator tanpa layar belum pernah dicoba di mesin ini (docs/16_DEBUGGING_GUIDE.md). Bila gagal berjalan, lakukan alur ini manual dan catat hasilnya.

**Prasyarat server:** sebelum bagian klien sebuah slice dimulai, `php tests/api.php` harus LULUS di repo root (docs/03_ROADMAP.md).

Dilarang menghapus, melewati (`skip`), atau melonggarkan uji agar hijau (docs/18_REPAIR_RULES.md).
