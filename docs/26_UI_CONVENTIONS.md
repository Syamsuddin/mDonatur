# 26 — UI_CONVENTIONS

**Jangkar.** Identitas visual aplikasi web Donatur (K16):

- spanduk `../public/img/header.jpg` (hijau–kuning);
- `../public/css/style.css`;
- Bootstrap 3.3.7.

Tata letak HP disusun sendiri. Koreksi kontras AA dari preview 10 Okt 2026 sudah masuk ke tabel. **Tabel ini beku:** nilai di luar tabel terlarang. Bila token tidak menjawab kebutuhan, berhenti dan tanya. Satu-satunya implementasinya di `lib/tema.dart`.

## Token warna

Rasio kontras di bawah dibulatkan ke bawah.

| Nama | Nilai | Dipakai untuk | Kontras |
|---|---|---|---|
| `primer` | `#046500` | AppBar, `FilledButton`, tab aktif, garis fokus | — |
| `diAtasPrimer` | `#FFFFFF` | Teks dan ikon di atas `primer`, `aksi`, `teksBahaya` | 7,3 : 1 di atas `primer` |
| `primerGelap` | `#003300` | Status bar | — |
| `aksen` | `#FFFF33` | **Hanya** di atas `primer`: nama yayasan di AppBar dan layar Masuk | 6,8 : 1 |
| `teks` | `#333333` | Teks utama | 12,6 : 1 |
| `teksLemah` | `#767676` | Label, keterangan, tab tidak aktif, strip hari ini | 4,54 : 1 |
| `latar` | `#FFFFFF` | Latar layar, kartu, dialog, lembar bawah | — |
| `garis` | `#DDDDDD` | Border isian dan kartu, pemisah, blok kerangka memuat | non-teks |
| `aksi` | `#337AB7` | Latar lencana bintang 3 | 4,56 : 1 dengan teks putih |
| `teksSukses` | `#3C763D` | Pesan sukses di kartu hasil | 5,4 : 1 |
| `teksInfo` | `#31708F` | Teks info (mis. "Persempit pencarian") | 5,4 : 1 |
| `teksPeringatan` | `#8A6D3B` | Judul daftar "Nama mirip" | 4,8 : 1 |
| `teksBahaya` | `#A94442` | Panel galat, `errorText`, latar lencana bintang 5 | 5,8 : 1 (juga dengan teks putih) |
| `sukses` | `#5CB85C` | Hanya latar lencana bintang 2, dengan teks `teks` | 5,0 : 1 |
| `info` | `#5BC0DE` | Hanya latar lencana bintang 0–1, dengan teks `teks` | 6,0 : 1 |
| `peringatan` | `#F0AD4E` | Hanya latar lencana bintang 4, dengan teks `teks` | 6,4 : 1 |

**Aturan warna**

- `ColorScheme` dibangun eksplisit dari token, **bukan** `fromSeed`:
  - `primary` dan `secondary` = `primer`;
  - `onPrimary`, `onSecondary`, dan `onError` = `diAtasPrimer`;
  - `error` = `teksBahaya`;
  - `surface` dan `surfaceTint` = `latar`, sehingga elevasi tidak mendapat rona hijau;
  - `onSurface` = `teks`, `onSurfaceVariant` = `teksLemah`;
  - `outline` dan `outlineVariant` = `garis`.
- Teks putih tidak boleh di atas `sukses`, `info`, `peringatan`, atau `#D9534F`, karena kontrasnya di bawah AA.
- Hanya tema terang; mode gelap di luar MVP.

## Token tipografi, jarak, dan bentuk

