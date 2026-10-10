# Arsip 23 — S2 Input sumbangan (F3, F4)

Diterima 10 Okt 2026. Blok ini dipindah dari docs/23_ACCEPTANCE_CRITERIA.md (aturan emas #6 INDEX); penegakannya kini di test suite. Bukti: `flutter test test/layar/input_sumbangan_test.dart test/layar/cari_donatur_test.dart test/api/klien_api_test.dart` → `All tests passed!` (suite penuh 193 uji), ditambah demo di emulator Pixel_5 Android 13 terhadap server lokal (`../UPDATE_PLAN.md` "Hasil uji 12c slice S2"). Bagian server slice ini (aksi `donatur`, `caridonatur`, `tambahdonasi`, `donasisaya`) selesai di 12b; `php tests/api.php` LULUS 158 cek sebelum klien dimulai.

## F3 Cek dan cari donatur (S2)

- [x] Jawaban `donatur` dari contoh kontrak §6.3 → kartu menampilkan nama, alamat, No HP, keterangan, lencana bintang sesuai `bintang`, riwayat, dan total tahun ini. *Uji "jawaban contoh kontrak §6.3 → kartu lengkap" dan "keterangan dan bintang lain ikut tampil"; warna lencana 0–5 diuji terhadap tabel token. Demo: Cari "UJI-MOBILE" → ketuk → kartu "Bintang 0", riwayat 10/10/2026 Rp 1.000.*
- [x] 404 `tidak_ada` → `pesan` server tampil di dekat isian Nomor Donator. *Uji "404 tidak_ada → pesan server di isian Nomor Donator" (`errorText`); 422 `rincian.id` juga ke isian itu (docs/14).*
- [x] Isian Nomor Donator hanya menerima digit, paling banyak 5. *Uji "Nomor Donator hanya digit, paling banyak 5".*
- [x] Cari Donatur: `q` kurang dari 2 huruf tidak dikirim; hasil tampil; `lebih: true` → "Persempit pencarian"; ketuk hasil → nomor terisi dan Cek otomatis. *`test/layar/cari_donatur_test.dart` (12 uji, termasuk jeda 500 ms, `q` dipangkas, jawaban lama dibuang); demo di emulator.*
- [x] Riwayat ber-`note_n` (jawaban admin) tampil dengan tanggal tebal, tanpa label. *Uji "riwayat note_n (admin) → tanggal tebal tanpa label".*

## F4 Input sumbangan (S2)

- [x] Simpan nonaktif sampai Cek berhasil untuk nomor yang tertulis; mengubah nomor menonaktifkannya lagi. *Uji "Simpan aktif hanya setelah Cek untuk nomor yang tertulis"; uji mutasi M3 membuatnya merah.*
- [x] **Saran Jumlah** mengisi Jumlah yang kosong; tidak menimpa Jumlah yang diketik pengguna; mengganti saran sebelumnya saat Cek ke donatur lain. *Tiga uji saran, ditambah nominal cepat yang tidak ditimpa; uji mutasi M2 membuatnya merah.*
- [x] Tombol nominal cepat sama dengan `nominal_umum`, dengan urutan yang sama. *Uji dengan `nominal_umum` tidak urut [100.000, 50.000, 2.000.000, 150.000]; label Semantics "Rp …".*
- [x] Jumlah 500 → dialog lokal; memilih Tidak → tidak ada permintaan terkirim. *Uji "Jumlah 500 → dialog lokal …" dan "Jumlah 1.000 tidak memakai dialog lokal"; uji mutasi M4 membuatnya merah.*
- [x] **Jawaban 201**: kartu hasil tampil; strip sama dengan `ringkasan_hari_ini`; Nomor dan Jumlah kosong, fokus di Nomor Donator. *Uji "201 → kartu hasil …" dan "2xx dengan "ulang": true diperlakukan sukses"; demo: kartu hasil "Data Sumbangan Berhasil Disimpan … 13:36 WITA", isian kosong, strip 3× → 4× (sumbangan 145681; lihat catatan data lokal di `../UPDATE_PLAN.md`).*
- [x] **409 `perlu_konfirmasi`**: dialog memuat semua `alasan` dan nama donatur; Ya → permintaan kedua dengan `konfirmasi: true` dan `Idempotency-Key` yang berbeda dari yang pertama. *Uji "409 … Ya → konfirmasi true dengan kunci baru" dan "409 … Tidak: tanpa permintaan kedua"; tidak didemokan di emulator.*
- [x] **Timeout**: panel tampil dengan tombol Kirim ulang; kiriman ulang memakai `Idempotency-Key` dan isi yang sama persis. *Uji "timeout → panel Kirim ulang …" (batas 20 detik), "isian diubah setelah galat jaringan → Kirim ulang hilang …", "500 galat_server → … Coba lagi dengan kunci sama"; uji mutasi M1 membuatnya merah.*

## Semua layar (bagian S2)

- [x] Empat state: Input Sumbangan Cek (petunjuk / indikator di Cek / `errorText` atau panel / kartu donatur), Simpan (— / Simpan nonaktif + indikator / panel, isian tetap / kartu hasil, isian kosong), dan Cari Donatur (petunjuk / kerangka daftar / panel + Coba lagi / daftar atau "Tidak ada donatur yang cocok"). Strip: kerangka memuat / panel + Coba lagi / total.
- [x] 360×640 dp, `textScaler` 1,3, tanpa luapan: kartu donatur panjang, 10 nominal cepat, strip 6 butir, `errorText`, kartu hasil, Cari Donatur dengan 20 hasil dan panel galat, kerangka dengan tab Input sungguhan.
- [x] Setiap isian punya `labelText` (Nomor Donator, Sumbangan, "Nama, alamat, atau nomor"). Nominal tampil sebagai teks "Rp …", tombol nominal cepat dibacakan "Rp …", lencana "Bintang {n} dari 5".
- [x] Galat tampil sesuai docs/14_ERROR_HANDLING.md "Tempat tampil"; isian tetap, juga setelah 401 dan masuk lagi (uji "401 saat Simpan …").

## Perubahan sesudah diterima (10 Okt 2026, permintaan pemilik)

- Strip menjadi satu baris "Total input hari ini (N×): Rp X" tanpa daftar input terakhir. Butir "strip sama dengan `ringkasan_hari_ini`" kini berarti total dan banyaknya input saja.
- Nominal cepat hanya `nominal_umum` ≤ Rp 300.000 (enam tombol, kisi 3 kolom). Butir "sama dengan `nominal_umum`, urutan sama" kini berlaku untuk nilai yang lolos batas itu.
- Kartu donatur ringkas: riwayat "dd/MM Rp jumlah" yang terlipat, dengan "Riwayat {tahun}" dan "Total Rp X" sebaris.
- Bukti: uji yang disesuaikan di `test/layar/input_sumbangan_test.dart`, ditambah `test/layar/input_sumbangan_muat_test.dart` (muat tanpa gulir di 393×851 dp dengan Roboto).
