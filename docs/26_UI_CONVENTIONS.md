# 26 — UI_CONVENTIONS

**Jangkar.** Identitas visual aplikasi web Donatur (K16):

- spanduk `../public/img/header.jpg` (hijau–kuning);
- `../public/css/style.css`;
- Bootstrap 3.3.7.

**Arah desain C "Dasbor Yayasan"**, dipilih pemilik 10 Okt 2026 dari tiga usulan (S7). Kepala hijau bergradien dengan pola bintang delapan melanjutkan spanduk web. Angka penting tampil kuning di atas hijau. Isi layar berada di lembar hijau sangat muda yang berkartu putih, Rekap memakai grafik, dan gerak singkat menandai sumbangan yang tersimpan.

Tata letak HP disusun sendiri. **Tabel ini beku:** nilai di luar tabel terlarang. Bila token tidak menjawab kebutuhan, berhenti dan tanya. Satu-satunya implementasinya di `lib/tema.dart`.

## Token warna

Rasio kontras di bawah dibulatkan ke bawah. Untuk gradien, kontras dihitung terhadap ujung yang paling terang (`primerTerang`).

| Nama | Nilai | Dipakai untuk | Kontras |
|---|---|---|---|
| `primer` | `#046500` | Indikator tab, tombol Cek, `FilledButton` dialog, garis fokus, nominal di kartu, garis grafik | 7,3 : 1 dengan `diAtasPrimer` |
| `primerTua` | `#023F00` | Ujung atas `gradienKepala` dan ujung kiri `gradienTombol`; teks segmen terpilih di atas `aksen` | 11,4 : 1 dengan `aksen` |
| `primerTerang` | `#0B7A2E` | Ujung bawah `gradienKepala` dan ujung kanan `gradienTombol`; latar di balik sudut atas lembar | — |
| `diAtasPrimer` | `#FFFFFF` | Teks dan ikon di atas `primer`, gradien, dan `pilKepala` | 5,4 : 1 di atas `primerTerang` |
| `diAtasPrimerNonaktif` | `#FFFFFF` alfa 38 % (`0x61FFFFFF`) | Ikon nonaktif di kepala (panah periode Rekap) | non-teks |
| `aksen` | `#FFFF33` | **Hanya** di atas `primer`, gradien, atau `pilKepala`: angka kepala, nama yayasan, inisial avatar, latar segmen terpilih, cincin logo | 5,1 : 1 di atas `primerTerang` |
| `pilKepala` | `#0F5F12` | Latar pil dan wadah segmen di kepala | 7,9 : 1 dengan `diAtasPrimer` |
| `teks` | `#333333` | Teks utama | 12,6 : 1 di `latar`, 11,4 : 1 di `latarDasbor` |
| `teksLemah` | `#6B6B6B` | Label, keterangan, sumbu grafik, tab tidak aktif, state kosong | 5,3 : 1 di `latar`, 4,8 : 1 di `latarDasbor` |
| `latar` | `#FFFFFF` | Kartu, isian, dialog, lembar bawah, navigasi, layar memuat awal | — |
| `latarDasbor` | `#F1F5F0` | Lembar isi di bawah kepala dan latar `Scaffold` | — |
| `garis` | `#DDDDDD` | Pemisah (`Divider`) dan latar tombol utama nonaktif | non-teks |
| `garisLembut` | `#E0E8DE` | Border isian, nominal cepat, dan `OutlinedButton`; tulang kerangka memuat | non-teks |
| `hijauLembut` | `#E3F0E1` | Cincin lingkaran cek kartu hasil | non-teks |
| `kuningLembut` | `#FFF59A` | Latar nominal cepat terpilih (dengan teks `teks`); cincin titik hari ini di grafik | 11,3 : 1 dengan `teks` |
| `emas` | `#B7791F` | Ikon bintang lencana dan garis nominal cepat terpilih | 3,6 : 1 di `latar` (non-teks) |
| `ungu` | `#6F42C1` | Hanya palet grafik | 6,4 : 1 di `latar` |
| `hijauSedang` | `#43A047` | Hanya palet grafik | 3,3 : 1 di `latar` |
| `aksi` | `#337AB7` | Hanya palet grafik | 4,5 : 1 di `latar` |
| `teksSukses` | `#3C763D` | Pesan sukses | 5,4 : 1 di `latar`, 4,9 : 1 di `latarDasbor` |
| `teksInfo` | `#31708F` | Teks info (mis. "Persempit pencarian") | 5,4 : 1 di `latar`, 4,9 : 1 di `latarDasbor` |
| `teksPeringatan` | `#8A6D3B` | Judul "Nama mirip" (selalu di dalam kartu `latar`); palet grafik | 4,8 : 1 di `latar` |
| `teksBahaya` | `#A94442` | Panel galat, `errorText`, ikon hapus baris sumbangan (admin, S8) | 5,8 : 1 di `latar`, 5,3 : 1 di `latarDasbor` |
| `bayangan` | `#043C00` alfa 20 % (`0x33043C00`) | Bayangan kartu, navigasi mengambang, dan tombol utama | — |
| `pola` | `#FFFFFF` alfa 10 % (`0x1AFFFFFF`) | Garis pola bintang di atas gradien kepala | dekoratif |
| `transparan` | `0x00000000` | AppBar, status bar, dan latar `FilledButton` di dalam tombol utama | — |