| Kategori | Nama | Nilai |
|---|---|---|
| Huruf | keluarga | Roboto bawaan Android (tidak dibundel) |
| Huruf | `label` | 14/20 sp, 400 → `bodyMedium`, label isian, label tab |
| Huruf | `tombol` | 14/20 sp, 500 → `labelLarge`; tab aktif juga 500 |
| Huruf | `isi` | 16/24 sp, 400 → `bodyLarge`, teks dalam isian |
| Huruf | `judul` | 20/28 sp, 500 → `titleLarge`, judul AppBar, nama di kartu donatur |
| Huruf | `nominal` | 28/36 sp, 700 → `headlineSmall` (diubah), nominal di kartu hasil |
| Huruf | `nomorRegister` | 32/40 sp, 700 → `headlineMedium` (diubah), Nomor Register di kartu hasil |
| Huruf | penanda `note_n` | berat 700 pada tanggal atau jam, ukuran tetap |
| Jarak | skala | 4 · 8 · 12 · 16 · 24 dp. Tepi layar 16, antar-isian 16 (layar Input Sumbangan 8), isi kartu 12, antar-tombol 8 |
| Bentuk | radius | 8 dp untuk kartu, tombol, isian, dialog, lencana, dan sudut atas lembar bawah |
| Bentuk | elevasi | 0 untuk isian, AppBar, dan NavigationBar (dipisah garis atas 1 dp warna `garis`); 1 untuk kartu |
| Sentuh | target | ≥ 48 × 48 dp; tinggi tombol 48 dp |
| Ikon | set | Material Icons bawaan (`Icons.*`), 24 dp. Tab: `add_card`, `person_add_alt_1`, `receipt_long`, `bar_chart`. Lainnya: `search`, `more_vert`, `settings`, `edit` |
| Logo | berkas | `assets/logo_yayasan.png`, logo Yayasan Ibnu Atha'illah 224 px dari pemilik (10 Okt 2026). Bagian putih di dalam logo tembus pandang, jadi logo selalu di atas `latar` atau alas lingkaran `latar`. Ikon terbesar dan layar pembuka memperbesar berkas ini sampai 1,4×; bila berkas asli ≥ 1024 px tersedia, ganti lalu buat ulang PNG Android [TERBUKA] |
| Logo | `logoKepala` | 56 dp di atas alas lingkaran `latar` 64 dp (tepi 4) pada kepala Masuk, sebaris dengan nama yayasan (jarak 12) dan ikon `settings` di kanan |
| Logo | `logoMemuat` | 80 dp di tengah layar memuat awal dan layar pembuka Android < 12 |
| Ikon peluncur | logo | Ikon adaptif: logo 66 dp (zona aman) di kanvas 108 dp, latar `latar`. Ikon lama (Android < 8): logo 40 dp di atas lingkaran `latar` 46 dp, kanvas 48 dp. Android 12 ke atas memakai ikon ini di layar pembuka sistem |

**Lencana bintang** berisi teks "Bintang {n}" dengan gaya `tombol`, dan `Semantics` "Bintang {n} dari 5".

| Bintang | Latar | Teks |
|---|---|---|
| 0–1 | `info` | `teks` |
| 2 | `sukses` | `teks` |
| 3 | `aksi` | `diAtasPrimer` |
| 4 | `peringatan` | `teks` |
| 5 | `teksBahaya` | `diAtasPrimer` |

## Inventaris komponen

