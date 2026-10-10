# Dosir mDonator — bahan blueprint VCBD

Klien mobile (Flutter, Android) untuk kerja operator aplikasi Donatur Yayasan Ibnu Atha'illah (Kapuh Madani, Kandangan).

- **Disusun:** 10 Okt 2026, dari kode repo `donatur` (cabang `pembaruan`, commit `b140a79` ditambah perubahan kerja Fase 10–11), DB lokal (salinan dump produksi 8 Okt 2026), keputusan pemilik di `UPDATE_PLAN.md` (Fase 12, §9 K11–K19), dan pemeriksaan mesin pengembangan.
- **Status:** dosir bahan. Belum melewati gerbang konfirmasi VCBD (Fase 2). Dosir ini bukan bagian dari paket 28 dokumen.
- **Tidak memuat data pribadi.** Semua angka data adalah agregat.

## 0. Cara memakai dosir ini

**Untuk skill `vcbd`:**

- Baca dosir ini di Fase 0 (Triase) sebagai **fakta diketahui**. Yang berlabel [FAKTA] dan [KEPUTUSAN] tidak ditanyakan ulang.
- Wawancara cukup menyelesaikan daftar [TERBUKA] (§15) dan mengonfirmasi [ASUMSI] (§14) sebagai satu blok.
- Draf Ringkasan Kebutuhan ada di §16, benih manifest di §17, dan peta bagian dosir ke dokumen 00–27 di §18.

**Label**

| Label | Arti |
|---|---|
| [FAKTA] | Terbaca dari kode, skema, DB lokal, atau mesin; disertai rujukan `path:baris` bila perlu |
| [KEPUTUSAN] | Diputuskan pemilik (K-nomor di `UPDATE_PLAN.md` §9) |
| [RANCANGAN] | Tertulis di `UPDATE_PLAN.md` Fase 12 sebagai rancangan, belum dikonfirmasi pemilik butir demi butir |
| [ASUMSI] | Dipakai bila tidak dikoreksi |
| [TERBUKA] | Butuh keputusan pemilik; disertai rekomendasi |

**Presedensi.** Untuk fakta yang punya padanan kode (skema, aturan bisnis, perintah), kode repo `donatur` menang atas dosir ini. Untuk keputusan dan rancangan Fase 12, `UPDATE_PLAN.md` menang. Bila dosir bertentangan dengan keduanya, berhenti dan laporkan.

## 1. Triase (Fase 0 VCBD)

| Butir | Isi |
|---|---|
| Nama aplikasi | **mDonator** |
| Deskripsi | Aplikasi Android untuk operator yayasan: input sumbangan, tambah donatur, Input Saya (daftar dan ubah nominal milik hari ini), rekap harian/mingguan/bulanan, dan ganti password. Datanya ada di server aplikasi Donatur (PHP native), diakses lewat API JSON baru. |
| Jenis | **Campuran.** Server: *brownfield* (API ditambahkan ke aplikasi berjalan yang sedang diperbarui Fase 0–11). Klien: *greenfield* (folder `mDonator/` masih kosong). [FAKTA] |
| Ber-UI | Ya untuk paket klien (`ui.enabled=true`). [FAKTA] |
| Mode | **SPLIT** direkomendasikan: klien adalah deployable terpisah (APK Flutter) di folder terpisah. Tata letak paket: lihat [TERBUKA] T1. |
| Profil framework | Server: `none`, tetapi **bukan** blok default profil native VCBD (lihat L1 di §12). Klien: Flutter (framework). [FAKTA] |
| Lokasi kode klien | `mDonator/` di root repo `donatur` [KEPUTUSAN K17] |
| Lingkungan kerja | Lokal saja. Deploy ditunda pemilik (9 Okt 2026); jangan merencanakan langkah server produksi. Distribusi APK ke HP operator tidak termasuk Fase 12. [KEPUTUSAN] |

## 2. K1 — Identitas dan tujuan → 00, 01

**Masalah** [FAKTA]

- Operator mencatat sumbangan lewat halaman web yang dirancang untuk desktop: lebar tata letak tetap 1000 px (`public/css/style.css`, `.wrap { width:1000px }`). Di HP, halaman ini sempit dan lambat dipakai.
- Input datang bergelombang: **Minggu pagi** dan **Kamis/Jumat malam**. Puncaknya 192 transaksi dalam sehari, dan satu operator pernah menginput 132 transaksi dalam sehari (§5, Statistik).

**Solusi.** Aplikasi Android ringan untuk empat tugas operator yang paling sering. Aturan bisnisnya tetap di server, sehingga web dan aplikasi selalu memakai aturan yang sama.

**Pengguna sasaran** [FAKTA]

- Akun dengan peran operator dan admin. Produksi punya 4 akun (`UPDATE_PLAN.md` §2).
- Dalam 12 bulan terakhir, 4 akun aktif menginput, ditambah satu ID user yang sudah terhapus (20 transaksi).

**Pemangku kepentingan.** Pemilik produk adalah pengelola aplikasi Donatur (pemilik repo). [FAKTA]

**Metrik sukses** [ASUMSI, lihat T12]

1. ≥ 80% sumbangan baru dalam 3 bulan setelah aplikasi dipakai tercatat lewat mDonator. Diukur dari porsi baris `"via":"mobile"` di `storage/logs/audit.log` [RANCANGAN].
2. Satu input sumbangan (nomor diketik → Simpan) selesai ≤ 15 detik di jaringan seluler, untuk donatur tanpa konfirmasi.

## 3. K2 — Fitur dan scope → 01, 02, 03

### 3.1 Fitur

| # | Fitur | Prioritas | Padanan web | Sumber |
|---|---|---|---|---|
| F1 | Masuk dan keluar (token) | MVP | `login`, `logout` | [KEPUTUSAN K11], cara login [TERBUKA T2] |
| F2 | Pengaturan alamat server | MVP | — | [RANCANGAN] |
| F3 | Cek donatur per nomor, dan cari donatur lewat nama/alamat | MVP | `search2`, pencarian `tampildonatur` | [KEPUTUSAN K11] |
| F4 | Input sumbangan: saran Jumlah, nominal cepat, konfirmasi K5/K9, kirim ulang aman | MVP | `tambahdonasi` → `prosestambahdonasi` | [KEPUTUSAN K11] |
| F5 | Tambah donatur beserta sumbangan pertama: peringatan nama mirip, duplikat persis, K9 | MVP | `tambahdonatur` → `prosestambahdonatur` | [KEPUTUSAN K11] |
| F6 | Input Saya (daftar per hari dan total) dan ubah nominal milik sendiri hari ini (K6) | MVP | `tampildonasi` (miliknya), `ubahdonasi` | [KEPUTUSAN K11, K15] |
| F7 | Rekap Hari / Minggu (Senin–Minggu) / Bulan, cakupan "Input saya" atau "Semua operator" | MVP | `rekapoperator`, `rekapalloperator`, `rekapbulanan` | [KEPUTUSAN K13, K14] |
| F8 | Ganti password | MVP | `gantipassword` | [KEPUTUSAN K11] |
| N1 | Pindai QR kartu donatur | Nanti | — | [ASUMSI] |
| N2 | Kirim bukti sumbangan lewat WhatsApp (tautan `wa.me`) | Nanti | — | [ASUMSI] |
| N3 | Versi iOS | Nanti | — | [TERBUKA T3] |

**User story MVP** (peran: lihat §4)

- **F1.** Sebagai operator, saya ingin masuk sekali di awal hari kerja agar bisa langsung menginput tanpa login berulang.
- **F2.** Sebagai pengelola, saya ingin mengisi alamat server di aplikasi agar aplikasi bisa dipakai di instalasi mana pun, termasuk subfolder.
- **F3.** Sebagai operator, saya ingin melihat nama, alamat, bintang, dan riwayat tahun ini setelah mengetik nomor agar yakin donaturnya benar. Bila donatur lupa nomornya, saya ingin mencarinya lewat nama.
- **F4.** Sebagai operator, saya ingin menyimpan sumbangan dengan sesedikit mungkin ketukan, dan diperingatkan bila donatur sudah menyumbang hari ini atau nominalnya besar, agar tidak terjadi salah catat.
- **F5.** Sebagai operator, saya ingin mendaftarkan donatur baru beserta sumbangan pertamanya, dan diperingatkan bila nama yang mirip sudah ada, agar tidak terjadi data ganda.
- **F6.** Sebagai operator, saya ingin melihat semua input saya hari ini beserta totalnya untuk serah terima uang, dan memperbaiki nominal yang salah ketik.
- **F7.** Sebagai operator, saya ingin melihat total harian, mingguan, dan bulanan, milik saya maupun semua operator.
- **F8.** Sebagai operator, saya ingin mengganti password dari HP.

**Kebutuhan non-fungsional** [ASUMSI kecuali disebut]

- Jawaban API untuk aksi baca ≤ 1 detik di server lokal, termasuk `rekap` bulan dengan cakupan semua.
- Aplikasi tetap bisa dipakai di jaringan seluler lemah: isian tidak hilang saat galat jaringan, dan kirim ulang tidak menggandakan data.
- Satu tangan, keypad angka untuk nomor dan nominal, dan target sentuh ≥ 48 dp.

### 3.2 Di luar scope

Semua ini [KEPUTUSAN] (K11, K15, `UPDATE_PLAN.md` §10):

1. Hapus donasi dari mobile (hapus tetap di web).
2. Input Khusus dan atribut Note (`Note='n'`): tidak bisa dibuat, dilihat, atau diubah operator.
3. Ubah dan hapus donatur, serta Kelola Pengguna.
4. Daftar sumbangan lengkap, grafik, dan rekap tahunan.
5. Mode offline. Waktu dicatat menurut jam server, jadi tanpa sinyal tidak ada input.
6. Aplikasi untuk donatur (riwayat sumbangan, notifikasi, pembayaran).
7. Perubahan skema database, termasuk tabel baru untuk token atau perangkat.
8. Distribusi APK atau Play Store, dan langkah server produksi.

### 3.3 Urutan rilis (vertical slice)

`UPDATE_PLAN.md` membagi Fase 12 per lapisan: 12a logika bersama → 12b API → 12c Flutter. Usulan slice di bawah memotongnya secara vertikal [ASUMSI]. Bila diterima, langkah di `UPDATE_PLAN.md` Fase 12 perlu diselaraskan.