**Palet grafik**, urut sesuai urutan baris server: `primer`, `aksi`, `emas`, `ungu`, `hijauSedang`, `teksPeringatan`, lalu berulang. Baris "User lama (sudah dihapus)" (`id_user: null`) selalu `teksLemah`.

**Aturan warna**

- `ColorScheme` dibangun eksplisit dari token, **bukan** `fromSeed`:
  - `primary` dan `secondary` = `primer`;
  - `onPrimary`, `onSecondary`, dan `onError` = `diAtasPrimer`;
  - `error` = `teksBahaya`;
  - `surface` dan `surfaceTint` = `latar`, sehingga elevasi tidak mendapat rona hijau;
  - `onSurface` = `teks`, `onSurfaceVariant` = `teksLemah`;
  - `outline` = `garisLembut`, `outlineVariant` = `garis`;
  - `shadow` = `bayangan`.
- Teks putih tidak boleh di atas `kuningLembut`, `hijauSedang`, atau `emas`. `teksPeringatan` hanya di atas `latar`.
- Di kepala hanya boleh `diAtasPrimer`, `aksen`, `pilKepala`, dan kotak `latar` (isian, panel galat).
- Hanya tema terang; mode gelap di luar MVP.

## Gradien dan pola

| Nama | Wujud | Dipakai untuk |
|---|---|---|
| `gradienKepala` | Linear atas → bawah: `primerTua` → `primerTerang` | Kepala semua layar, dari tepi atas layar (di belakang status bar dan AppBar) sampai bawah isi kepala; lingkaran cek kartu hasil |
| `gradienTombol` | Linear kiri → kanan: `primerTua` → `primerTerang` | Tombol utama yang aktif |
| `areaGrafik` | Linear atas → bawah: `primer` alfa 30 % → `primer` alfa 0 % | Area di bawah garis grafik per hari |
| `polaBintang` | Ubin 44 dp: dua persegi 20 dp di tengah ubin (satu diputar 45°) dan lingkaran jari-jari 4 dp, garis 1 dp warna `pola` | Di atas `gradienKepala`, juga di layar Masuk |

Gradien lain terlarang. Kepala berakhir lurus; lembar isi di bawahnya bersudut atas 24 dp, dan sudut itu berlatar `primerTerang` sehingga tampak menumpang di kepala.

## Token tipografi, jarak, dan bentuk

