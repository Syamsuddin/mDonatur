# 06 — BUSINESS_PROCESS

Isi permintaan, jawaban, dan kode galat ada di `API_CONTRACT.md` §6–§8. Cara tiap kode galat ditampilkan ada di docs/14_ERROR_HANDLING.md. Hak per peran ada di docs/05_USER_ROLE.md. Setiap simpan memakai **kunci kirim ulang baru**; Kirim ulang setelah putus jaringan memakai **kunci yang sama** (kontrak §7).

## P0 Buka aplikasi

1. Baca token dan alamat server dari secure storage. Alamat yang disimpan di Pengaturan menang atas `SERVER_URL` bawaan build.
2. Tanpa token → layar Masuk.
3. Ada token → panggil `konfigurasi`:
   - 200 → cek versi (kontrak §9) → tab Input;
   - 401 → Masuk;
   - galat jaringan → panel galat dengan Coba lagi. Token tidak dihapus.
4. Setiap kali aplikasi kembali ke depan (resume), panggil `konfigurasi` lagi. `hari_ini` dan peran ikut diperbarui, termasuk saat tanggal berganti tengah malam.

## P1 Masuk

- *Normal:* Username dan Password → `login`. Simpan token, kedaluwarsa, dan username terakhir → `konfigurasi` → tab Input. Pengguna dan peran tidak disimpan di perangkat; keduanya selalu dari `konfigurasi` (docs/05_USER_ROLE.md).
- Layar Masuk punya ikon Pengaturan, supaya alamat server bisa diubah sebelum masuk.
- *Cabang:* `tidak_valid`, `login_gagal`, `login_terkunci`, `api_mati`, galat jaringan, versi tidak cocok. Isian tetap.

## P2 Input Sumbangan (layar awal, tab Input)

1. **Saat dibuka,** panggil `donasisaya` tanpa tanggal untuk mengisi strip satu baris "Total input hari ini (N×): Rp X". Strip tidak menampilkan daftar input terakhir (keputusan pemilik 10 Okt 2026).
2. **Cek donatur.** Ketik Nomor Donator (keypad angka, maksimal 5 digit) → Cek → `donatur`. Hasilnya kartu donatur: nama, alamat, No HP, keterangan, bintang, riwayat tahun ini, dan total tahun ini.
   - Ikon cari di sebelah isian membuka layar **Cari Donatur** (`caridonatur`, minimal 2 huruf). Ketuk satu hasil → nomor terisi → Cek otomatis.
   - Mengubah nomor membuang hasil Cek. **Simpan hanya aktif bila ada hasil Cek untuk nomor yang tertulis** [ASUMSI].
3. **Jumlah**
   - Bila `saran_jumlah` tidak `null`, nilainya mengisi Jumlah hanya bila Jumlah kosong atau masih berisi saran sebelumnya (penanda "otomatis"). Ketikan pengguna atau ketukan nominal cepat menghapus penanda itu. Aturan ini sama dengan Fase 11 web (`isiSaranJumlah()`).
   - Tombol nominal cepat diambil dari `konfigurasi.nominal_umum` yang ≤ Rp 300.000, yaitu enam tombol 50.000–300.000 (keputusan pemilik 10 Okt 2026); ketukan mengisi Jumlah. Saran di atas Rp 300.000 tetap mengisi Jumlah.
4. **Jumlah < 1.000:** sebelum mengirim, tampilkan dialog lokal "Nominal Rp {jumlah} — benar?" dengan tombol **Ya, simpan** / **Tidak** (T16). Tidak → kembali ke isian Jumlah.
5. **Simpan** → `tambahdonasi`. Pada 201, atau 2xx dengan `"ulang": true`:
   - tampilkan kartu hasil (nama, nominal, jam WITA);
   - perbarui strip dari `ringkasan_hari_ini`;
   - kosongkan Nomor dan Jumlah, tutup kartu donatur, dan fokus ke Nomor Donator.
6. **409 `perlu_konfirmasi`:** dialog konfirmasi berisi `alasan` dan `donatur`. **Ya, simpan** mengirim isi yang sama dengan `konfirmasi: true` dan kunci baru. **Tidak** kembali ke isian.
7. **Timeout atau tanpa jaringan:** isian tetap, dan tombol **Kirim ulang** memakai kunci yang sama.
8. **401:** layar Masuk tampil di atas kerangka (docs/08_ARCHITECTURE.md). Setelah masuk, isian masih ada dan pengguna menekan Simpan lagi.

## P3 Tambah Donatur (tab Donatur)

1. Isian: Nama Donator, Alamat, Nomor Handphone, Keterangan, dan Sumbangan Pertama.
2. **Nama mirip.** Setelah Nama berisi ≥ 2 huruf dan pengguna berhenti mengetik 500 ms [ASUMSI], panggil `caridonatur` dengan `q` = Nama. Hasilnya tampil sebagai daftar peringatan "Nama mirip". Bila `lebih: true`, tampilkan "Persempit pencarian".
   - Ketuk satu nama → pindah ke tab Input dengan nomor terisi dan Cek otomatis. Isian Tambah Donatur tidak dihapus.