| Slice | Tujuan yang bisa didemokan | Server | Klien |
|---|---|---|---|
| S0 | Kontrak `openapi.yaml` v0.1.0 dan mock berjalan | — | Proyek Flutter kosong memanggil mock |
| S1 | Masuk dan keluar | token, `login`, `konfigurasi`, `api.php`, aturan `.htaccess` | layar Masuk, Pengaturan |
| S2 | Input sumbangan dari awal sampai tersimpan | logika bersama donasi, `donatur`, `caridonatur`, `tambahdonasi`, kirim ulang aman | layar Input Sumbangan |
| S3 | Tambah donatur | logika bersama donatur, `tambahdonatur` | layar Tambah Donatur |
| S4 | Input Saya dan ubah nominal | `donasisaya`, `ubahdonasi` | layar Input Saya, Ubah |
| S5 | Rekap | logika bersama rekap, `rekap` | layar Rekap |
| S6 | Ganti password, APK debug | `gantipassword` | layar Ganti Password, ikon, build |

Gerbang tiap slice di sisi server: HTML web tetap 129/129 SAMA dan semua uji LULUS (§8.1).

## 4. K3 — Aktor dan peran → 05, 06, 21

### 4.1 Peran

[FAKTA] `app/auth.php:46-50`. Peran dibaca ulang dari DB di setiap permintaan, seperti `periksa_akun_aktif()` di `app/auth.php:190-203`.

| Nilai `user.Keterangan` | Peran | Bisa memakai mDonator |
|---|---|---|
| `admin` (huruf bebas) | admin | Ya; fiturnya sama dengan operator [KEPUTUSAN K11] |
| `Operator` (huruf bebas) | operator | Ya |
| lainnya, mis. `Nonaktif` | — | Tidak; token langsung ditolak (401) |

### 4.2 Matriks akses mobile

Semua aturan ditegakkan **server**. Klien hanya menyembunyikan aksi yang tidak berlaku.

| Kapabilitas | Operator | Admin | Ditegakkan di |
|---|:-:|:-:|---|
| Cek dan cari donatur | ✓ | ✓ | guard peran API |
| Input sumbangan (selalu `Note='y'`) | ✓ | ✓ | logika bersama donasi |
| Tambah donatur beserta sumbangan pertama | ✓ | ✓ | logika bersama donatur |
| Lihat Input Saya | ✓ milik sendiri | ✓ milik sendiri | filter `IdUser` = pengguna token |
| Ubah nominal | ✓ hanya milik sendiri, hari ini (K6) | ✓ milik sendiri, tanggal apa pun [ASUMSI] | `boleh_ubah_donasi()` `app/auth.php:82-91` |
| Lihat baris `Note='n'` di daftar | ✗ | ✓, dengan penanda `note_n` | `sql_note_daftar()` `app/auth.php:31-35` |
| Ubah `Note` | ✗ | ✗ di mobile | API tidak menerima field Note |
| Hapus donasi | ✗ | ✗ di mobile | aksi tidak ada (404) |
| Rekap saya dan semua operator | ✓ | ✓ | — |
| Ganti password sendiri | ✓ | ✓ | — |

Catatan baris "Ubah nominal" untuk admin: `boleh_ubah_donasi()` mengizinkan admin mengubah donasi siapa pun, tetapi layar Input Saya hanya menampilkan milik sendiri, sehingga di mobile admin praktis hanya mengubah miliknya.

### 4.3 Alur proses bisnis

**P1 Masuk**

- *Alur normal:* username dan password → `login` → token disimpan di secure storage → layar awal.
- *Gagal:*
  - kredensial salah → 401 dengan pesan web "Username dan Password anda salah!" (`app/halaman/proseslogin.php:29`);
  - akun bukan admin/operator → 401 dengan pesan yang sama, supaya keberadaan akun tidak terbuka;
  - setelah `LOGIN_MAX_ATTEMPTS` kali gagal → 429 dengan sisa menit. Penghitungnya dipakai bersama web (L16);
  - API mati (`APP_KEY` kosong) → 503;
  - tanpa jaringan → pesan, isian tetap.

**P2 Input sumbangan**

- *Alur normal:* ketik nomor → Cek (`donatur`) → info donatur, bintang, riwayat tahun ini, dan saran Jumlah → Jumlah terisi otomatis atau dipilih dari nominal cepat → Simpan (`tambahdonasi` dengan `Idempotency-Key`) → kartu hasil → kembali ke kolom nomor. Strip "Total input hari ini" diperbarui.
- *Gagal:*
  - nomor kosong atau tidak terdaftar → 422 per isian (`app/halaman/prosestambahdonasi.php:30-33`);
  - Jumlah kosong atau bukan angka → 422;
  - donatur sudah menyumbang hari ini (K5) atau nominal di atas `NOMINAL_KONFIRMASI` (K9) → 409 `perlu_konfirmasi` dengan `alasan` → dialog Ya/Tidak → Ya mengirim ulang dengan `konfirmasi=1`;
  - koneksi putus sesudah server menyimpan → kirim ulang dengan kunci yang sama mendapat jawaban pertama, tanpa baris baru;
  - token kedaluwarsa di tengah isian → layar Masuk, lalu kembali dengan isian utuh.

**P3 Tambah donatur**

- *Alur normal:* isi Nama, Alamat, No HP, Keterangan, dan Sumbangan Pertama. Setelah ≥ 2 huruf Nama, `caridonatur` menampilkan nama mirip sebagai peringatan; operator bisa memilih salah satunya, lalu pindah ke Input Sumbangan dengan nomor terisi. Simpan → kartu hasil dengan Nomor Register besar.
- *Gagal:*
  - isian wajib kosong atau terlalu panjang → 422 (`app/halaman/prosestambahdonatur.php:18-23`);
  - teks di luar latin1 (emoji) → 422 (L2);
  - keempat isian persis sama dengan donatur yang ada → 409 `donatur_sudah_ada` dengan nomor yang ada (`app/halaman/prosestambahdonatur.php:31,38-46`);
  - sumbangan pertama di atas batas K9 → 409 `perlu_konfirmasi`.

**P4 Input Saya dan ubah**

- *Alur normal:* daftar input saya pada satu tanggal (bawaan hari ini menurut server) beserta total dan jumlah transaksi → ketuk baris yang `boleh_ubah` → ubah Jumlah → simpan.
- *Gagal:*
  - bukan milik sendiri atau bukan hari ini → 403 dengan `PESAN_K6` (`app/auth.php:92`);
  - Jumlah baru di atas batas dan berubah → 409 `perlu_konfirmasi` (`app/halaman/prosesubahdonasi.php:26-35`);
  - baris sudah tidak ada → 404.

**P5 Rekap**

- *Alur normal:* pilih periode (Hari/Minggu/Bulan) dan cakupan (Saya/Semua), geser ke periode sebelum atau sesudahnya → ringkasan serta rincian per hari dan per operator.
- *Kosong:* periode tanpa data menampilkan state kosong, bukan galat.

**P6 Ganti password**

- *Alur normal:* lama, baru, ulang → token baru (token lama batal) → tetap masuk.
- *Gagal* (`app/halaman/prosesgantipassword.php:18-31`):
  - M1 belum dijalankan;
  - password lama salah (ikut menambah penghitung penguncian);
  - password baru < 8 karakter, ulangan tidak sama, atau sama dengan yang lama;
  - sedang terkunci → 429.

**P7 Pencabutan akses.** Admin men-Nonaktifkan akun atau password diganti di web → permintaan berikutnya dijawab 401 → layar Masuk. Tidak ada pencabutan per perangkat (§11).

## 5. K4 — Domain dan data → 04, 07

### 5.1 Glosarium

| Istilah | Makna |
|---|---|
| Donatur / Donator | Penyumbang terdaftar (tabel `donator`) |
| Nomor Register / Nomor Donator | `donator.Id`, nomor yang diketik operator (1–32767) |
| Sumbangan / Donasi | Satu catatan pemberian (tabel `donasi`) |
| Jumlah / Nominal | Rupiah bulat, tanpa desimal |
| Operator | Akun peran operator; `donasi.IdUser` = yang menginput |
| Note | Atribut internal `y`/`n`, khusus admin (K3). Dari mobile selalu `y`. |
| Bintang | Tingkat donatur 0–5 dari total `Note='y'` **tahun kalender lalu** ÷ 12 (§5.4) |
| Saran Jumlah | Rata-rata sumbangan donatur dalam 12 bulan terakhir, bila tepat salah satu Nominal Umum (Fase 11) |
| Nominal Umum | `NOMINAL_UMUM` (`app/web.php:144`): 50.000, 100.000, 150.000, 200.000, 250.000, 300.000, 350.000, 500.000, 1.000.000, 2.000.000 |
| Konfirmasi K5 | Donatur yang sama sudah tercatat menyumbang pada tanggal itu |
| Konfirmasi K9 | Nominal di atas `NOMINAL_KONFIRMASI` (bawaan Rp 5.000.000) |
| Input Saya | Sumbangan yang diinput pengguna token pada satu tanggal |
| Transaksi | Jumlah baris donasi `Note='y'` (`COUNT(*)`) |
| Donatur (dalam rekap) | Jumlah donatur berbeda (`COUNT(DISTINCT IdDonator)`); jangan disamakan dengan transaksi (L3) |
| User lama | Donasi dengan `IdUser` yang tidak ada lagi di tabel `user`, dikumpulkan sebagai satu baris "User lama (sudah dihapus)" |
| Hari ini | Tanggal server dalam `APP_TIMEZONE` (Asia/Makassar, WITA), bukan jam HP |
| Minggu (pekan) | Senin–Minggu (K14). "Minggu" juga nama hari terakhirnya; label UI "Minggu ini" berarti pekan. |

### 5.2 Skema fisik

Pemilik skema adalah server: `database/SCHEMA.sql`, ditambah M1. Paket klien **tidak** memiliki skema; `07` paket frontend cukup stub yang menunjuk kontrak. Ringkasan di bawah adalah konteks untuk batas validasi. [FAKTA]