| Kategori | Nama | Nilai |
|---|---|---|
| Huruf | keluarga isi | **Plus Jakarta Sans** (Tokotype, OFL 1.1), TTF statis 400 · 500 · 600 · 700 · 800 di `assets/huruf/` |
| Huruf | keluarga tampilan | **Outfit** (OFL 1.1), TTF statis 600 · 700 · 800 di `assets/huruf/` |
| Huruf | jarak huruf | 0 di semua token huruf; jarak huruf bawaan Material 3 dirancang untuk Roboto dan melebarkan kedua huruf ini |
| Huruf | `label` | Plus Jakarta Sans 14/20 sp, 400 → `bodyMedium`, label isian, keterangan |
| Huruf | `kecil` | Plus Jakarta Sans 12/16 sp, 600 → `labelMedium`, label tab, pil, label sumbu grafik, teks lencana |
| Huruf | `tombol` | Plus Jakarta Sans 14/20 sp, 700 → `labelLarge`, tombol dan segmen |
| Huruf | `isi` | Plus Jakarta Sans 16/24 sp, 400 → `bodyLarge`, teks dalam isian, baris daftar |
| Huruf | `judulKartu` | Outfit 16/22 sp, 700 → `titleMedium`, judul kartu ("Rincian per hari"), nama di kartu donatur |
| Huruf | `judul` | Outfit 20/28 sp, 600 → `titleLarge`, judul AppBar, nama di kartu hasil, judul dialog dan lembar |
| Huruf | `nominal` | Outfit 28/36 sp, 800 → `headlineSmall`, nominal kartu hasil dan Total ringkasan Rekap |
| Huruf | `angkaKepala` | Outfit 30/38 sp, 800 → `displaySmall`, angka di kepala (total hari ini, total Input Saya), warna `aksen` |
| Huruf | `nomorRegister` | Outfit 32/40 sp, 800 → `headlineMedium`, Nomor Register di kartu hasil |
| Huruf | penanda `note_n` | berat 700 pada tanggal atau jam yang dasarnya 400, ukuran tetap |
| Jarak | skala | 4 · 8 · 12 · 16 · 24 dp. Tepi layar 16, antar-isian 16 (layar Input Sumbangan 8, dengan jarak atas lembar 12), isi kartu 12, antar-kartu 12 (layar Input 8), antar-tombol 8, bawah isi kepala 12, antar-baris riwayat kartu donatur 2 |
| Bentuk | radius | Kartu 18 · isian, tombol Cek, nominal cepat, panel galat 12 · lembar isi, lembar bawah, dialog, navigasi 24 · tombol lain, segmen, pil, lencana: pil penuh (`StadiumBorder`) |
| Bentuk | elevasi | AppBar 0 (transparan) · isian 0 · kartu 2 · navigasi mengambang 3 · tombol utama: bayangan `bayangan` 0/6 dp blur 16. Semua bayangan berwarna `bayangan` |
| Bentuk | navigasi | `NavigationBar` tinggi 64 dp, mengambang dengan jarak 12 dp kiri-kanan dan 8 dp bawah (di atas inset sistem), indikator pil 64 × 32 dp (bawaan Material 3) |
| Sentuh | target | ≥ 48 × 48 dp; tinggi tombol 48 dp; tombol utama 52 dp |
| Ikon | set | Material Icons bawaan (`Icons.*`), 24 dp. Tab: `add_card`, `person_add_alt_1`, `receipt_long`, `bar_chart`. Lainnya: `search`, `more_vert`, `settings`, `edit`, `delete_outline`, `chevron_left`, `chevron_right`, `calendar_month`, `error_outline`, `check_rounded`, `star_rounded`, `star_outline_rounded` |
| Ikon | ukuran lain | Bintang lencana 16 dp; ikon state kosong 40 dp (ikon tab layar itu, `teksLemah`); centang kartu hasil 32 dp |
| Avatar | inisial | Lingkaran `primer` 40 dp, satu atau dua huruf pertama kata nama (kapital), Outfit 800 15 sp warna `aksen` |
| Logo | berkas | `assets/logo_yayasan.png`, logo Yayasan Ibnu Atha'illah 224 px dari pemilik (10 Okt 2026). Bagian putih di dalam logo tembus pandang, jadi logo selalu di atas `latar` atau alas lingkaran `latar`. Ikon terbesar dan layar pembuka memperbesar berkas ini sampai 1,4×; bila berkas asli ≥ 1024 px tersedia, ganti lalu buat ulang PNG Android [TERBUKA] |
| Logo | `logoKepala` | 56 dp di atas alas lingkaran `latar` 64 dp (tepi 4) bercincin `aksen` 2 dp, pada kepala Masuk, sebaris dengan nama yayasan (jarak 12) dan ikon `settings` di kanan |
| Logo | `logoBar` | 28 dp di atas alas lingkaran `latar` 32 dp bercincin `aksen` 2 dp, sebagai `leading` AppBar kerangka |
| Logo | `logoMemuat` | 80 dp di tengah layar memuat awal dan layar pembuka Android < 12 |
| Ikon peluncur | logo | Ikon adaptif: logo 66 dp (zona aman) di kanvas 108 dp, latar `latar`. Ikon lama (Android < 8): logo 40 dp di atas lingkaran `latar` 46 dp, kanvas 48 dp. Android 12 ke atas memakai ikon ini di layar pembuka sistem |

