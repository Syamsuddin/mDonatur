# 16 — DEBUGGING_GUIDE

Lokasi log: docs/15_OBSERVABILITY.md. Perintah: docs/11_COMMANDS.md.

## Gejala → diagnosa

| Gejala | Penyebab yang mungkin | Langkah |
|---|---|---|
| Emulator tidak bisa menghubungi server | Alamat salah, server mati, atau cleartext belum diizinkan di build debug | `SERVER_URL` harus `http://localhost:8000` dan `adb reverse tcp:8000 tcp:8000` sudah dijalankan sejak emulator terakhir menyala (cek `adb reverse --list`); server `php -S` harus jalan; periksa manifest `src/debug` (docs/21_SECURITY_RULES.md) |
| HP fisik tidak bisa menghubungi server | Server hanya mendengar `localhost` | Sambungkan lewat USB dan jalankan `adb reverse tcp:8000 tcp:8000`, atau jalankan `php -S 0.0.0.0:8000 …` dan pakai IP LAN mesin |
| APK rilis sama sekali tanpa jaringan | Izin `INTERNET` hanya ada di manifest debug/profile buatan Flutter | Tambahkan izin itu di `android/app/src/main/AndroidManifest.xml` |
| `SERVER_URL` sudah diganti, aplikasi tetap ke alamat lama | Alamat di Pengaturan menang atas `SERVER_URL` | Tekan "Pakai alamat bawaan" di Pengaturan |
| Semua aksi 401 di Apache (PHP-FPM/CGI), padahal token baru | Header `Authorization` dibuang web server | Bug server: aturan `.htaccess` `E=HTTP_AUTHORIZATION` (`../UPDATE_PLAN.md` Fase 12) |
| 401 `token_tidak_sah` tepat setelah pengguna login di web | `password_cocok()` memperbarui hash password, sehingga token lama batal (kontrak §3) | Wajar; pengguna masuk lagi |
| Login di HP terkunci (429) padahal yang salah password di web | Penghitung penguncian dipakai bersama web, per IP + username; IP seluler bisa berganti | Wajar; tunggu sesuai `sisa_detik` |
| `gantipassword` → 409 `fitur_belum_tersedia` | Migrasi M1 belum dijalankan di server (produksi masih begitu) | Tampilkan `pesan`; token tetap berlaku |
| Angka rekap "tidak cocok" dengan web | "Jumlah Donatur … orang" di `rekapoperator`/`rekapalloperator` sebenarnya jumlah transaksi; `rekapoperator` juga tidak menghitung user terhapus | Bandingkan dengan tabel paritas kontrak §6.9, bukan dengan label web |
| Jam sumbangan lama tampak 8 jam lebih awal | Data sebelum deploy tercatat dalam UTC, data baru dalam WITA (K1) | Tampilkan apa adanya; **jangan** mengonversi |
| Pesan K5 menyebut jumlah lebih banyak dari baris yang dilihat operator | K5 menghitung semua sumbangan donatur hari itu, termasuk Note n | Paritas dengan web [TERBUKA T13]; bukan bug klien |
| Tambah donatur dengan emoji → 500 | Server belum menolak teks di luar Latin-1 | Bug server; seharusnya 422 (kontrak §4) |
| Nominal 400.000 dan 600.000 tidak ada di tombol cepat | `NOMINAL_UMUM` server tidak memuatnya | Keputusan server [TERBUKA T8]; klien tidak menambah sendiri |
| Rekap "Minggu ini" pada hari Minggu terus berubah | Minggu adalah hari tersibuk sekaligus hari terakhir pekan (K14) | Wajar |

## Jebakan klien