| Komponen | Wujud | Rumah |
|---|---|---|
| Tema | `ThemeData`, `ColorScheme` eksplisit, `TextTheme` | `lib/tema.dart` |
| Kerangka | `Scaffold` + `AppBar` (judul layar, menu ⋮: Ganti Password, Pengaturan, Keluar) + `NavigationBar` 4 tab + `IndexedStack`; indikator tab aktif transparan | `lib/layar/kerangka.dart` |
| Tombol | `FilledButton`: Simpan, Masuk, Ya, simpan · `OutlinedButton`: Cek, Coba lagi, Kirim ulang · `TextButton`: Tidak, Batal, Pakai alamat bawaan | gaya di `lib/tema.dart` |
| Isian | `TextField` dengan `labelText`, `errorText`, dan border garis luar. Isian angka: keypad angka + hanya digit. Layar Input Sumbangan memakai isian padat (`isDense`, tetap ≥ 48 dp) | `lib/widget/isian_angka.dart` |
| Nominal cepat | Kisi 3 kolom berisi `OutlinedButton` bertuliskan "100.000" (tanpa "Rp"), hanya `nominal_umum` ≤ Rp 300.000: enam tombol 50.000–300.000 dalam dua baris | `lib/widget/nominal_cepat.dart` |
| Kartu donatur | `Card` ringkas: nama (`judul`) dan lencana sebaris; alamat; No HP · keterangan sebaris; "Riwayat {tahun}" dengan "Total Rp X" di kanan; riwayat "dd/MM Rp jumlah" yang terlipat | `lib/widget/kartu_donatur.dart` |
| Lencana bintang | lihat tabel di atas | `lib/widget/lencana_bintang.dart` |
| Logo yayasan | `Image.asset` selebar token Logo; `alas` = lingkaran `latar` untuk latar `primer`; label `Semantics` hanya bila nama yayasan tidak tertulis di sebelahnya | `lib/widget/logo_yayasan.dart` |
| Strip hari ini | Satu baris di bawah AppBar tab Input: "Total input hari ini (N×): Rp X" (`teksLemah`), tanpa daftar input terakhir; huruf mengecil bila tidak muat | `lib/widget/strip_hari_ini.dart` |
| Kartu hasil | `Card`: pesan sukses, nama donatur atau Nomor Register (`nomorRegister`), nominal (`nominal`), jam "HH:mm WITA" | `lib/widget/kartu_hasil.dart` |
| Dialog konfirmasi | `AlertDialog`: judul, nama donatur bila ada, daftar alasan, `TextButton` Tidak + `FilledButton` Ya, simpan. Dipakai juga untuk dialog nominal kecil dan Keluar | `lib/widget/dialog_konfirmasi.dart` |
| Panel galat | Kotak ber-border 1 dp `teksBahaya`, teks `teksBahaya`, tombol Coba lagi atau Kirim ulang | `lib/widget/panel_galat.dart` |
| State kosong | Teks `teksLemah` di tengah | `lib/widget/state_kosong.dart` |
| Kerangka memuat | Blok statis warna `garis`, tanpa animasi. Di tombol: `CircularProgressIndicator` 20 dp di dalam tombol nonaktif | `lib/widget/kerangka_memuat.dart` |
| Baris sumbangan | `ListTile`: jam (tebal bila `note_n`), "nomor · nama", jumlah di kanan, ikon `edit` bila `boleh_ubah` | `lib/widget/baris_sumbangan.dart` |
| Segmen | `SegmentedButton`: Hari / Minggu / Bulan dan Input saya / Semua operator | `lib/layar/rekap.dart` |

## Layar → pola

| Layar | Pola | Navigasi | Judul AppBar |
|---|---|---|---|
| Memuat awal | logo `logoMemuat` di tengah latar `latar`, tanpa AppBar, status bar `primerGelap` | P0, selama token dibaca dan `konfigurasi` dipanggil | — |
| Masuk | autentikasi; kepala `primer` berisi logo (`logoKepala`), nama yayasan (`aksen`), "mDonator", dan ikon `settings` dalam satu baris | awal tanpa token; didorong di atas kerangka saat 401 | — |
| Input Sumbangan | formulir, strip hari ini di atas | tab 1 "Input" (layar awal) | Input Sumbangan |
| Cari Donatur | daftar + cari | dari ikon `search` di Input | Cari Donatur |
| Tambah Donatur | formulir | tab 2 "Donatur" | Tambah Donatur |
| Input Saya | daftar + filter tanggal | tab 3 "Input Saya" | Input Saya |
| Ubah Sumbangan | formulir di lembar bawah | ketuk baris Input Saya | — |
| Rekap | dasbor | tab 4 "Rekap" | Rekap |
| Ganti Password | formulir | menu ⋮ | Ganti Password |
| Pengaturan | formulir + info diagnosa | menu ⋮ dan ikon `settings` di Masuk | Pengaturan |

Tidak ada aksi destruktif. Keluar dengan isian yang belum disimpan selalu lewat dialog (docs/06_BUSINESS_PROCESS.md P7).