**Lencana bintang** berupa satu baris berisi lima ikon bintang 16 dp warna `emas`: `n` ikon `star_rounded` lalu `5 − n` ikon `star_outline_rounded`, diikuti teks "Bintang {n}" bergaya `kecil` warna `teks`. `Semantics`-nya "Bintang {n} dari 5". Nilai `n` (0–5) dari server.

## Token gerak

| Nama | Nilai | Dipakai untuk |
|---|---|---|
| `cepat` | 200 ms, `easeOutCubic` | Kartu donatur dan kartu hasil muncul: pudar dari 0 dan naik 8 dp |
| `pop` | 450 ms, `easeOutBack` | Lingkaran cek kartu hasil: skala 0,3 → 1 |
| `hitung` | 700 ms, `easeOutCubic` | Nominal kartu hasil naik dari Rp 0 ke nilainya, dibulatkan ke ribuan selama berjalan |
| `kilau` | 1.500 ms, berulang | Kilau kerangka memuat dari `garisLembut` ke `latarDasbor` |
| `grafik` | 300 ms, `easeOutCubic` | Grafik berganti data |

**Aturan gerak**

- Bila pengaturan Android "Hapus animasi" aktif (`MediaQuery.disableAnimations`), semua gerak mati: kartu langsung tampil, nominal langsung bernilai akhir, kerangka memuat statis, dan grafik berganti tanpa gerak.
- Pembaca layar selalu menerima nilai akhir, juga selama nominal menghitung naik.
- Gerak tidak pernah menunda tombol atau isian. Simpan berikutnya bisa langsung diketik.
- Transisi halaman memakai bawaan Material; transisi kustom terlarang.

## Inventaris komponen