| Tabel.kolom | Tipe | Catatan untuk mobile |
|---|---|---|
| `donator.Id` | smallint, AI, PK | 1–32767; maksimum sekarang 7.758 |
| `donator.Nama` | varchar(100) NOT NULL | wajib; maks 100 karakter |
| `donator.Alamat` | varchar(255) NOT NULL | wajib; maks 255 |
| `donator.NoHP` | varchar(20) NOT NULL | boleh kosong (string kosong); maks 20; bentuk umum `08xxxxxxxxxx` |
| `donator.Keterangan` | varchar(255) NOT NULL | boleh kosong; maks 255 |
| `donasi.Id` | int, AI, PK | id sumbangan untuk Ubah |
| `donasi.IdUser` | tinyint | diisi server dari token, tidak pernah dari klien |
| `donasi.IdDonator` | smallint | tanpa foreign key; ada 178 donasi "yatim" (donaturnya terhapus, K7) |
| `donasi.Tanggal` / `Waktu` | date / time | dicap server; tanpa zona waktu (L4 di §12) |
| `donasi.Jumlah` | int | 1–2.147.483.647 (`input_nominal`, `app/web.php:66-69`) |
| `donasi.Note` | varchar(1), default `y` | tidak pernah dikirim ke operator |
| `user.Id/Username/Password/Keterangan` | tinyint / varchar(50) / varchar(255) setelah M1 / varchar(100) | password hash; plaintext di produksi sampai M1 dideploy |

Semua tabel memakai charset **latin1**, sedangkan koneksi memakai utf8mb4 (L2). Tidak ada foreign key.

### 5.3 Entitas payload klien

Bentuk final ditulis di `kontrak/openapi.yaml`; bagian ini hanya bahan.

| Entitas | Atribut kunci |
|---|---|
| Pengguna | id, username, peran |
| Sesi | token, kedaluwarsa |
| Konfigurasi | versi_api, hari_ini, zona_waktu, nominal_umum[], nominal_konfirmasi |
| DonaturRingkas | id, nama, alamat |
| DonaturDetail | DonaturRingkas + no_hp, keterangan, bintang, riwayat[], total_tahun_ini, saran_jumlah? |
| Sumbangan | id, id_donatur, nama_donatur?, tanggal, waktu, jumlah, boleh_ubah, note_n? (hanya untuk admin) |
| Rekap | periode, dari, sampai, cakupan, total, transaksi, donatur, per_hari[], per_operator[] |
| Galat | kode, pesan, rincian?, alasan?, sisa_detik?, id_donatur? |

### 5.4 Aturan data yang wajib dipertahankan

[FAKTA]; di-port ke logika bersama, bukan ditulis ulang di klien.

- **Bintang** (`app/halaman/search2.php:17-35`): rataan = SUM(Jumlah) `Note='y'` tahun kalender lalu ÷ 12.

  | Rataan | Bintang |
  |---|---|
  | < 50.000 | 0 |
  | < 150.000 | 1 |
  | < 250.000 | 2 |
  | < 600.000 | 3 |
  | < 1.250.000 | 4 |
  | ≥ 1.250.000 | 5 |

  Warna tombolnya di web: info, info, success, primary, warning, danger.
- **Riwayat** di Cek: tahun kalender berjalan, memakai `sql_note_daftar()`, urut Tanggal (`app/halaman/search2.php:58`).
- **Saran Jumlah** (`app/web.php:151-155`): `ROUND(AVG(Jumlah))`, `Note='y'`, `Tanggal` ≥ hari ini − 1 tahun; hanya bila hasilnya anggota `NOMINAL_UMUM`.
- **K5** (`app/web.php:130-141`): `COUNT(*)` donasi donatur itu pada tanggal itu, **tanpa filter Note dan tanpa filter operator** (L8).
- **K9:** `Jumlah > nominal_batas()`. Untuk ubah, hanya bila nominal berubah (`app/halaman/prosesubahdonasi.php:27`). Untuk tambah donatur, hanya bila donaturnya baru.
- **Duplikat donatur:** keempat isian Nama, Alamat, NoHP, dan Keterangan persis sama (`app/halaman/prosestambahdonatur.php:31`).
- **Agregat** (rekap, total, strip hari ini) selalu `Note='y'` untuk semua peran. **Daftar** per sumbangan memakai `sql_note_daftar()`.
- **Strip "Total input hari ini"** (`app/views/form-donasi.php:85-103`): total dan jumlah input saya hari ini (`Note='y'`), serta 6 input terakhir (nomor dan jumlah, urut Waktu menurun).

### 5.5 Data sensitif

- **PII donatur** (Nama, Alamat, NoHP) hanya ditampilkan selama layar terbuka dan tidak disimpan di perangkat. [ASUMSI A6]
- Token dan alamat server disimpan di `flutter_secure_storage`. Password tidak pernah disimpan. [RANCANGAN]
- Log klien dan jejak audit server tidak boleh memuat password, token, atau PII donatur. Audit hanya mencatat id dan nilai sumbangan seperti di web (`app/audit.php`). [FAKTA, RANCANGAN]

### 5.6 Statistik data

[FAKTA] DB lokal = dump produksi 8 Okt 2026; jendela 12 bulan s.d. 8 Okt 2026.

| Ukuran | Nilai |
|---|---|
| Donatur terdaftar / aktif menyumbang | 7.723 / 897 |
| Donatur aktif dengan No HP valid | 104 (12%) |
| Donatur baru (sumbangan pertama dalam 12 bulan) | 105 (≈ 2 per pekan) |
| Transaksi `Note='y'` / `Note='n'` | 4.692 / 669 (12,5% baris adalah Note n) |
| Rata-rata nominal | Rp 204.051 |
| Total per bulan penuh | Rp 29,7–151 juta |
| Hari dengan input | 137; rata-rata 34,2 transaksi per hari aktif; maksimum 192 |
| Maksimum input satu operator dalam sehari | 132 (rata-rata 24,4) |
| Hari ramai (semua Note) | Minggu 3.491 · Kamis 1.049 · Jumat 750 · Sabtu 68 · Selasa 3 |
| Jam ramai (WITA) | 08–11 (≈ 4.000 baris) dan 19–23 (≈ 1.050 baris); jam lain hampir kosong |
| Nominal tersering | 100.000 (1.522) · 50.000 (1.054) · 200.000 (575) · 150.000 (303) · 300.000 (246) · **400.000 (153)** · 500.000 (149) · 250.000 (136) · 1.000.000 (67) · **600.000 (63)** |
| Porsi nominal yang termasuk `NOMINAL_UMUM` | 87,1% |
| Di atas Rp 5 juta (K9) | 3 transaksi; maksimum Rp 25,7 juta |
| Nominal janggal | minimum Rp 1; 3 transaksi bukan kelipatan Rp 1.000 |
| Kasus K5 (donatur dan tanggal sama, > 1 transaksi) | 81 |
| Donasi milik user terhapus | 20 |
| Panjang terpanjang Nama / Alamat / NoHP / Keterangan | 47 / 46 / 15 / 42 karakter; tidak ada karakter non-ASCII |

## 6. K5 — Stack dan arsitektur → 08, 09, 12

### 6.1 Stack

| Lapisan | Teknologi dan versi | Status |
|---|---|---|
| Klien | Flutter 3.47.5 (stable), Dart 3.13.4, DevTools 2.60.0 | [FAKTA] terpasang |
| Android | SDK platforms android-28 s.d. android-36, build-tools 28.0.3 s.d. 36.0.0, NDK, cmdline-tools, emulator; AVD `Pixel_5-Android_13`; JDK 17.0.18 | [FAKTA] terpasang |
| Paket Dart | `http`, `flutter_secure_storage`, `intl`, `flutter_localizations` (SDK). State memakai `ChangeNotifier` bawaan. | [RANCANGAN] |
| Server | PHP 8.4.23 (lokal) / PHP 8.x (produksi); mysqli prosedural; tanpa framework dan tanpa Composer | [FAKTA] |
| DB | MySQL 8.4 (lokal, `ONLY_FULL_GROUP_BY` dan `STRICT_TRANS_TABLES` aktif) / MariaDB 10.11 (produksi) | [FAKTA] |
| Web server | Apache/LiteSpeed (`public/.htaccess`), Nginx (`deploy/nginx.conf`), `php -S` (lokal) | [FAKTA] |
| Alat kontrak | Node 22.19.0 dan npx 11.7.0 (untuk Prism dan openapi-generator-cli); Python 3.14.8 (schemathesis belum terpasang) | [FAKTA]; pemakaian [TERBUKA T5, T6] |

### 6.2 Teknologi terlarang

| Terlarang | Alasan |
|---|---|
| Framework PHP, Composer, pustaka server baru | Batasan pemilik (`UPDATE_PLAN.md` §1) [KEPUTUSAN] |
| Tabel atau kolom DB baru | Skema hanya boleh berubah lewat migrasi terencana (sekarang hanya M1) [KEPUTUSAN] |
| WebView yang membungkus halaman web | K12 memilih aplikasi native [KEPUTUSAN] |
| Paket state management (bloc, riverpod, getx, provider) | Lima sampai tujuh layar tidak membutuhkannya [ASUMSI] |
| SDK telemetri, analytics, atau crash reporting pihak ketiga (Firebase dan sejenisnya) | Data donatur tidak boleh keluar dari server yayasan [ASUMSI A3] |
| `dio` dan `built_value` (bawaan generator `dart-dio`) | Dependensi berat; generator `dart` berbasis `http` cukup [TERBUKA T5] |
| `http://` di build rilis | Token dan PII lewat jaringan seluler [RANCANGAN] |
| Pustaka komponen UI di luar Material bawaan Flutter | Mencegah gaya campur aduk [ASUMSI A17] |

### 6.3 Arsitektur

```text
mDonator (Android)                                        Server Donatur (PHP)
lib/layar/*  ──►  lib/state/*  ──►  lib/api/klien_api  ══HTTPS══►  public/index.php
(widget)          (ChangeNotifier)  (http + token,                  └─ app/rute.php → app/halaman/api.php
                                     Idempotency-Key)                  └─ app/api/<aksi>.php   (validasi bentuk JSON)
                                                                          └─ app/donasi.php     (logika bersama web + API)
                                                                             └─ app/db.php, app/auth.php, app/audit.php
```

**Keputusan arsitektural kunci**

| Keputusan | Alasan | Status |
|---|---|---|
| Klien native Flutter; server tetap PHP native | Pilihan pemilik; server sudah teruji di MySQL/MariaDB, Apache, dan Nginx | [KEPUTUSAN K12] |
| API di aplikasi yang sama lewat `{APP_URL}/api?aksi=<nama>` | Router hanya menerima nama `[a-z0-9]+` satu segmen (L9), dan alamat ini tidak butuh aturan web server baru | [RANCANGAN] |
| Logika bisnis dipindah ke `app/donasi.php` dan dipakai web maupun API | Aturan K5, K6, K9, Note, dan WITA tidak boleh punya dua salinan | [RANCANGAN] |
| Token HMAC tanpa sesi dan tanpa tabel | Skema tidak boleh bertambah; tanpa cookie berarti tanpa CSRF | [TERBUKA T2] |
| "Hari ini" diambil dari server | Jam HP bisa salah; data dicap jam server | [RANCANGAN] |
| Tanpa mode offline | Waktu dicap server; data uang tidak boleh antre di HP | [KEPUTUSAN, §10] |
| Kirim ulang aman lewat `Idempotency-Key` | Jaringan seluler; data uang tidak boleh ganda | [RANCANGAN] |
| Alamat server bisa diatur | Aplikasi web harus portabel (root domain atau subfolder) | [RANCANGAN] |

