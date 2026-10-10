# 23 — ACCEPTANCE_CRITERIA

Kriteria per fitur aktif. Alur rinci: docs/06_BUSINESS_PROCESS.md. Pola antarmuka: docs/26_UI_CONVENTIONS.md. Perintah: docs/11_COMMANDS.md. Gerbang umum: docs/24_DEFINITION_OF_DONE.md. Setiap fitur juga mensyaratkan bagian server slicenya LULUS (`php tests/api.php` di repo root, docs/03_ROADMAP.md).

## Semua layar (diperiksa di setiap slice)

- [ ] Layar ber-data menampilkan empat state sesuai tabel di docs/26_UI_CONVENTIONS.md.
- [ ] Dirender di 360×640 dp dengan `textScaler` 1,3 tanpa overflow.
- [ ] Setiap isian punya label. Nominal dan lencana bintang punya label `Semantics`.
- [ ] Galat ditampilkan sesuai tabel "Tempat tampil" di docs/14_ERROR_HANDLING.md, dan isian tidak hilang.

Verifikasi: `flutter test test/layar/` → `All tests passed!`. Perintah "Cek warna literal", "Cek `print`", dan "Cek alamat tertanam" → keluaran kosong.

## F1 Masuk dan keluar (S1)

- [ ] `uji_operator` dengan password benar → token tersimpan di secure storage → `konfigurasi` dipanggil → tab Input tampil.
- [ ] `login_gagal` → panel berisi `pesan` server; isian Username tetap.
- [ ] `login_terkunci` → panel berisi `pesan` server. `api_mati` → "Layanan mobile belum diaktifkan di server."
- [ ] Aplikasi dibuka dengan token yang dijawab 401 → layar Masuk.
- [ ] Ada isian di tab Input, lalu permintaan berikutnya dijawab 401 → Masuk tampil di atas kerangka; setelah masuk, isian masih ada.
- [ ] `versi_api` `"0.2.0"` (klien 0.1.0) → layar blokir dengan pesan kontrak §9.
- [ ] Keluar saat ada isian belum disimpan → dialog konfirmasi. Setelah Keluar, token terhapus, sedangkan alamat server dan username terakhir tetap.

Verifikasi: `flutter test test/layar/masuk_test.dart test/api/klien_api_test.dart` → `All tests passed!`. Demo di emulator: masuk dan keluar sebagai `uji_operator`.

## F2 Pengaturan alamat server (S1)

- [ ] `http://host/donatur/` disimpan sebagai `http://host/donatur` (build debug), dan aksi dipanggil ke `http://host/donatur/api?aksi=<aksi>`.
- [ ] Validasi alamat dengan mode rilis menolak `http://…` dan menerima `https://…`.
- [ ] Mengganti alamat saat sudah masuk menghapus token → Masuk. "Pakai alamat bawaan" mengembalikan `SERVER_URL`.
- [ ] Pengaturan menampilkan versi aplikasi, `versiKontrak`, `versi_api`, username, peran, dan kedaluwarsa.

Verifikasi: `flutter test test/layar/pengaturan_test.dart` → `All tests passed!`.

## F3 Cek dan cari donatur (S2)

- [ ] Jawaban `donatur` dari contoh kontrak §6.3 → kartu menampilkan nama, alamat, No HP, keterangan, lencana bintang sesuai `bintang`, riwayat, dan total tahun ini.
- [ ] 404 `tidak_ada` → `pesan` server tampil di dekat isian Nomor Donator.
- [ ] Isian Nomor Donator hanya menerima digit, paling banyak 5.
- [ ] Cari Donatur: `q` kurang dari 2 huruf tidak dikirim; hasil tampil; `lebih: true` → "Persempit pencarian"; ketuk hasil → nomor terisi dan Cek otomatis.
- [ ] Riwayat ber-`note_n` (jawaban admin) tampil dengan tanggal tebal, tanpa label.

Verifikasi: `flutter test test/layar/input_sumbangan_test.dart test/layar/cari_donatur_test.dart` → `All tests passed!`.

## F4 Input sumbangan (S2)

- [ ] Simpan nonaktif sampai Cek berhasil untuk nomor yang tertulis; mengubah nomor menonaktifkannya lagi.
- [ ] **Saran Jumlah**
  - mengisi Jumlah yang kosong;
  - tidak menimpa Jumlah yang diketik pengguna;
  - mengganti saran sebelumnya saat Cek ke donatur lain.