| Komponen | Wujud | Rumah |
|---|---|---|
| Tema | `ThemeData`, `ColorScheme` eksplisit, `TextTheme` dua keluarga huruf, serta token gradien, pola, dan gerak | `lib/tema.dart` |
| Latar dasbor | `gradienKepala` + `polaBintang` dari tepi atas layar sampai bawah isi kepala (status bar, AppBar transparan, lalu isi kepala opsional per layar), kemudian lembar isi `latarDasbor` bersudut atas 24 dp. Lembarnya mengisi sisa layar; isi lembar yang menggulir, kepala diam | `lib/widget/latar_dasbor.dart` |
| Kerangka | `Scaffold` + AppBar transparan (`logoBar`, judul layar, menu ⋮: Ganti Password, Pengaturan, Keluar) + `NavigationBar` mengambang 4 tab + `IndexedStack`; gerak tab yang tidak aktif dihentikan (`TickerMode`) | `lib/layar/kerangka.dart` |
| AppBar | Transparan tanpa elevasi; judul `judul` dan ikon `diAtasPrimer`; status bar transparan berikon terang | gaya di `lib/tema.dart` |
| Navigasi | `NavigationBar` `latar`, mengambang, radius 24, elevasi 3; indikator pil `primer`; ikon terpilih `diAtasPrimer`, lainnya `teksLemah`; label `kecil`, yang terpilih `primer` | `lib/layar/kerangka.dart` |
| Tombol utama | `FilledButton` pil setinggi 52 dp di atas `gradienTombol` dengan bayangan; nonaktif berlatar `garis` dengan teks `teksLemah`. Dipakai untuk Simpan di semua layar dan Masuk | `lib/widget/tombol_utama.dart` |
| Tombol | `FilledButton` pil `primer`: Ya, simpan dan Keluar di dialog · `OutlinedButton` pil `latar` bergaris `garisLembut`, teks `primer`: Coba lagi, Kirim ulang, Pengaturan, Keluar di layar versi · Cek: `OutlinedButton` bergaya isi (latar `primer`, teks `diAtasPrimer`, radius 12) · `TextButton`: Tidak, Batal, Pakai alamat bawaan | gaya di `lib/tema.dart` |
| Isian | `TextField` terisi `latar` dengan `labelText` dan `errorText`, border 1 dp `garisLembut`, radius 12; fokus 2 dp `primer`; galat `teksBahaya`. Isian angka: keypad angka + hanya digit. Layar Input Sumbangan memakai isian padat (`isDense`, tetap ≥ 48 dp). **Isian di kepala** (cari, Tanggal): gaya terisi tanpa garis, label melayang di dalam kotak `latar` radius 12, fokus garis bawah 2 dp `primer`, sebab label bergaris akan jatuh di atas gradien | `lib/widget/isian_angka.dart`; gaya isian kepala di `lib/tema.dart` |
| Nominal cepat | Kisi 3 kolom `OutlinedButton` radius 12 bertuliskan "100.000" (tanpa "Rp"), hanya `nominal_umum` ≤ Rp 300.000: enam tombol 50.000–300.000 dalam dua baris. Tombol yang nilainya sama dengan isian Sumbangan tampil terpilih: latar `kuningLembut`, garis 1,5 dp `emas`, teks 800 | `lib/widget/nominal_cepat.dart` |
| Kartu | `Card` `latar`, radius 18, elevasi 2, tanpa border | gaya di `lib/tema.dart` |
| Kartu donatur | `Card` ringkas: avatar inisial dengan nama (`judulKartu`, agar nama panjang tetap satu baris di 393 dp) dan lencana bintang di bawahnya; "Alamat …" dan "No HP … · Keterangan …" selebar kartu; pemisah; "Riwayat {tahun}" dengan "Total Rp X" (`tombol`, `primer`) di kanan; riwayat "dd/MM Rp jumlah" yang terlipat, apa adanya dari server tanpa dijumlah per bulan. Muncul dengan gerak `cepat` | `lib/widget/kartu_donatur.dart` |
| Lencana bintang | lihat aturan di atas | `lib/widget/lencana_bintang.dart` |
| Ringkasan hari ini | Isi kepala tab Input: label "Total input hari ini" (`label`, `diAtasPrimer`), nominal `angkaKepala` (`aksen`) yang mengecil bila tidak muat, pil "{N} transaksi" (`pilKepala`, `kecil`, `diAtasPrimer`). Memuat: kerangka memuat satu baris di kepala (tulang `pilKepala`, kilau ke `primerTerang`). Gagal: panel galat dengan Coba lagi. Selama keyboard terbuka, ringkasan dilipat dengan gerak `cepat` agar isian tetap mendapat ruang | `lib/widget/strip_hari_ini.dart` |
| Kartu hasil | `Card` berisi di tengah: lingkaran 56 dp `gradienKepala` dengan ikon `check_rounded` 32 dp dan cincin 6 dp `hijauLembut` (gerak `pop`), pesan sukses (`teksSukses`), Nomor Register (label + `nomorRegister`) bila donatur baru, nama donatur atau "(donatur terhapus)" (`judul`), nominal (`nominal`, `primer`, gerak `hitung`), jam "HH:mm WITA" (`teksLemah`). Muncul dengan gerak `cepat` | `lib/widget/kartu_hasil.dart` |
| Dialog konfirmasi | `AlertDialog` radius 24: judul, nama donatur bila ada, daftar alasan, `TextButton` Tidak + `FilledButton` Ya, simpan. Dipakai juga untuk dialog nominal kecil dan Keluar | `lib/widget/dialog_konfirmasi.dart` |
| Panel galat | Kotak `latar` radius 12, border 1 dp `teksBahaya`, ikon `error_outline` dan teks `teksBahaya`, tombol Coba lagi atau Kirim ulang. Kotak putihnya membuat panel juga terbaca di kepala | `lib/widget/panel_galat.dart` |
| State kosong | Ikon tab layar itu (40 dp, `teksLemah`) di atas teks `teksLemah`, di tengah | `lib/widget/state_kosong.dart` |
| Kerangka memuat | `Skeletonizer` berisi baris tiruan: tulang `garisLembut` dengan gerak `kilau`, statis bila Hapus animasi aktif; teks tiruan tidak pernah terlihat atau dibacakan. Di tombol: `CircularProgressIndicator` 20 dp di dalam tombol nonaktif | `lib/widget/kerangka_memuat.dart` |
| Baris sumbangan | `ListTile` di dalam `Card`: jam (tebal bila `note_n`), "nomor · nama", jumlah (`isi`, 700) di kanan, ikon `edit` `primer` bila `boleh_ubah`, lalu `IconButton` `delete_outline` `teksBahaya` (target 48 dp, tooltip "Hapus") bila `boleh_hapus` (admin, S8). Selama menghapus, ikonnya diganti indikator tombol 20 dp | `lib/widget/baris_sumbangan.dart` |
| Centang Note | `Checkbox` Material bawaan (tercentang berlatar `primer` dengan centang `diAtasPrimer`, kosong bergaris `teksLemah`) dengan label "Note" (`label`) yang ikut bisa diketuk, target ≥ 48 dp; sebaris di kanan isian Sumbangan, hanya bila `boleh_atur_note` (admin, S8) | `lib/layar/input_sumbangan.dart` |
| Segmen | `SegmentedButton` pil di kepala Rekap: Hari / Minggu / Bulan dan Input saya / Semua operator. Wadah `pilKepala`, teks `diAtasPrimer`; terpilih berlatar `aksen` dengan teks `primerTua` 800; tanpa ikon centang | gaya di `lib/tema.dart` |
| Grafik per hari | `LineChart` (`fl_chart`) setinggi 160 dp di `Card` "Rincian per hari" (periode Minggu dan Bulan): satu titik per tanggal dari `dari` sampai `sampai`, berhenti di `hari_ini` server. Tanggal yang tidak ada di `per_hari` bernilai 0 (kontrak §6.9). Garis `primer` 3 dp melengkung tanpa melampaui titik, area `areaGrafik`, titik hari ini lingkaran `primer` 5 dp bercincin `kuningLembut`; label sumbu `kecil` `teksLemah`, label hari ini `primer` (Minggu: nama hari Sen–Min tiap hari; Bulan: tanggal 1, 8, 15, 22, 29); tanpa sumbu nilai, sentuh, dan tooltip. Baris rincian per hari tetap tampil di bawahnya | `lib/widget/grafik_rekap.dart` |
| Donat per operator | `PieChart` (`fl_chart`) donat 120 dp, lubang 60 %, di `Card` "Rincian per operator" (cakupan Semua operator); bagian berwarna palet grafik sesuai urutan `per_operator`. Baris rincian per operator di bawahnya menjadi legenda: titik 12 dp berwarna sama sebagai `leading` | `lib/widget/grafik_rekap.dart` |