### 6.4 Struktur folder

**Klien** [ASUMSI, mengikuti `UPDATE_PLAN.md` Fase 12]

```text
mDonator/
├── DOSIR_MDONATOR.md        dosir ini (bahan, bukan bagian paket)
├── CLAUDE.md, INDEX.md      keluaran vcbd
├── docs/                    00–27 + _MANIFEST.json (keluaran vcbd)
├── pubspec.yaml
├── lib/
│   ├── main.dart            titik masuk, MaterialApp, lokal id_ID
│   ├── tema.dart            token warna/tipografi dari docs/26
│   ├── api/                 klien_api.dart, galat_api.dart, gen/ (bila codegen, T5)
│   ├── state/               sesi.dart (token, pengguna, konfigurasi), satu ChangeNotifier per layar bila perlu
│   ├── layar/               masuk, input_sumbangan, tambah_donatur, input_saya, ubah_sumbangan, rekap, ganti_password, pengaturan
│   └── util/                rupiah.dart, tanggal.dart
├── test/                    unit dan widget
├── integration_test/        alur penuh terhadap server lokal
└── android/                 applicationId (T10), network_security_config khusus debug
```

**Penamaan klien** [ASUMSI]

- Berkas Dart memakai `snake_case`; kelas memakai `UpperCamelCase`; anggota memakai `lowerCamelCase`.
- Kata domain memakai bahasa Indonesia, sama dengan server: `donatur`, `sumbangan`, `jumlah`, `rekap`.
- Nama field JSON mengikuti kontrak (T4).

**Server** [RANCANGAN]

- Berkas baru: `app/donasi.php`, `app/token.php`, `app/halaman/api.php`, `app/api/<aksi>.php`, `tests/api.php`.
- Nama aksi hanya huruf kecil.
- Halaman web yang sudah ada tetap di tempatnya, dan HTML-nya harus sama persis.

## 7. K6 — Lingkungan dan operasi → 10, 11, 15

### 7.1 Setup lokal

[FAKTA] kecuali disebut.

- Server dev: `php -S localhost:3000 -t public public/index.php` dari root repo. Emulator Android mencapai host lewat `http://10.0.2.2:3000`. HP fisik di LAN butuh server yang mendengar `0.0.0.0` dan alamat IP mesin.
- DB lokal `kapuhmad_donatur` (salinan produksi berisi PII). `.env` menunjuk ke DB ini.
- Akun uji `uji_admin` dan `uji_operator` dibuat oleh `php tests/akun-uji.php`; password-nya di `tests/.akun-uji` (di-ignore git).
- Kunci `.env` baru: `APP_KEY` dan `API_TOKEN_HOURS`. [RANCANGAN]
- `mDonator/` dan `kontrak/` tidak ikut salinan rilis server (`tests/instalasi.php`) dan dilewati lint smoke. [RANCANGAN]

### 7.2 Perintah

Tanda † berarti perintah belum ada dan baru lahir di Fase 12.

| Tujuan | Perintah |
|---|---|
| Server dev | `php -S localhost:3000 -t public public/index.php` |
| Cek instalasi server | `php bin/cek.php` |
| Akun uji lokal | `php tests/akun-uji.php` |
| Uji API † | `php tests/api.php` → harus mencetak LULUS |
| Regresi web | `php tests/smoke.php` · `php tests/security.php` · `php tests/donasi.php` · `php tests/rekap.php` · `php tests/password.php` · `php tests/pengguna.php` |
| HTML web tidak berubah | `php tests/snapshot.php <label>` lalu `php tests/compare.php <a> <b>` → 129/129 SAMA |
| Sidik data | `php bin/sidik-data.php > tests/_out/sidik-<label>.txt` lalu `diff` |
| MariaDB | `php tests/mariadb.php --dump=<dump produksi>` |
| Instalasi (Apache, Nginx, HTTPS) | `DB_ROOT_PASS=... php tests/instalasi.php` |
| Dependensi klien † | `cd mDonator && flutter pub get` |
| Analisis statik † | `flutter analyze` → tanpa isu |
| Uji klien † | `flutter test` |
| Uji integrasi † | `flutter test integration_test -d emulator-5554 --dart-define=SERVER_URL=http://10.0.2.2:3000` |
| Emulator | `~/Library/Android/sdk/emulator/emulator -avd Pixel_5-Android_13` |
| Jalankan | `flutter run -d emulator-5554 --dart-define=SERVER_URL=http://10.0.2.2:3000` |
| APK debug † | `flutter build apk --debug --dart-define=SERVER_URL=<alamat>` |
| Mock API † | `npx @stoplight/prism-cli mock kontrak/openapi.yaml -p 4010` (emulator: `http://10.0.2.2:4010`) |
| Codegen klien † [TERBUKA T5] | `npx @openapitools/openapi-generator-cli generate -i kontrak/openapi.yaml -g dart -o mDonator/lib/api/gen` |
| Validasi kontrak † | `bash kontrak/scripts/validate-kontrak.sh --backend . --frontend mDonator` (bergantung T1) |

### 7.3 Observability

- **Server** [FAKTA, RANCANGAN]
  - `storage/logs/php-error.log` untuk galat; galat API dijawab 500 JSON tanpa jejak tumpukan.
  - `storage/logs/audit.log` mendapat satu baris JSON per tambah atau ubah, dengan tambahan `"via":"mobile"`.
  - Penguncian login disimpan di `storage/cache/login-*.json`; kunci kirim ulang di `storage/cache/`.
- **Klien** [ASUMSI A3]
  - Tidak ada telemetri jarak jauh.
  - `debugPrint` hanya di build debug, tanpa token dan tanpa PII.
  - Layar Pengaturan menampilkan versi aplikasi, `versi_api` server, dan alamat server untuk diagnosa.

## 8. K7 — Kualitas dan keamanan → 13, 14, 21, 23, 24

### 8.1 Strategi uji

**Server** (`UPDATE_PLAN.md` Fase 12 bagian Uji) [RANCANGAN]

- `tests/api.php` baru, dengan pola `security.php`:
  - menulis baris bertanda `UJI-API …` lalu menghapusnya;
  - menolak DB non-lokal;
  - sidik data harus sama di awal dan akhir.
- Cakupannya:
  - token: tidak ada, rusak, tanda tangan diubah, kedaluwarsa, `APP_KEY` lain, akun Nonaktif, password diganti, `APP_KEY` kosong;
  - tanpa sesi: tidak ada `Set-Cookie` dan tidak ada file sesi baru; cookie `DONATUR_SID` tidak berlaku; tidak ada header CORS;
  - paritas dengan web: `donatur` sama dengan `search2`; `rekap` cocok dengan query acuan, termasuk pekan yang melintasi bulan dan tahun, serta user lama;
  - aturan K5, K6, K9, Note, dan WITA; kirim ulang aman; duplikat donatur; `aksi=hapusdonasi` → 404;
  - masukan jahat: SQLi, `<script>`, emoji (L2), isian terlalu panjang;
  - audit `via` mobile tanpa rahasia.
- `tests/instalasi.php`: header `Authorization` harus sampai ke PHP di semua skenario (php -S, Apache + PHP-FPM, subfolder, `htaccess-root`, Nginx, HTTPS).
- `tests/mariadb.php` ikut menjalankan `tests/api.php`.
- Regresi: HTML web 129/129 SAMA, semua rangkaian lama LULUS, sidik data identik.

**Klien** [RANCANGAN, ASUMSI]

- `flutter analyze` bersih.
- Unit: format dan parse rupiah, tanggal Indonesia, pemetaan galat API (401/403/404/409/422/429/503/500/timeout) dengan `MockClient` dari `package:http/testing.dart`, dan kunci kirim ulang yang sama dipakai saat retry.
- Widget: alur Masuk; Input Sumbangan (saran hanya mengisi Jumlah yang kosong atau yang masih berisi saran sebelumnya, sesuai aturan Fase 11; dialog K5/K9; strip hari ini); Tambah Donatur (nama mirip, 409 duplikat); Input Saya (baris tanpa `boleh_ubah` tidak bisa diketuk); Rekap (periode × cakupan, state kosong).
- Integrasi (opsional per slice): terhadap server lokal memakai `uji_operator` dan `uji_admin`; baris uji dihapus kembali [ASUMSI A13].

### 8.2 Penanganan galat

Bentuk JSON-nya milik kontrak. Bagian ini mendefinisikan perilaku klien per kode. [RANCANGAN]

| HTTP | `kode` | Perilaku klien |
|---|---|---|
| 200 | — | Tampilkan hasil (state sukses) |
| 401 | `token_tidak_sah`, `login_gagal` | Hapus token, buka Masuk. Isian layar asal disimpan di memori dan dipulihkan setelah masuk lagi. Saat login: tampilkan `pesan`. |
| 403 | `tidak_berhak` | Tampilkan `pesan` (untuk ubah: `PESAN_K6`) |
| 404 | `tidak_ada` | Tampilkan `pesan`, mis. "Data Donator nomor X tidak ditemukan!" |
| 409 | `perlu_konfirmasi` | Dialog berisi daftar `alasan` beserta tombol **Ya, simpan** dan **Tidak**. Ya mengirim ulang isian yang sama dengan `konfirmasi=1` dan kunci kirim ulang yang **baru**. |
| 409 | `donatur_sudah_ada` | Tampilkan nomor yang ada, dengan aksi "Input sumbangan untuk nomor ini" |
| 422 | `tidak_valid` | Pesan di bawah tiap isian dari `rincian` |
| 429 | `login_terkunci` | "Terlalu banyak percobaan gagal. Coba lagi dalam N menit." (dari `sisa_detik`) |
| 503 | `api_mati` | "Layanan mobile belum diaktifkan di server." |
| 500 | `galat_server` | Pesan umum dan tombol Coba lagi; isian tetap |
| — | timeout, tanpa jaringan | Isian tetap; tombol Kirim ulang memakai **kunci kirim ulang yang sama** |

- Pesan ditulis dalam bahasa Indonesia. Pesan galat web dipakai apa adanya bila sudah ada. [ASUMSI]
- Server mengirim pesan teks polos, tanpa HTML (L13). Klien tidak pernah merender HTML dari server.