- **Nama paket.** "mDonator" bukan nama paket Dart yang sah. `flutter create` wajib memakai `--project-name mdonator` (docs/11_COMMANDS.md).
- **`flutter create .` di folder ini** menambah `README.md`, `.gitignore`, dan `test/widget_test.dart` contoh. Hapus uji contoh itu, dan jangan menimpa berkas paket blueprint.
- **Dua CLAUDE.md.** Sesi Claude Code di `mDonator/` ikut memuat `../CLAUDE.md` (aturan server PHP). Untuk kode di `mDonator/`, paket ini yang berlaku. Aturan root berlaku saat menyentuh berkas di luar `mDonator/`.
- **Urutan sumber.** Untuk API, `API_CONTRACT.md` menang atas semua dokumen. `DOSIR_MDONATOR.md` hanya bahan asal; bila beda dengan `docs/`, docs menang.
- **Tipe data.** `jumlah` dan `id_donatur` dikirim sebagai bilangan bulat JSON; string seperti `"100000"` dijawab 422. Nomor donatur 1–32767.
- **Visibilitas admin.** Baris `note_n` dan `boleh_ubah` untuk tanggal lain hanya muncul bagi `uji_admin`. Uji visibilitas harus memakai kedua akun.
- **Font di uji widget.** Uji widget tidak memuat huruf dari `pubspec.yaml`; keluarga yang belum dimuat digambar dengan font uji Flutter (setiap huruf selebar 1 em), sehingga teks lebih cepat terlipat daripada di HP. Uji "muat satu layar" (`test/layar/input_sumbangan_muat_test.dart`) memuat Plus Jakarta Sans dan Outfit dari `assets/huruf/` dengan `FontLoader`; jangan mengukur tinggi layar dengan font uji.
- **Kilau dan `pumpAndSettle`.** Kilau `Skeletonizer` berulang tanpa henti. Selama kerangka memuat tampil dengan animasi aktif, `pumpAndSettle` habis waktu. Uji widget menyalakan Hapus animasi lewat `bantu.dart`; uji gerak memakai `pump(durasi)`.
- **`flutter_animate` di uji.** Jangan memberi `delay` pada `Animate` itu sendiri (efeknya boleh): penundaan awal memakai timer yang masih tertunda saat uji selesai dan menggagalkan uji.
- **Edge-to-edge.** Android 15 ke atas menggambar aplikasi di bawah status bar dan mengabaikan `statusBarColor`; `main.dart` menyalakan `SystemUiMode.edgeToEdge` agar Android 13 sama. Kepala dasbor memang mengisi area status bar; jangan menambah `SafeArea` atas di dalam lembar.
- **`ListView` dan status bar transparan.** `ListView` tanpa `padding` menambah padding atas setinggi status bar. Di layar Masuk itu meninggalkan pita putih di atas kepala (ditemukan di emulator S7), jadi daftar di sana memakai `padding: EdgeInsets.zero`. Daftar di dalam `LatarDasbor` aman karena padding atasnya sudah dibuang.
- **Tab tersembunyi tetap bergerak.** `IndexedStack` menjaga tab lain tetap hidup, termasuk animasinya. Tanpa `TickerMode(enabled: false)` di kerangka, kerangka memuat tab yang belum pernah dibuka terus berkilau di belakang layar.
- **`AnimatedSize` berdurasi nol** melempar galat tata letak saat ukurannya berubah. Tanpa gerak, ganti isinya langsung tanpa `AnimatedSize`.
- **Jarak huruf Material 3** (0,1–0,5 sp) dirancang untuk Roboto. Token huruf docs/26 menetapkan 0; tanpa itu baris kartu donatur terlipat dan uji muat gagal.
- **Uji gerak dan `flutter_animate`.** Animasi `flutter_animate` mulai setelah frame pertama widget, dan selama pudar dari opasitas 0 widget tidak masuk pohon semantics. Satu `pump(durasi)` hanya satu frame, jadi majukan dua frame sebelum memeriksa keadaan di tengah gerak.
- **Label `Semantics` tanpa `container: true`** bergabung ke node induk (kartu), sehingga `find.bySemanticsLabel` tidak menemukannya. Nominal kartu hasil dan grafik memakai `container: true`.
- **Emulator dipakai bersama.** Pengguna atau sesi lain bisa sedang memakai aplikasi di emulator. Ketukan `adb shell input` lalu bisa mengenai isian orang lain dan menyimpan data; periksa layar dulu, dan jangan menekan Simpan lewat `adb` tanpa koordinasi.
- **Emulator tanpa layar** belum pernah dicoba di mesin ini, dan headless Chrome diketahui macet. Bila uji integrasi tidak bisa berjalan otomatis, jalankan alurnya manual.

Jebakan implementasi server (sesi di repo root) ada di `DOSIR_MDONATOR.md` §12 (L1, L9–L13, L19–L20) dan `../UPDATE_PLAN.md` Fase 12.