## Layar → pola

| Layar | Isi kepala | Lembar isi | Navigasi | Judul AppBar |
|---|---|---|---|---|
| Memuat awal | — (tanpa kepala) | logo `logoMemuat` di tengah latar `latar`, status bar berikon gelap | P0, selama token dibaca dan `konfigurasi` dipanggil | — |
| Masuk | `logoKepala`, nama yayasan (`judul`, `aksen`), "mDonator" (`isi`, `diAtasPrimer`), ikon `settings` sebaris | lembar `latar` bersudut atas 24: Username, Password, tombol utama Masuk | awal tanpa token; didorong di atas kerangka saat 401 | — |
| Input Sumbangan | ringkasan hari ini | Nomor Donator + Cari + Cek, panel/kartu, Sumbangan (dengan centang Note bagi admin), nominal cepat; tombol utama Simpan dan panel galatnya tetap di bawah | tab 1 "Input" (layar awal) | Input Sumbangan |
| Cari Donatur | isian cari | `Card` daftar hasil: avatar inisial, nama, "nomor · alamat" | dari ikon `search` di Input | Cari Donatur |
| Tambah Donatur | — | kartu hasil, isian, "Nama mirip" di dalam `Card`; tombol utama Simpan tetap di bawah | tab 2 "Donatur" | Tambah Donatur |
| Input Saya | pilihan Tanggal (isian `latar` baca-saja, ikon `calendar_month`) dan, bila ada data, "Total N transaksi" (`label`, `diAtasPrimer`) dengan nominal `angkaKepala` | `Card` berisi baris sumbangan | tab 3 "Input Saya" | Input Saya |
| Ubah Sumbangan | — | lembar bawah `latar` bersudut atas 24, judul `judul`, tombol utama Simpan | ketuk baris Input Saya | — |
| Rekap | segmen periode, segmen cakupan, navigasi periode (`chevron_left`/`chevron_right` dan judul rentang, `diAtasPrimer`) | `Card` ringkasan (Total `nominal` `primer`, Transaksi, Donatur), `Card` Rincian per operator (donat), `Card` Rincian per hari (grafik) | tab 4 "Rekap" | Rekap |
| Ganti Password | — | formulir, tombol utama Simpan | menu ⋮ | Ganti Password |
| Pengaturan | — | formulir, tombol utama Simpan, `Card` info diagnosa | menu ⋮ dan ikon `settings` di Masuk | Pengaturan |
| Gagal memuat, versi tidak cocok | — | panel galat dan tombolnya | P0 | mDonator |