### 8.3 Aturan keamanan

[RANCANGAN] kecuali disebut.

- **Token**
  - HMAC-SHA256 berisi id user, waktu terbit, dan kedaluwarsa (`API_TOKEN_HOURS`, bawaan 16 jam).
  - Kuncinya `APP_KEY` digabung nilai `user.Password`, sehingga ganti password membatalkan semua token. Lihat juga L17.
  - Setiap permintaan memeriksa tanda tangan dan kedaluwarsa, lalu membaca ulang peran dari DB.
- **Pengiriman token:** header `Authorization: Bearer`. API mengabaikan cookie, sehingga tidak ada CSRF. Tidak ada CORS.
- **Batas percobaan login** dipakai bersama web: kunci = IP dan username, `LOGIN_MAX_ATTEMPTS` dan `LOGIN_LOCK_MINUTES` (`app/auth.php:220-256`). [FAKTA]
- **Validasi** memakai `input_bulat`, `input_nominal`, dan `input_teks` yang sama dengan web, ditambah validasi latin1 untuk teks (L2). SQL selalu lewat parameter `db_query()`. [FAKTA, RANCANGAN]
- **Penegakan di server:**
  - `IdUser` dan `Note` tidak pernah diterima dari klien;
  - K6 lewat `boleh_ubah_donasi()`;
  - visibilitas Note lewat `sql_note_daftar()`.
- **Transport:** build rilis hanya `https://`. `network_security_config` yang mengizinkan cleartext hanya untuk build debug.
- **Penyimpanan di klien:** token, alamat server, dan username terakhir disimpan di secure storage. Password tidak disimpan. PII donatur tidak disimpan (A6).
- **Rahasia:** `APP_KEY` hanya di `.env`. Kunci tanda tangan APK (`*.jks`, `*.keystore`, `key.properties`) tidak pernah di-commit.
- **Pencabutan:** set Nonaktif atau ganti password. Rotasi `APP_KEY` mengeluarkan semua pengguna mobile.

### 8.4 Kriteria terima per fitur

Bahan untuk 23. Blok verifikasi mengikuti §7.2.

| Fitur | Kriteria (Given/When/Then ringkas) | Verifikasi |
|---|---|---|
| F1 | Kredensial `uji_operator` benar → token dan peran `operator`. Salah 5× → 429. Akun di-Nonaktifkan → permintaan berikutnya 401. `APP_KEY` kosong → 503. Klien menyimpan token dan membuka layar awal; 401 membuka Masuk. | `php tests/api.php` LULUS; `flutter test` (masuk) |
| F2 | Alamat dengan subfolder (`http://host/donatur/`) berfungsi. Build rilis menolak `http://`. | uji widget pengaturan; uji `tests/instalasi.php` skenario subfolder |
| F3 | `donatur` untuk nomor fixture sama persis dengan isi fragmen `search2` (nama, alamat, bintang, riwayat, saran). Operator tidak menerima baris Note n. `caridonatur` mengembalikan ≤ 20 hasil. | `php tests/api.php` |
| F4 | Simpan → satu baris `Note='y'`, `IdUser` = pengguna token, Tanggal/Waktu WITA. Donatur sama di hari yang sama → 409 lalu tersimpan dengan `konfirmasi=1`. Kunci kirim ulang yang sama dua kali → satu baris. Strip hari ini bertambah. | `php tests/api.php`; `flutter test` (input) |
| F5 | Donatur baru dan sumbangan pertama tersimpan. Duplikat persis → 409 dengan nomor yang ada. Emoji di Nama → 422, bukan 500. | `php tests/api.php` |
| F6 | Daftar hari ini hanya milik sendiri; total memakai `Note='y'`. Ubah milik orang lain atau kemarin → 403. Tidak ada aksi hapus. | `php tests/api.php`; `flutter test` (input saya) |
| F7 | Untuk 3 tanggal acuan (termasuk pekan lintas bulan dan lintas tahun), angka `rekap` sama dengan query acuan dan dengan halaman `rekapalloperator`/`rekapbulanan`. | `php tests/api.php` (bagian rekap) |
| F8 | Ganti sukses → token lama 401, token baru 200. Password lama salah menambah penghitung penguncian. | `php tests/api.php`; `php tests/password.php` tetap LULUS |
| Semua | HTML web 129/129 SAMA; smoke, security, donasi, rekap, password, dan pengguna LULUS; sidik data identik; MariaDB LULUS; tidak ada perubahan skema. | §7.2 |

### 8.5 Definition of Done universal

[ASUMSI, mengikuti kebiasaan proyek]

Kriteria terima terpenuhi · `flutter analyze` bersih dan `flutter test` hijau · semua uji server LULUS · HTML web 129/129 SAMA · sidik data identik · tidak ada perubahan skema · tidak ada entri baru di `php-error.log` · `UPDATE_PLAN.md` diperbarui dengan bagian "Hasil uji" untuk fase atau slice terkait.

## 9. K8 — Kebijakan perubahan dan risiko → 18, 20, 22, 25

- **Git** [FAKTA]
  - Repo lokal saja (tanpa remote). Pekerjaan di cabang `pembaruan`; `main` berisi baseline produksi.
  - Commit hanya bila pemilik meminta. Gaya pesan: `Fase N: <ringkasan>`.
  - Akhiri pesan commit dengan baris atribusi yang ditetapkan lingkungan kerja.
- **Operasi irreversibel yang butuh gerbang manusia** [KEPUTUSAN, RANCANGAN]
  - perubahan skema DB (terlarang, kecuali migrasi terencana);
  - apa pun yang menyentuh server atau DB produksi (deploy ditunda);
  - menulis ke DB selain DB lokal;
  - mengubah format token atau mengganti `APP_KEY` (semua pengguna keluar);
  - perubahan kontrak yang breaking (naik versi mayor);
  - menambah dependensi Dart atau PHP;
  - mengubah `applicationId` setelah APK dibagikan;
  - membagikan atau menerbitkan APK.
- **Guardrail agen** [ASUMSI, berdasarkan aturan proyek]
  - jangan mengubah markup atau CSS halaman web;
  - jangan menyalin aturan bisnis ke Dart; klien hanya menampilkan hasil server;
  - jangan menerima `IdUser`/`Note` dari klien;
  - jangan menonaktifkan uji untuk menghijaukan;
  - jangan menyimpan PII di perangkat;
  - jangan menambah endpoint di luar kontrak.
- **Perbaikan bug:** reproduksi → akar masalah → perbaikan minimal → uji regresi. Jangan melebihi scope bug, dan jangan refactor luas tanpa izin. [ASUMSI]
- **Rilis:** tidak ada langkah rilis di Fase 12 selain APK debug lokal. Dokumen 25 cukup stub: "distribusi ditunda". [KEPUTUSAN]

## 10. K9 — Antarmuka (paket klien) → 26

**Jangkar** [FAKTA, *brownfield*: diekstrak dari kode]

- identitas visual web: spanduk `public/img/header.jpg` (logo yayasan, hijau–kuning, judul merah);
- `public/css/style.css`;
- Bootstrap 3.3.7 (`public/css/bootstrap.min.css`).

K16 memutuskan tata letak HP sendiri dengan warna dan logo web.

### 10.1 Token

| Kategori | Nama | Nilai | Sumber |
|---|---|---|---|
| Warna | `primer` | `#046500` | sampel spanduk (hijau); setara `.marquee` `#006600` |
| Warna | `primerGelap` | `#003300` | [ASUMSI] untuk status bar |
| Warna | `aksen` | `#FFFF33` | sampel spanduk (kuning); teks marquee `yellow` |
| Warna | `judulMerah` | `#E00000` | sampel teks judul spanduk [ASUMSI, hasil sampling] |
| Warna | `navbar` | `#222222` | `.navbar-inverse` Bootstrap |
| Warna | `teks` | `#333333` | warna teks body Bootstrap 3 |
| Warna | `teksLemah` | `#777777` | `.text-muted` Bootstrap 3 |
| Warna | `latar` | `#FFFFFF` | `.wrap`, `.content` |
| Warna | `garis` | `#DDDDDD` | border tabel Bootstrap 3 |
| Warna | `aksi` | `#337AB7` | `.btn-primary` |
| Warna | `sukses` / `info` / `peringatan` / `bahaya` | `#5CB85C` / `#5BC0DE` / `#F0AD4E` / `#D9534F` | Bootstrap 3; latar badge |
| Warna | `teksSukses` / `teksInfo` / `teksPeringatan` / `teksBahaya` | `#3C763D` / `#31708F` / `#8A6D3B` / `#A94442` | warna teks alert Bootstrap 3 (lulus AA di atas putih) |
| Warna | bintang 0/1/2/3/4/5 | `info`, `info`, `sukses`, `aksi`, `peringatan`, `bahaya` | `app/halaman/search2.php:23-34` |
| Huruf | keluarga | Roboto (bawaan Android) | web memakai Arial/Segoe UI, yang tidak ada di Android [ASUMSI A4] |
| Huruf | skala (sp/tinggi baris) | label 14/20 · isi 16/24 · judul 20/28 · nominal 28/36 · Nomor Register hasil 32/40 | [ASUMSI] |
| Jarak | skala | 4 · 8 · 12 · 16 · 24 dp | [ASUMSI] |
| Bentuk | radius | 8 dp (kartu, tombol, isian) | [ASUMSI] |
| Bentuk | elevasi | 0 (isian) · 1 (kartu) | [ASUMSI] |
| Sentuh | target minimum | 48 × 48 dp | [ASUMSI] |

Kontras:

- Putih di atas `primer` ≈ 8:1 dan teks `teks` di atas putih ≈ 12,6:1; keduanya lulus AA.
- Warna semantik Bootstrap (`sukses`, `info`, `peringatan`) **tidak** dipakai untuk teks di atas putih. Teks memakai varian `teks*`.

### 10.2 Halaman → pola

[ASUMSI; layar awal TERBUKA T7]

| Halaman | Pola | Navigasi |
|---|---|---|
| Masuk | autentikasi | — |
| Input Sumbangan | formulir; strip hari ini di atas | tab 1 (layar awal) |
| Tambah Donatur | formulir | tab 2 |
| Input Saya | daftar + filter tanggal | tab 3 |
| Ubah Sumbangan | formulir (lembar bawah) | dari Input Saya |
| Rekap | dasbor (segmen Hari/Minggu/Bulan dan Saya/Semua, panah periode) | tab 4 |
| Ganti Password, Pengaturan, Keluar | formulir / aksi | menu ⋮ di app bar |