- [ ] Tombol nominal cepat sama dengan `nominal_umum`, dengan urutan yang sama.
- [ ] Jumlah 500 → dialog lokal; memilih Tidak → tidak ada permintaan terkirim.
- [ ] **Jawaban 201**
  - kartu hasil tampil;
  - strip sama dengan `ringkasan_hari_ini`;
  - Nomor dan Jumlah kosong, fokus di Nomor Donator.
- [ ] **409 `perlu_konfirmasi`**
  - dialog memuat semua `alasan` dan nama donatur;
  - Ya → permintaan kedua dengan `konfirmasi: true` dan `Idempotency-Key` yang berbeda dari yang pertama.
- [ ] **Timeout**
  - panel tampil dengan tombol Kirim ulang;
  - kiriman ulang memakai `Idempotency-Key` dan isi yang sama persis.

Verifikasi: `flutter test test/layar/input_sumbangan_test.dart test/api/klien_api_test.dart` → `All tests passed!`. Demo di emulator: simpan, lalu strip bertambah.

## F5 Tambah donatur (S3)

- [ ] Mengetik Nama "Fulan" huruf demi huruf → `caridonatur` dipanggil sekali, 500 ms setelah ketikan terakhir. Hasil tampil sebagai "Nama mirip".
- [ ] Ketuk nama mirip → tab Input, nomor terisi, Cek otomatis; isian Tambah Donatur tetap.
- [ ] 201 → kartu hasil dengan Nomor Register (32/40, tebal); isian kosong; strip di tab Input diperbarui.
- [ ] 409 `donatur_sudah_ada` → nomor yang ada tampil bersama aksi "Input sumbangan untuk nomor ini".
- [ ] 422 dengan `rincian.nama` → `errorText` di Nama Donator; isian lain tetap.
- [ ] Sumbangan Pertama 500 → dialog lokal.

Verifikasi: `flutter test test/layar/tambah_donatur_test.dart` → `All tests passed!`.

## F6 Input Saya dan ubah (S4)

- [ ] Saat dibuka, `donasisaya` dipanggil tanpa `tanggal`; total dan transaksi tampil.
- [ ] Baris `boleh_ubah: false` tidak bisa diketuk dan tidak punya ikon ubah. Tidak ada aksi hapus di layar mana pun.
- [ ] Ubah dijawab 200 → lembar tertutup dan daftar dimuat ulang. 403 → `pesan` server tampil di lembar.
- [ ] `nama_donatur: null` → "(donatur terhapus)". `note_n: true` → jam tebal.
- [ ] Date picker tidak bisa memilih tanggal setelah `hari_ini`. Daftar kosong → "Belum ada input pada tanggal ini".

Verifikasi: `flutter test test/layar/input_saya_test.dart` → `All tests passed!`.

## F7 Rekap (S5)

- [ ] Bawaan: `periode=hari`, `cakupan=saya`, tanggal `hari_ini`. Mengganti segmen memanggil `rekap` dengan tanggal yang sama.
- [ ] Panah → nonaktif bila `navigasi.sesudah` `null`. Panah ← memuat `navigasi.sebelum`.
- [ ] Label "Transaksi" dan "Donatur" terpisah.
- [ ] Rincian per operator hanya tampil untuk Semua operator; baris `id_user: null` tampil sebagai "User lama (sudah dihapus)".
- [ ] `transaksi` = 0 → "Tidak ada sumbangan pada periode ini".

Verifikasi: `flutter test test/layar/rekap_test.dart` → `All tests passed!`. Di server, paritas rekap dengan halaman web diuji oleh `php tests/api.php`.

## F8 Ganti password dan APK debug (S6)

- [ ] 200 → token tersimpan diganti token baru, dan permintaan berikutnya membawa token baru.
- [ ] 422 → `errorText` pada `lama`/`baru`/`ulang` sesuai `rincian`. 409 `fitur_belum_tersedia` → panel berisi `pesan`.
- [ ] `GalatJaringan` setelah mengirim → token dihapus → Masuk dengan pesan P6.3.
- [ ] Perintah "APK debug" menghasilkan `app-debug.apk`, dan alur masuk → input → konfirmasi → rekap berjalan di emulator terhadap server lokal.

Verifikasi: `flutter test test/layar/ganti_password_test.dart` → `All tests passed!`, lalu perintah "APK debug".