Satu-satunya aksi destruktif adalah hapus sumbangan oleh admin di Input Saya. Atas permintaan pemilik, aksi ini dikirim tanpa dialog konfirmasi (K23, docs/06_BUSINESS_PROCESS.md P4.6). Keluar dengan isian yang belum disimpan selalu lewat dialog (docs/06_BUSINESS_PROCESS.md P7).

## Perangkat

- Ponsel Android, orientasi potret dikunci, mobile-first.
- Wajib layak di lebar 360 dp dengan `textScaler` sampai 1,3 tanpa luapan. Tablet dan lanskap bukan target.
- Input Sumbangan muat satu layar tanpa digulir di HP 393×851 dp (Pixel 5) dengan skala huruf 1,0 dan huruf aplikasi, untuk donatur dengan riwayat bulanan (keputusan pemilik 10 Okt 2026). Riwayat yang jauh lebih panjang, layar lebih kecil, atau keyboard terbuka boleh menggulir.
- Label tab 2 adalah "Donatur". Label "Donatur Baru" pecah dua baris pada 360 dp × 1,3 (diperiksa di emulator saat S0); pemilik memilih label lebih pendek, 10 Okt 2026.
- Layar digambar sampai ke tepi (edge-to-edge): kepala mengisi area status bar, dan navigasi mengambang di atas inset bawah sistem.

## Empat state wajib