Navigasi utama berupa bottom navigation dengan 4 tab dan ikon Material Icons saja. Tidak ada aksi destruktif di mobile. Keluar meminta konfirmasi bila ada isian yang belum disimpan.

**Target perangkat:** ponsel Android, mobile-first, potret. Wajib layak di lebar 360 dp dan pada skala huruf sistem hingga 1,3× tanpa luapan. Tablet tidak menjadi target. [ASUMSI]

### 10.3 Empat state wajib

| Layar | Kosong | Memuat | Gagal | Sukses |
|---|---|---|---|---|
| Input Sumbangan (Cek) | "Ketik nomor donatur lalu tekan Cek" | indikator di tombol Cek | pesan 404/galat di bawah isian | kartu donatur |
| Input Sumbangan (Simpan) | — | tombol Simpan nonaktif dan berputar | pesan dan isian tetap | kartu hasil, lalu isian dikosongkan |
| Tambah Donatur | formulir kosong | tombol berputar | pesan per isian | kartu Nomor Register |
| Input Saya | "Belum ada input pada tanggal ini" | kerangka daftar | pesan dan Coba lagi | daftar dan total |
| Rekap | "Tidak ada sumbangan pada periode ini" | kerangka kartu | pesan dan Coba lagi | ringkasan dan rincian |

### 10.4 Mikroteks

[ASUMSI A2, A5]

- Bahasa Indonesia, nada formal-netral.
- Kata kerja tombol tetap: **Cek**, **Simpan**, **Batal**, **Ya, simpan**, **Tidak**, **Masuk**, **Keluar**, **Coba lagi**.
- Label isian mengikuti web: Nomor Donator, Sumbangan, Nama Donator, Alamat, Nomor Handphone, Keterangan, Sumbangan Pertama, Password Lama, Password Baru, Ulangi Password Baru.
- Rupiah ditulis "Rp 100.000" (`intl` id_ID, tanpa desimal). Web menulis "Rp. 100.000,-".
- Tanggal ditulis "Minggu, 12/10/2026" (d/m/Y dengan nama hari bahasa Indonesia, sama dengan `hariku()`). Jam ditulis "08:15 WITA".

**Aksesibilitas:** kontras AA dari tabel token, setiap isian berlabel, fokus terlihat, dan label semantik (`Semantics`) untuk nominal dan bintang.

**Larangan UI:**

- nilai di luar tabel token;
- pustaka UI baru;
- gradien (navbar web memakai gradien, tetapi aplikasi tidak);
- emoji;
- teks placeholder yang tertinggal;
- ikon di luar Material Icons;
- animasi dekoratif;
- WebView.

**Ikon aplikasi:** logo yayasan hanya ada di dalam `header.jpg` (1000×125 px, logo ±110 px), terlalu kecil untuk ikon peluncur [TERBUKA T9].

## 11. K10 — Kontrak backend ↔ frontend → 27, kontrak

> **Sudah ditulis:** kontrak lengkap ada di [`API_CONTRACT.md`](API_CONTRACT.md) (versi 0.1.0, 10 Okt 2026), atas permintaan pemilik. Kontrak itu memakai rekomendasi T2 dan T4. Untuk alamat, aksi, payload, dan kode galat, `API_CONTRACT.md` menang atas tabel di bagian ini; tabel di bawah tinggal catatan asal-usul. Bila VCBD mode split membuat `openapi.yaml`, berkas itu diturunkan dari `API_CONTRACT.md` (lihat §1 kontrak).

| Butir | Isi | Status |
|---|---|---|
| Tata letak | Kontrak Markdown di `mDonator/API_CONTRACT.md`; klien di `mDonator/`; backend = root repo | [TERBUKA T1] untuk tata letak paket VCBD |
| Gaya | REST-ish JSON di `{APP_URL}/api?aksi=<nama>`, bukan `/api/v1/...` (router satu segmen, L9) | [RANCANGAN] |
| Versi | SemVer di `info.version`, mulai 0.1.0. Tambahan opsional = minor; breaking = mayor dengan gerbang manusia. Server mengembalikan `versi_api` di `konfigurasi`; klien menolak bila versi mayornya berbeda ("Perbarui aplikasi") [ASUMSI A18]. | [ASUMSI] |
| Auth | `components.securitySchemes`: bearer. Semua aksi kecuali `login` wajib token. Penegakan peran milik backend. | [RANCANGAN] |
| Amplop sukses | `{"ok": true, "data": …}` | [RANCANGAN] (berbeda dari default VCBD `{"error":{…}}`; dipilih agar seragam dengan gaya bahasa proyek) |
| Amplop galat | `{"ok": false, "kode": "…", "pesan": "…", "rincian"?: {isian: pesan}, "alasan"?: […], "sisa_detik"?: n, "id_donatur"?: n}` | [RANCANGAN] |
| Nama field | **snake_case** untuk semua field JSON. `UPDATE_PLAN.md` Fase 12 masih mencampur nama isian PascalCase (`IdDonator`, `Jumlah`, `NoHP`); perlu diselaraskan. | [TERBUKA T4] |
| Tanggal/jam | `tanggal` `YYYY-MM-DD`, `waktu` `HH:MM:SS`, tanpa offset karena kolom DB tanpa zona dan data lama UTC (L4). `kedaluwarsa` token ISO-8601 dengan offset. | [RANCANGAN] |
| Paginasi | Tidak ada; semua daftar terbatas (≤ 20 hasil cari, ≤ ±200 input per hari, ≤ 31 baris per hari) | [ASUMSI A7] |
| Header khusus | `Authorization: Bearer <token>`; `Idempotency-Key: <UUID v4>` untuk `tambahdonasi`, `tambahdonatur`, `ubahdonasi`; jawaban yang diulang membawa `"ulang": true` | [RANCANGAN] |
| Tooling FE | mock: Prism; client: generator `dart` (berbasis `http`) ke `lib/api/gen/`, atau ditulis tangan | [TERBUKA T5] |
| Tooling BE | `tests/api.php` sebagai gerbang (pola uji proyek tanpa dependensi); schemathesis opsional | [TERBUKA T6] |

### 11.1 Draf aksi

Bahan untuk `kontrak/openapi.yaml`. Setelah kontrak ditulis, kontrak menjadi satu-satunya rumah, dan tabel ini serta tabel aksi di `UPDATE_PLAN.md` Fase 12 cukup merujuknya.

| Aksi | Metode | Permintaan | Jawaban `data` | Galat khusus |
|---|---|---|---|---|
| `login` | POST | `username`, `password` | `token`, `kedaluwarsa`, `pengguna{id, username, peran}` | 401 `login_gagal`; 429 `login_terkunci` (`sisa_detik`) |
| `konfigurasi` | GET | — | `versi_api`, `hari_ini`, `zona_waktu`, `nominal_umum[]`, `nominal_konfirmasi` | — |
| `donatur` | GET | `id` | `id, nama, alamat, no_hp, keterangan, bintang, riwayat[{tanggal, waktu, jumlah, note_n?}], total_tahun_ini, saran_jumlah\|null` | 404 `tidak_ada` |
| `caridonatur` | GET | `q` (≥ 2 karakter) | `[{id, nama, alamat}]`, ≤ 20, urut `nama, id` | 422 bila `q` < 2 |
| `tambahdonasi` | POST | `id_donatur`, `jumlah`, `konfirmasi?` | `sumbangan{id, id_donatur, nama_donatur, tanggal, waktu, jumlah}`, `hari_ini{total, transaksi, terakhir[≤6]}` | 422; 409 `perlu_konfirmasi` |
| `tambahdonatur` | POST | `nama, alamat, no_hp, keterangan, sumbangan, konfirmasi?` | `donatur{id, nama, alamat, no_hp, keterangan}`, `sumbangan{…}` | 422; 409 `donatur_sudah_ada` (`id_donatur`); 409 `perlu_konfirmasi` |
| `donasisaya` | GET | `tanggal?` (bawaan hari ini) | `tanggal, total, transaksi, daftar[{id, waktu, id_donatur, nama_donatur\|null, jumlah, boleh_ubah, note_n?}]`, urut terbaru dulu | 422 tanggal tidak valid |
| `ubahdonasi` | POST | `id`, `jumlah`, `konfirmasi?` | `sumbangan{…}` | 403 `tidak_berhak`; 404; 422; 409 `perlu_konfirmasi` |
| `rekap` | GET | `periode` (`hari`/`minggu`/`bulan`), `tanggal`, `cakupan` (`saya`/`semua`) | `periode, dari, sampai, cakupan, total, transaksi, donatur, per_hari[{tanggal, transaksi, total}], per_operator[{nama, transaksi, total}]` | 422 |
| `gantipassword` | POST | `lama`, `baru`, `ulang` | `token`, `kedaluwarsa` | 422 (pesan dari `prosesgantipassword.php`); 429 |

**Definisi `rekap`** [RANCANGAN, ASUMSI A8]

- Semua angka memakai `Note='y'`.
- `cakupan=saya` → `IdUser` = pengguna token.
- `minggu` = Senin s.d. Minggu yang memuat `tanggal`; `bulan` = tanggal 1 s.d. akhir bulan.
- `per_hari` hanya berisi hari yang ada datanya, urut naik (seperti `rekapalloperator`).
- `per_operator` hanya untuk `cakupan=semua`, memakai pola `jumlahoperator` (LEFT JOIN `user`; baris "User lama (sudah dihapus)" di akhir; urut total menurun).

**Paritas `rekap` dengan web** (L3, L4)

| Pembanding web | Angka mobile yang harus sama |
|---|---|
| `rekapoperator` (hari × semua) | `per_operator.transaksi` = kolom "Jumlah Donatur … orang"; `per_operator.total` = "Jumlah Sumbangan" |
| `rekapalloperator` (bulan × semua) | `per_hari.transaksi` = "Jumlah Penyumbang … orang" |
| `rekapbulanan` (bulan × semua) | `donatur` = "penyumbang" bulan itu |

**Keluar:** tidak ada aksi server. Klien menghapus token lokal. [ASUMSI A10]

## 12. Jebakan (landmines) → 16

Untuk manifest `landmines`. [FAKTA] kecuali disebut.