3. Sumbangan Pertama < 1.000 → dialog lokal seperti P2.4.
4. **Simpan** → `tambahdonatur`. Pada 201:
   - kartu hasil menampilkan Nomor Register besar dan nominal;
   - strip hari ini di tab Input diperbarui dari `ringkasan_hari_ini`;
   - isian dikosongkan.
5. **409 `donatur_sudah_ada`:** tampilkan nomor yang sudah ada beserta aksi "Input sumbangan untuk nomor ini" (pindah ke tab Input, nomor terisi, Cek otomatis).
6. **409 `perlu_konfirmasi` (K9):** sama dengan P2.6. **422:** pesan di bawah tiap isian, termasuk untuk teks di luar Latin-1 seperti emoji.

## P4 Input Saya (tab) dan Ubah Sumbangan

1. Saat dibuka, panggil `donasisaya` tanpa tanggal. Tanggal bisa diganti lewat date picker; nilai awalnya `konfigurasi.hari_ini`, dan tanggal setelah hari ini tidak bisa dipilih. Tarik ke bawah untuk memuat ulang.
2. Layar menampilkan total, transaksi, dan daftar baris (jam, nomor dan nama donatur, jumlah).
   - `nama_donatur: null` → tulis "(donatur terhapus)".
   - `note_n: true` (hanya admin) → jam ditulis tebal, tanpa label.
3. Baris `boleh_ubah: true` bisa diketuk dan membuka lembar bawah **Ubah**, dengan Jumlah lama sudah terisi → Simpan (< 1.000 → dialog lokal) → `ubahdonasi`. Pada 200: tutup lembar, lalu muat ulang `donasisaya`.
4. Baris `boleh_ubah: false` tidak bisa diketuk dan tidak punya ikon ubah. Tidak ada aksi hapus.
5. *Cabang:*
   - 403 `tidak_berhak`;
   - 404 `tidak_ada` → muat ulang daftar;
   - 409 `perlu_konfirmasi` → seperti P2.6;
   - 422;
   - galat jaringan → Kirim ulang dengan kunci yang sama.

## P5 Rekap (tab)

1. Bawaan: periode Hari, cakupan Input saya, tanggal `konfigurasi.hari_ini`.
2. **Kontrol**
   - Segmen Hari / Minggu / Bulan, dan segmen Input saya / Semua operator. Mengganti segmen memakai `tanggal` yang sama.
   - Panah ← memuat `navigasi.sebelum`. Panah → memuat `navigasi.sesudah`, dan nonaktif bila nilainya `null`.
   - Judul menampilkan rentang `dari`–`sampai`.
3. **Isi**
   - Total, transaksi, dan donatur. Labelnya harus tegas: "Transaksi" berbeda dengan "Donatur".
   - Rincian per hari untuk Minggu dan Bulan.
   - Rincian per operator untuk Semua operator, termasuk baris "User lama (sudah dihapus)".
4. `transaksi` = 0 → state kosong "Tidak ada sumbangan pada periode ini".

## P6 Ganti Password (menu ⋮)

1. Password Lama, Password Baru, dan Ulangi Password Baru → `gantipassword`. Pada 200: ganti token tersimpan dengan token baru, tampilkan "Password berhasil diganti.", lalu kembali.
2. *Cabang:* 409 `fitur_belum_tersedia`, 429 `login_terkunci`, 422 per isian.
3. **Putus koneksi setelah mengirim** (kontrak §6.10): hapus token dan buka Masuk dengan pesan "Koneksi terputus. Masuk dengan password baru; bila gagal, pakai password lama."

## P7 Keluar, pencabutan akses, dan Pengaturan

- **Keluar** (menu ⋮)
  - Bila ada isian yang belum disimpan di tab mana pun, tampilkan dialog "Isian yang belum disimpan akan hilang. Keluar?" dengan tombol **Keluar** / **Batal**.
  - Lalu hapus token, kedaluwarsa, dan semua state di memori (konfigurasi, pengguna, isi layar). Alamat server dan username terakhir tetap disimpan.
  - Lalu kirim `logout` dengan token lama di latar belakang (kontrak §6.11, sejak 0.2.0): server mencatatnya di log aktivitas dan mencabut token itu. Tidak ditunggu, tidak diulang, dan galat apa pun (jaringan, 401, 404 server lama, versi tidak cocok) diabaikan tanpa pesan maupun layar versi.
- **Pencabutan:** 401 `akun_nonaktif` atau `token_*` pada permintaan mana pun → docs/14_ERROR_HANDLING.md.
- **Pengaturan** (menu ⋮ dan layar Masuk)
  - Alamat server: garis miring di akhir dibuang. Build rilis hanya menerima `https`; build debug juga menerima `http`. Tombol "Pakai alamat bawaan" kembali ke `SERVER_URL`.
  - Mengubah alamat saat sudah masuk menghapus token (token itu milik server lama) → Masuk [ASUMSI].
  - Informasi diagnosa: versi aplikasi, versi kontrak klien, `versi_api` server, username, peran, dan kedaluwarsa token.