| Layar | Kosong | Memuat | Gagal | Sukses |
|---|---|---|---|---|
| Masuk | isian kosong | Masuk nonaktif + indikator | panel galat | tab Input |
| Input Sumbangan (Cek) | "Ketik nomor donatur lalu tekan Cek" | indikator di tombol Cek | `pesan` 404 di dekat isian / panel galat | kartu donatur |
| Input Sumbangan (Simpan) | — | Simpan nonaktif + indikator | panel galat, isian tetap | kartu hasil, isian dikosongkan |
| Ringkasan hari ini (kepala Input) | — | kerangka memuat satu baris | panel galat + Coba lagi | label, nominal, pil |
| Cari Donatur | "Ketik minimal 2 huruf nama, alamat, atau nomor" | kerangka daftar | panel galat + Coba lagi | daftar / "Tidak ada donatur yang cocok" |
| Tambah Donatur | formulir kosong | Simpan nonaktif + indikator | `errorText` per isian / panel | kartu Nomor Register |
| Input Saya | "Belum ada input pada tanggal ini" | kerangka daftar | panel galat + Coba lagi | ringkasan di kepala + daftar |
| Input Saya (hapus, admin) | — | indikator di tombol hapus baris itu, hapus lain nonaktif | panel galat di atas daftar (Kirim ulang / Coba lagi / tanpa tombol) | daftar dimuat ulang tanpa baris itu |
| Rekap | "Tidak ada sumbangan pada periode ini" | kerangka kartu | panel galat + Coba lagi | ringkasan + rincian + grafik |
| Ganti Password, Pengaturan | isian | tombol nonaktif + indikator | `errorText` / panel | pesan sukses |

## Mikroteks

- Bahasa Indonesia, nada formal-netral. Pesan server ditampilkan apa adanya.
- **Kata kerja tombol tetap:** Cek, Simpan, Batal, Ya, simpan, Tidak, Masuk, Keluar, Coba lagi, Kirim ulang.
- **Label isian:** Username, Password, Nomor Donator, Sumbangan, Nama Donator, Alamat, Nomor Handphone, Keterangan, Sumbangan Pertama, Password Lama, Password Baru, Ulangi Password Baru, Alamat Server, Tanggal, Nama, alamat, atau nomor. Label centang: Note. Tooltip ikon hapus: Hapus.
- **Teks kepala dan kartu:** "Total input hari ini", "{N} transaksi", "Total N transaksi", "Total", "Transaksi", "Donatur", "Rincian per operator", "Rincian per hari".
- **Format**
  - Rupiah "Rp 100.000" (`id_ID`, tanpa desimal).
  - Tanggal "Minggu, 12/10/2026"; rentang "Senin, 05/10/2026 – Minggu, 11/10/2026"; bulan "Oktober 2026". Riwayat di kartu donatur memakai tanggal ringkas "04/01" (tahunnya di judul "Riwayat 2026"). Sumbu grafik: tanggal "5" untuk Bulan, nama hari "Sen" untuk Minggu.
  - Jam "HH:mm". Label "WITA" hanya di kartu hasil, karena data baru pasti WITA, sedangkan data sebelum deploy tercatat UTC (K1).

## Aksesibilitas

- Kontras sesuai tabel token (AA).
- Setiap isian punya `labelText`, dan fokus terlihat (garis 2 dp `primer`).
- Ikon tanpa teks punya `tooltip`.
- Nominal dibacakan sebagai teks "Rp …". Lencana memakai `Semantics` "Bintang {n} dari 5".
- Grafik punya `Semantics` "Grafik rincian per hari" dan "Grafik rincian per operator". Angkanya tetap terbaca lewat baris rincian di bawah grafik.
- Pengaturan "Hapus animasi" dihormati (Token gerak).

## Larangan UI

- Nilai di luar tabel token, `ColorScheme.fromSeed`, dan rona elevasi.
- Gradien di luar tabel Gradien dan pola; emoji.
- Gerak di luar Token gerak, gerak yang mengabaikan Hapus animasi, dan transisi halaman kustom.
- Pustaka UI di luar Material bawaan dan tiga paket docs/09_STACK.md (`fl_chart`, `flutter_animate`, `skeletonizer`); set ikon lain; huruf selain dua keluarga yang dibundel; `google_fonts` atau huruf yang diunduh saat berjalan.
- Grafik yang menjumlah atau menyaring data di Dart: grafik hanya menggambar angka jawaban server.
- Teks placeholder yang tertinggal; WebView.

Kriteria antarmuka yang diuji: docs/23_ACCEPTANCE_CRITERIA.md.