| # | Jebakan | Akibat bila diabaikan |
|---|---|---|
| L1 | Blok default "Profil PHP Native Modular" VCBD (Composer PSR-4, PDO, `modules/<domain>/`, `scripts/migrate.php`) **tidak cocok** dengan server ini: mysqli prosedural, tanpa Composer, `app/halaman/<nama>.php`, `bin/migrasi.php`. | Agen merombak server mengikuti default skill; melanggar batasan pemilik |
| L2 | Tabel latin1 dengan koneksi utf8mb4 dan mode STRICT: teks berisi emoji gagal dengan `ERROR 1366 Incorrect string value` (diuji 10 Okt 2026 di tabel sementara). Keyboard HP memudahkan emoji. | 500 saat tambah donatur. API wajib menolak teks di luar latin1 dengan 422. |
| L3 | "Jumlah Donatur/Penyumbang … orang" di `rekapoperator` dan `rekapalloperator` sebenarnya **jumlah transaksi** (`mysqli_num_rows` baris donasi). "penyumbang" di `rekapbulanan` adalah `COUNT(DISTINCT IdDonator)`. | Angka mobile "tidak cocok" dengan web; label menyesatkan |
| L4 | Jam data lama UTC (8 jam di belakang WITA); data baru WITA sejak kode baru dideploy (K1). Tanggal donasi lama pukul 00.00–07.59 WITA tercatat di tanggal UTC sebelumnya. | Jangan menambah offset atau mengonversi di klien maupun server |
| L5 | `rekapoperator` mengambil daftar operator dari tabel `user` (yang nonaktif ikut tampil dengan 0) dan **tidak** menghitung donasi user terhapus (20 transaksi dalam 12 bulan). `jumlahoperator` mengumpulkannya sebagai "User lama". | Jumlah total `per_operator` mobile bisa lebih besar dari total di `rekapoperator` pada tanggal yang punya donasi user terhapus; uji harus memperhitungkannya |
| L6 | Total "Jumlah Sumbangan" di Daftar Sumbangan web memakai `sql_note_daftar()`, sehingga untuk admin ikut menghitung Note n (`app/halaman/tampildonasi.php:14`), berbeda dengan aturan agregat. | Mobile memakai `Note='y'` untuk semua total; jangan meniru halaman itu |
| L7 | Tiga jendela waktu berbeda: bintang = tahun kalender **lalu**, riwayat = tahun kalender **berjalan**, saran = **12 bulan bergulir**. | Jangan disatukan |
| L8 | K5 menghitung semua donasi donatur pada tanggal itu tanpa filter Note, sehingga pesan K5 untuk operator bisa menyebut jumlah yang memuat baris Note n yang tidak boleh ia lihat. | Paritas dengan web dipertahankan; ubahan butuh keputusan [TERBUKA T13] |
| L9 | Router hanya menerima nama `[a-z0-9]+` satu segmen (`app/rute.php`); `/api/v1/login` dijawab 404. | Pakai `api?aksi=` |
| L10 | `app/bootstrap.php` selalu memanggil `session_start()`. | Tanpa pengecualian, setiap permintaan API membuat satu file sesi baru di `storage/sessions` |
| L11 | Apache dengan PHP-FPM/CGI membuang header `Authorization`. | Token tidak sampai; butuh `RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]` dan pembacaan `REDIRECT_HTTP_AUTHORIZATION` |
| L12 | Penangan exception di `bootstrap.php` mencetak panel HTML `infodanger()`. | API harus menjawab 500 JSON |
| L13 | Pesan alur web berisi HTML (`<br/>`, tabel di `konfirmasi_post()`, `infodanger()`). | Logika bersama harus mengembalikan data dan teks polos; HTML dirakit hanya di halaman web |
| L14 | `input_nominal` menerima 1 s.d. 2.147.483.647 tanpa titik atau koma; data berisi nominal Rp 1 dan nominal bukan kelipatan Rp 1.000. | Klien mengirim bilangan bulat polos; format hanya untuk tampilan. Peringatan nominal kecil [TERBUKA T16] |
| L15 | `donator.Id` smallint (maks 32767); maksimum sekarang 7.758. | Validasi 1–32767 |
| L16 | Penghitung penguncian login (`storage/cache/login-<sha1(IP\|username)>.json`) dipakai bersama web. IP seluler (NAT) bisa berganti. | Gagal login di mobile ikut mengunci web dari IP yang sama; wajar, tetapi perlu didokumentasikan |
| L17 | `password_cocok()` meng-hash ulang password plaintext saat login pertama dan saat `password_needs_rehash`, sehingga isi `user.Password` berubah. | Token yang ditandatangani dengan nilai lama langsung batal. Tanda tangan harus dibuat **setelah** `password_cocok()` dengan membaca ulang `Password`. Pengguna mobile ikut keluar bila hash diperbarui saat login web. |
| L18 | Produksi belum menjalankan M1 (password plaintext `varchar(32)`); lokal sudah. | `gantipassword` mengembalikan pesan "migrasi M1 belum dijalankan" di server tanpa M1; token tetap jalan |
| L19 | DB lokal adalah salinan produksi berisi PII. Uji yang menulis wajib memberi tanda dan membersihkan baris (`UJI-…`), dan menolak DB non-lokal. | Data uji tertinggal di salinan produksi |
| L20 | `tests/instalasi.php` menyalin semua berkas git (terlacak dan tak terlacak yang tidak di-ignore) ke rilis; `tests/smoke.php` me-lint seluruh pohon berkas. | `mDonator/` dan `kontrak/` ikut rilis server dan memperlambat lint; keduanya wajib dikecualikan |
| L21 | `NOMINAL_UMUM` tidak memuat 400.000 dan 600.000, padahal keduanya peringkat 6 dan 10 nominal tersering. | Tombol nominal cepat dari `NOMINAL_UMUM` melewatkan nominal populer [TERBUKA T8] |
| L22 | Hari Minggu adalah hari tersibuk sekaligus hari terakhir pekan (K14). | Rekap "Minggu ini" pada hari Minggu masih berubah sampai malam |
| L23 | Headless Chrome macet di mesin ini (catatan proyek); emulator `Pixel_5-Android_13` tersedia, tetapi menjalankannya tanpa layar belum dicoba. | Uji integrasi Flutter mungkin harus manual [ASUMSI] |

## 13. Keputusan yang sudah diambil

`UPDATE_PLAN.md` §9; hanya yang menyangkut mDonator.

| # | Keputusan |
|---|---|
| K1 | Pencatatan memakai WITA mulai versi baru; data lama tidak dikonversi |
| K3 | Note adalah atribut khusus admin; agregat memakai `Note='y'`; daftar operator tanpa Note n |
| K5 | Donasi ganda di hari yang sama boleh, dengan konfirmasi |
| K6 | Operator hanya mengubah donasi miliknya sendiri pada hari yang sama |
| K9 | Batas konfirmasi nominal Rp 5.000.000 (`NOMINAL_KONFIRMASI`) |
| K11 | mDonator khusus kerja operator; admin boleh masuk dengan fitur yang sama |
| K12 | Stack Flutter/Dart, native; server tetap PHP native dengan API JSON di aplikasi yang sama |
| K13 | Rekap dengan cakupan "Input saya" dan "Semua operator" |
| K14 | Pekan = Senin–Minggu |
| K15 | Tidak ada hapus donasi di mobile; ubah nominal milik sendiri hari ini ada |
| K16 | Tata letak HP sendiri dengan warna dan logo web; web tidak berubah |
| K17 | Kode Flutter di `mDonator/`, dikecualikan dari rilis server |

## 14. Asumsi (dipakai bila tidak dikoreksi)

| # | Asumsi |
|---|---|
| A1 | Metrik sukses seperti §2 |
| A2 | UI berbahasa Indonesia, nada formal-netral |
| A3 | Tanpa telemetri atau crash reporting pihak ketiga |
| A4 | Huruf Roboto bawaan Android |
| A5 | Rupiah "Rp 100.000"; tanggal d/m/Y dengan nama hari Indonesia; jam "HH:MM WITA" |
| A6 | Di perangkat hanya disimpan token, alamat server, dan username terakhir (secure storage); PII donatur hanya di memori layar |
| A7 | Tanpa paginasi |
| A8 | `per_hari` hanya hari yang ada datanya, urut naik |
| A9 | `donasisaya` urut terbaru dulu (Waktu menurun, lalu Id menurun) |
| A10 | Keluar = hapus token lokal; tanpa aksi server |
| A11 | `konfigurasi` wajib token |
| A12 | `caridonatur`: `q` ≥ 2 karakter, ≤ 20 hasil, urut Nama lalu Id; mencocokkan Id, Nama, atau Alamat seperti `tampildonatur` |
| A13 | Uji integrasi memakai `uji_operator`/`uji_admin` dan menghapus baris ujinya |
| A14 | Riwayat di Cek = tahun kalender berjalan (seperti `search2`) |
| A15 | Input Sumbangan menampilkan strip "Total input hari ini (N×): Rp …" dan 6 input terakhir (seperti `form-donasi.php`) |
| A16 | Timeout koneksi 10 detik dan permintaan 20 detik; POST tidak diulang otomatis, hanya lewat tombol |
| A17 | Komponen Material 3 bawaan Flutter; tanpa pustaka UI tambahan |
| A18 | Klien menolak server dengan `versi_api` mayor berbeda |
| A19 | Admin dapat mengubah nominal miliknya pada tanggal apa pun lewat Input Saya, karena `boleh_ubah_donasi()` mengizinkan admin |
| A20 | Slice S0–S6 menggantikan urutan lapisan 12a/12b/12c (perlu penyelarasan `UPDATE_PLAN.md`) |

## 15. Pertanyaan terbuka