## Perangkat

- Ponsel Android, orientasi potret dikunci, mobile-first.
- Wajib layak di lebar 360 dp dengan `textScaler` sampai 1,3 tanpa luapan. Tablet dan lanskap bukan target.
- Input Sumbangan muat satu layar tanpa digulir di HP 393×851 dp (Pixel 5) dengan skala huruf 1,0, untuk donatur dengan riwayat bulanan (keputusan pemilik 10 Okt 2026). Riwayat yang jauh lebih panjang, layar lebih kecil, atau keyboard terbuka boleh menggulir.
- Label tab 2 adalah "Donatur". Label "Donatur Baru" pecah dua baris pada 360 dp × 1,3 (diperiksa di emulator saat S0); pemilik memilih label lebih pendek, 10 Okt 2026.

## Empat state wajib

| Layar | Kosong | Memuat | Gagal | Sukses |
|---|---|---|---|---|
| Masuk | isian kosong | Masuk nonaktif + indikator | panel galat | tab Input |
| Input Sumbangan (Cek) | "Ketik nomor donatur lalu tekan Cek" | indikator di tombol Cek | `pesan` 404 di dekat isian / panel galat | kartu donatur |
| Input Sumbangan (Simpan) | — | Simpan nonaktif + indikator | panel galat, isian tetap | kartu hasil, isian dikosongkan |
| Cari Donatur | "Ketik minimal 2 huruf nama, alamat, atau nomor" | kerangka daftar | panel galat + Coba lagi | daftar / "Tidak ada donatur yang cocok" |
| Tambah Donatur | formulir kosong | Simpan nonaktif + indikator | `errorText` per isian / panel | kartu Nomor Register |
| Input Saya | "Belum ada input pada tanggal ini" | kerangka daftar | panel galat + Coba lagi | daftar + total |
| Rekap | "Tidak ada sumbangan pada periode ini" | kerangka kartu | panel galat + Coba lagi | ringkasan + rincian |
| Ganti Password, Pengaturan | isian | tombol nonaktif + indikator | `errorText` / panel | pesan sukses |

## Mikroteks

- Bahasa Indonesia, nada formal-netral. Pesan server ditampilkan apa adanya.
- **Kata kerja tombol tetap:** Cek, Simpan, Batal, Ya, simpan, Tidak, Masuk, Keluar, Coba lagi, Kirim ulang.
- **Label isian:** Username, Password, Nomor Donator, Sumbangan, Nama Donator, Alamat, Nomor Handphone, Keterangan, Sumbangan Pertama, Password Lama, Password Baru, Ulangi Password Baru, Alamat Server.
- **Format**
  - Rupiah "Rp 100.000" (`id_ID`, tanpa desimal).
  - Tanggal "Minggu, 12/10/2026"; rentang "Senin, 05/10/2026 – Minggu, 11/10/2026"; bulan "Oktober 2026". Riwayat di kartu donatur memakai tanggal ringkas "04/01" (tahunnya di judul "Riwayat 2026").
  - Jam "HH:mm". Label "WITA" hanya di kartu hasil, karena data baru pasti WITA, sedangkan data sebelum deploy tercatat UTC (K1).

## Aksesibilitas

- Kontras sesuai tabel token (AA).
- Setiap isian punya `labelText`, dan fokus terlihat (bawaan Material 3, warna `primer`).
- Ikon tanpa teks punya `tooltip`.
- Nominal dibacakan sebagai teks "Rp …". Lencana memakai `Semantics` "Bintang {n} dari 5".

## Larangan UI

- Nilai di luar tabel token, `ColorScheme.fromSeed`, dan rona elevasi.
- Pustaka UI atau set ikon lain; font yang dibundel.
- Gradien (navbar web memakai gradien, aplikasi tidak); emoji.
- Animasi dekoratif (shimmer, transisi kustom).
- Teks placeholder yang tertinggal; WebView.

Kriteria antarmuka yang diuji: docs/23_ACCEPTANCE_CRITERIA.md.