| # | Pertanyaan | Rekomendasi |
|---|---|---|
| T1 | Tata letak paket VCBD | **Paket frontend penuh di `mDonator/`** (`docs/`, `CLAUDE.md`, `INDEX.md` di dalamnya). Kontraknya `mDonator/API_CONTRACT.md` yang sudah ditulis; `openapi.yaml` (di `kontrak/` atau `mDonator/`) hanya bila T5 memilih codegen. Sisi backend tetap diatur `UPDATE_PLAN.md` Fase 12 dan `CLAUDE.md` root, dengan hanya `docs/_MANIFEST.json` backend minimal (`split.role=backend`) supaya `validate-kontrak.sh --backend . --frontend mDonator` bisa memeriksa pin versi. Paket backend 28 dokumen di root akan bertabrakan dengan `CLAUDE.md` dan `UPDATE_PLAN.md` yang sudah ada (risiko kontradiksi). |
| T2 | Cara login (K18) | Token HMAC tanpa tabel, 16 jam, batal bila Nonaktif atau password diganti |
| T3 | Platform (K19) | Android dulu |
| T4 | Konvensi nama field JSON | snake_case untuk semua field. Sudah dipakai di `API_CONTRACT.md` 0.1.0, dan tabel aksi di `UPDATE_PLAN.md` sudah diganti rujukan ke kontrak. Mengubahnya berarti perubahan kontrak. |
| T5 | Client dari kontrak | Generator `dart` (berbasis `http`, tanpa `dio`/`built_value`) ke `lib/api/gen/`, tidak diedit tangan; atau tulis tangan dengan uji fixture terhadap skema. Rekomendasi: generator `dart`. |
| T6 | Uji kontrak backend | `tests/api.php` sebagai gerbang wajib; schemathesis opsional di lokal |
| T7 | Layar awal | Langsung ke Input Sumbangan (tugas tersering) dengan bottom navigation; ringkasan hari ini berupa strip di Input Sumbangan. Ini menggantikan "Beranda" di `UPDATE_PLAN.md`, yang perlu diselaraskan. |
| T8 | Tombol nominal cepat | Ambil dari `nominal_umum` server apa adanya; tambahan 400.000/600.000 diputuskan pemilik (mengubah `NOMINAL_UMUM` juga mengubah saran Fase 11) |
| T9 | Ikon aplikasi | Pemilik menyediakan logo yayasan PNG ≥ 1024 px; sementara itu dipakai ikon teks "mD" di atas `primer` |
| T10 | `applicationId` / nama paket | Tetapkan sebelum APK pertama dibagikan, mis. `com.kapuhmadani.mdonator`; tidak bisa diganti tanpa memasang ulang |
| T11 | Versi Android HP operator | `minSdk` bawaan Flutter; periksa HP operator sebelum distribusi |
| T12 | Metrik sukses | A1 |
| T13 | Pesan K5 yang ikut menghitung Note n | Pertahankan paritas dengan web; bila diubah, ubah juga di web |
| T14 | Perlindungan tangkapan layar (`FLAG_SECURE`) | Tidak dipakai |
| T15 | Masa berlaku token | 16 jam (input 23.00–05.00 WITA hampir tidak ada); bisa diubah lewat `API_TOKEN_HOURS` |
| T16 | Peringatan nominal kecil di klien | Konfirmasi lokal "Rp 100 — benar?" untuk nominal < Rp 1.000; aturan server tidak berubah |

## 16. Draf Ringkasan Kebutuhan (format VCBD Fase 2)

Disajikan ulang oleh `vcbd` setelah T1–T16 dijawab.

| Kategori | Ringkas |
|---|---|
| Tujuan & metrik | Input operator di HP, bergelombang (Minggu pagi, Kamis/Jumat malam). Metrik: ≥ 80% input lewat mobile dalam 3 bulan; ≤ 15 detik per input |
| Fitur MVP | F1 masuk/keluar · F2 alamat server · F3 cek/cari donatur · F4 input sumbangan · F5 tambah donatur · F6 Input Saya + ubah nominal hari ini · F7 rekap Hari/Minggu/Bulan × Saya/Semua · F8 ganti password |
| Out-of-scope | hapus donasi · Note/Input Khusus · ubah/hapus donatur dan kelola pengguna · daftar lengkap, grafik, rekap tahunan · offline · aplikasi donatur · perubahan skema · distribusi/deploy |
| Peran & akses | operator dan admin (fitur sama); Nonaktif ditolak; penegakan di server (K3, K6) |
| Alur utama | P1 masuk · P2 input (K5/K9, kirim ulang aman) · P3 tambah donatur (nama mirip, duplikat) · P4 Input Saya/ubah · P5 rekap · P6 ganti password · P7 pencabutan |
| Entitas inti | Pengguna, Sesi, Konfigurasi, Donatur, Sumbangan, Rekap, Galat; skema milik server (latin1, tanpa FK) |
| Data sensitif | Nama/Alamat/NoHP donatur (tidak disimpan di perangkat), token (secure storage), password (tidak disimpan) |
| Antarmuka | Jangkar: spanduk dan CSS web serta Bootstrap 3.3.7. Primer `#046500`, aksen `#FFFF33`, Roboto, radius 8, target sentuh 48 dp. Bottom navigation 4 tab; empat state per layar; tanpa gradien/emoji/pustaka UI |
| Kontrak API | monorepo `kontrak/` + `mDonator/`; `api?aksi=`; SemVer 0.1.0; bearer; amplop `{ok,data}` / `{ok:false,kode,pesan,…}`; snake_case; tanggal/jam tanpa offset; tanpa paginasi; `Idempotency-Key`; Prism + generator `dart`; `tests/api.php` |
| Profil native | Server: PHP native apa adanya (bukan blok default VCBD; L1). Klien: Flutter |
| Stack & versi | Flutter 3.47.5 / Dart 3.13.4 / Android SDK 28–36 / JDK 17; PHP 8.4 (lokal) dan 8.x (produksi); MySQL 8.4 / MariaDB 10.11 |
| Arsitektur & integrasi | layar → state (`ChangeNotifier`) → klien API → `api.php` → `app/api/*` → `app/donasi.php` (bersama web); tanpa integrasi pihak ketiga |
| Lingkungan & perintah | lokal saja; `php -S` + emulator `10.0.2.2`; perintah di §7.2 |
| Tes & keamanan | `tests/api.php` + regresi web 129/129 SAMA + MariaDB + instalasi; `flutter analyze/test`; token HMAC, tanpa sesi/CSRF/CORS, latin1, HTTPS rilis |
| Definisi terima/selesai | §8.4 / §8.5 |
| Kebijakan perubahan | git lokal, cabang `pembaruan`, commit atas permintaan; gerbang manusia untuk skema, produksi, `APP_KEY`, kontrak breaking, dependensi, `applicationId`, distribusi |

## 17. Benih `_MANIFEST.json` paket frontend

Isian lain diturunkan dari bagian dosir yang dirujuk; jangan disalin dua kali.

```json
{
  "app": { "name": "mDonator", "description": "Aplikasi Android operator untuk aplikasi Donatur Yayasan Ibnu Atha'illah", "type": "greenfield" },
  "requirements": {
    "stack": {
      "backend": "PHP 8.x native (mysqli prosedural) — repo donatur",
      "frontend": "Flutter 3.47.5 / Dart 3.13.4 (Android)",
      "db": "MySQL 8.4 lokal / MariaDB 10.11 produksi (milik backend)",
      "framework": { "backend": "none", "frontend": "flutter" },
      "forbidden": ["framework PHP", "Composer", "tabel DB baru", "WebView", "paket state management", "telemetri pihak ketiga", "dio/built_value", "http di rilis"]
    },
    "ui": { "enabled": true, "anchor": "spanduk header.jpg + public/css/style.css + Bootstrap 3.3.7 aplikasi Donatur" },
    "split": { "enabled": true, "role": "frontend", "contract_path": "API_CONTRACT.md (openapi.yaml bila T1/T5 memilihnya)", "contract_version": "0.1.0" }
  },
  "collapsed": ["07", "17", "19", "25"],
  "landmines": "§12 L1–L23",
  "assumptions": "§14 A1–A20",
  "open_questions": "§15 T1–T16"
}
```

- `07` dikolaps karena skema milik backend (lihat kontrak).
- `25` dikolaps karena distribusi ditunda.
- `referenced_by` memakai default VCBD, ditambah `"26": ["23","CLAUDE"]` dan pseudo-pemilik `"KONTRAK"` untuk 06, 14, dan 23.

## 18. Peta dosir → dokumen VCBD

| Bagian dosir | Dokumen |
|---|---|
| §1 Triase | manifest (`app`, `split`, `ui`, `stack.framework`) |
| §2 K1 | 00, 01 |
| §3 K2 | 01 (fitur, user story, NFR), 02 (scope), 03 (slice) |
| §4 K3 | 05 (peran, matriks), 06 (alur), 21 (penegakan) |
| §5 K4 | 04 (glosarium, entitas), 07 (stub → kontrak), 21 (data sensitif) |
| §6 K5 | 08 (arsitektur, keputusan), 09 (stack, terlarang), 12 (struktur, penamaan) |
| §7 K6 | 10 (setup), 11 (perintah), 15 (observability) |
| §8 K7 | 13 (uji), 14 (galat), 21 (keamanan), 23 (kriteria), 24 (DoD) |
| §9 K8 | 18, 20, 22, 25 |
| §10 K9 | 26 |
| §11 K10 | 27, `kontrak/openapi.yaml`, `kontrak/KONTRAK.md` |
| §12 Jebakan | 16 (manifest `landmines`) |
| §13–§15 | manifest (`assumptions`, `open_questions`); Ringkasan Kebutuhan |

## 19. Sumber bukti

| Sumber | Dipakai untuk |
|---|---|
| `UPDATE_PLAN.md` (Fase 12, §1, §4, §9 K1–K19, §10) | keputusan, rancangan, scope |
| `CLAUDE.md` (root) | batasan pemilik, perintah, tata letak, gotcha |
| `database/SCHEMA.sql` | skema |
| `app/auth.php` | peran, K6, password, penguncian login, Note |
| `app/web.php` | validator input, K5/K9, `NOMINAL_UMUM`, saran Jumlah |
| `app/audit.php`, `app/bootstrap.php`, `app/rute.php`, `public/index.php`, `public/.htaccess` | audit, sesi, router, rewrite |
| `app/halaman/search2.php` | bintang, riwayat, saran |
| `app/halaman/proseslogin.php`, `prosesgantipassword.php` | alur login dan ganti password |
| `app/halaman/prosestambahdonasi.php`, `prosestambahdonatur.php`, `prosesubahdonasi.php` | aturan tambah dan ubah |
| `app/halaman/tampildonasi.php`, `tampildonatur.php` | daftar sumbangan, pencarian donatur |
| `app/halaman/rekapoperator.php`, `rekapalloperator.php`, `rekapbulanan.php`, `jumlahoperator.php` | definisi rekap dan paritas |
| `app/views/form-donasi.php`, `app/views/header.php`, `public/css/style.css`, `public/css/bootstrap*.css`, `public/img/header.jpg` | strip hari ini, label, token visual |
| DB lokal `kapuhmad_donatur` (query agregat 10 Okt 2026) | §5.6, L2, L5, L21 |
| `flutter --version`, `~/Library/Android/sdk`, `emulator -list-avds`, `java -version`, `php -v`, `node -v`, `python3 --version` | §6.1 |
| `~/.claude/skills/vcbd` (SKILL.md v2.6, `references/protokol-wawancara.md`, `references/template-dokumen.md`) | struktur dosir |
