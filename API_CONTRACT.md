# Kontrak API mDonator

**Versi kontrak: 0.1.0** · 10 Oktober 2026 · Status: **draf**; sisi server sudah diimplementasikan (Fase 12b, 10 Okt 2026, diuji `tests/api.php`), klien belum (12c).

Kontrak ini mengikat dua pihak:

- **Server:** aplikasi Donatur (PHP native), di `app/halaman/api.php` dan `app/api/*.php`.
- **Klien:** aplikasi Flutter mDonator di `mDonator/`.

## 1. Kedudukan dokumen

- **Satu-satunya rumah** untuk alamat, aksi, isi permintaan, isi jawaban, kode galat, dan aturan pemakaian API. Dokumen lain (`UPDATE_PLAN.md` Fase 12, `DOSIR_MDONATOR.md`, dan dokumen blueprint) hanya merujuk ke sini.
- **Kontrak menang.**
  - Server yang tidak sesuai kontrak = bug server.
  - Klien yang berasumsi di luar kontrak = bug klien.
  - Bila kontrak sendiri keliru atau kurang: berhenti, laporkan, dan tunggu keputusan pemilik sebelum mengubah kode.
- **Aturan bisnis tetap milik server.** Kontrak hanya menjelaskan perilaku yang terlihat dari luar. Klien tidak menghitung ulang aturan K5, K6, K9, Note, bintang, saran, maupun rekap.
- **Bila nanti dibuat `openapi.yaml`** (mode split VCBD, keputusan T1/T5 di dosir): berkas itu diturunkan dari dokumen ini dalam satu langkah dan harus setara isinya. Sejak saat itu `openapi.yaml` menjadi rumah endpoint dan payload, dan dokumen ini menyusut menjadi aturan (§1–§5, §7–§9).
- **Keputusan yang dipakai:**
  - [KEPUTUSAN] K3, K5, K6, K9, K11–K17 di `UPDATE_PLAN.md` §9.
  - Rekomendasi dosir yang belum dijawab pemilik: T2 (token HMAC 16 jam), T4 (nama field snake_case), A7 (tanpa paginasi), dan A9–A12. Mengubah salah satunya berarti mengubah kontrak (§9).

## 2. Alamat dan transport

| Butir | Aturan |
|---|---|
| Basis | `{BASE}` = nilai `APP_URL` server, tanpa garis miring akhir. Bisa root domain (`https://donatur.contoh.org`) atau subfolder (`https://contoh.org/donatur`). Klien tidak menanam basis di kode (`--dart-define=SERVER_URL`, bisa diubah di Pengaturan). |
| Alamat aksi | `{BASE}/api?aksi=<aksi>`. Parameter GET lain ditambahkan ke query string yang sama. Jangan memakai `api.php`: GET ke `api.php` dialihkan 301. |
| Metode | Setiap aksi punya satu metode (GET atau POST, lihat §6). Metode lain → 405 dengan header `Allow`. `OPTIONS` juga 405; tidak ada CORS. |
| Isi permintaan POST | JSON, dengan header `Content-Type: application/json`. Selain JSON → 415. Isi bukan JSON yang sah atau bukan objek → 400. Maksimum 16 KB → di atas itu 413. |
| Isi permintaan GET | Tanpa isi; semua masukan lewat query string. |
| Jawaban | Selalu JSON, termasuk saat galat. Header: `Content-Type: application/json; charset=utf-8`, `Cache-Control: no-store`, `X-Api-Versi: 0.1.0`. Tidak pernah ada `Set-Cookie`. |
| Skema | Build rilis klien hanya memakai `https://`. `http://` hanya untuk build debug (server lokal, `http://10.0.2.2:3000` di emulator). |
| Batas waktu klien | Koneksi 10 detik, permintaan 20 detik. POST tidak diulang otomatis (§7). |

## 3. Autentikasi

- **Login:** semua aksi kecuali `login` wajib membawa header `Authorization: Bearer <token>`.
- **Token buram bagi klien.** Klien menyimpannya di secure storage, mengirimnya apa adanya, dan **tidak mengurai isinya**. Masa berlaku dibaca dari field `kedaluwarsa`.
- **Masa berlaku:** `API_TOKEN_HOURS` jam sejak terbit (bawaan 16).
- **Token batal seketika** bila:
  - password pengguna berubah, lewat web maupun `gantipassword`;
  - server memperbarui hash password saat pengguna login;
  - akun bukan lagi `admin`/`Operator` di `user.Keterangan`, misalnya di-Nonaktifkan;
  - `APP_KEY` server diganti (semua token batal).
- **Peran dibaca ulang dari DB** di setiap permintaan; perubahan peran langsung berlaku.
- **Tidak ada pencabutan per perangkat.** Untuk mencabut akses: ganti password atau set Nonaktif.
- **Keluar** cukup dengan menghapus token di perangkat; tidak ada aksi server.
- **Cookie diabaikan.** Cookie sesi web (`DONATUR_SID`) tidak berlaku di API; tanpa token, jawabannya 401.
- **Jawaban 401** membawa header `WWW-Authenticate: Bearer`.
- **API mati:** bila `APP_KEY` di server kosong, semua aksi (termasuk `login`) menjawab 503 `api_mati`. Halaman web tidak terpengaruh.

*Catatan implementasi server, bukan bagian antarmuka:* bentuk token dan cara penandatanganannya ada di `UPDATE_PLAN.md` Fase 12 (HMAC-SHA256, kunci `APP_KEY` digabung nilai `user.Password`). Tanda tangan dibuat setelah `password_cocok()` selesai.

## 4. Konvensi data

| Butir | Aturan |
|---|---|
| Nama field | `snake_case` bahasa Indonesia, sama dengan istilah domain (`id_donatur`, `jumlah`, `no_hp`) |
| Bilangan | Bilangan bulat JSON. Rupiah selalu bulat tanpa desimal. Server tidak menerima angka sebagai string atau pecahan (`"100000"` dan `100000.0` → 422). |
| Teks | String JSON UTF-8, dipangkas spasi depan-belakang oleh server. Teks donatur (`nama`, `alamat`, `no_hp`, `keterangan`) hanya boleh berisi karakter yang ada di Latin-1 (U+0000–U+00FF), sehingga emoji → 422. Alasannya: tabel latin1 menolak karakter lain dengan galat server. |
| Tanggal | `"YYYY-MM-DD"`. Tanggal masukan harus tanggal sah antara 2000-01-01 dan 2100-12-31. |
| Jam | `"HH:MM:SS"`, tanpa zona. Data baru tercatat dalam WITA (`Asia/Makassar`). Data sebelum versi baru dideploy tercatat dalam UTC dan **tidak dikonversi** (K1). Klien menampilkan apa adanya, tanpa menambah atau mengurangi jam. |
| Waktu lengkap | Hanya `kedaluwarsa`, dalam ISO-8601 dengan offset zona server, mis. `"2026-10-13T00:15:00+08:00"` |
| Boolean | `true`/`false` JSON. `konfirmasi` hanya dianggap benar bila bernilai `true`. |
| Kosong | Field yang tidak punya nilai dikirim `null` bila tertulis "atau null" di §6. Teks opsional yang tidak diisi dikirim `""`. |
| Field tak dikenal | Klien **wajib mengabaikan** field jawaban yang tidak dikenalnya (dasar perubahan minor, §9). Server mengabaikan field permintaan yang tidak dikenal, termasuk `id_user`, `note`, `tanggal`, dan `waktu` pada aksi tulis. |
| Paginasi | Tidak ada. Semua daftar terbatas: `caridonatur` ≤ 20, `donasisaya` satu hari, `rekap.per_hari` ≤ 31. |
| "Hari ini" | Selalu tanggal server dalam `APP_TIMEZONE` (WITA), yang dikirim di `konfigurasi.hari_ini`. Klien tidak memakai jam HP untuk menentukan hari. |

## 5. Amplop jawaban

**Sukses**

```json
{ "ok": true, "data": { } }
```

Jawaban yang diputar ulang dari kunci kirim ulang (§7) menambahkan `"ulang": true` di samping `"ok"`.

**Galat**

```json
{ "ok": false, "kode": "tidak_valid", "pesan": "Isian belum benar.", "rincian": { "jumlah": "Nominal sumbangan Kosong" } }
```

| Field | Ada pada | Isi |
|---|---|---|
| `kode` | semua galat | Kode mesin dari katalog §8 |
| `pesan` | semua galat | Kalimat bahasa Indonesia, teks polos tanpa HTML, siap ditampilkan |
| `rincian` | `tidak_valid` | Objek *nama field → pesan* untuk isian yang salah |
| `alasan` | `perlu_konfirmasi` | Daftar kalimat alasan konfirmasi (K5, K9) |
| `donatur` | `perlu_konfirmasi` pada `tambahdonasi` | `{ "id": int, "nama": string }` untuk ditampilkan di dialog |
| `sisa_detik` | `login_terkunci` | Sisa waktu penguncian dalam detik |
| `id_donatur` | `donatur_sudah_ada` | Nomor donatur yang sudah terdaftar |

Klien memutuskan tindakan dari **status HTTP dan `kode`**, dan menampilkan `pesan` atau `rincian`. Bila menerima `kode` yang tidak dikenal, klien bertindak menurut status HTTP saja.

## 6. Aksi

Ringkasan:

| Aksi | Metode | Token | Kunci kirim ulang | Fungsi |
|---|---|:-:|:-:|---|
| `login` | POST | — | — | Masuk, mendapat token |
| `konfigurasi` | GET | ✓ | — | Versi API, hari ini, nominal, pengguna |
| `donatur` | GET | ✓ | — | Detail satu donatur (Cek) |
| `caridonatur` | GET | ✓ | — | Cari donatur lewat nomor, nama, atau alamat |
| `tambahdonasi` | POST | ✓ | wajib | Simpan sumbangan |
| `tambahdonatur` | POST | ✓ | wajib | Donatur baru beserta sumbangan pertama |
| `donasisaya` | GET | ✓ | — | Input saya pada satu tanggal |
| `ubahdonasi` | POST | ✓ | wajib | Ubah nominal satu sumbangan |
| `rekap` | GET | ✓ | — | Rekap hari, minggu, atau bulan |
| `gantipassword` | POST | ✓ | — | Ganti password, mendapat token baru |

Tidak ada aksi hapus. `aksi=hapusdonasi` dan nama lain yang tidak ada di tabel → 404 `aksi_tidak_ada`.

Struktur yang dipakai berulang:

- **`Sumbangan`**: `{ "id": int, "id_donatur": int, "nama_donatur": string atau null, "tanggal": "YYYY-MM-DD", "waktu": "HH:MM:SS", "jumlah": int }`. `nama_donatur` bernilai `null` bila donaturnya sudah terhapus (donasi yatim, K7).
- **`RingkasanHariIni`**: input pengguna token pada hari ini, hanya `Note='y'`, sama dengan strip di form input web.

  ```text
  { "tanggal": "YYYY-MM-DD", "total": int, "transaksi": int,
    "terakhir": [ { "id_donatur": int, "jumlah": int, "waktu": "HH:MM:SS" } ] }
  ```

  `terakhir` berisi paling banyak 6 baris, urut `waktu` menurun, hanya donasi yang donaturnya masih ada.

### 6.1 `login` — POST

Permintaan:

| Field | Tipe | Aturan |
|---|---|---|
| `username` | string | wajib, 1–50 karakter |
| `password` | string | wajib, 1–200 karakter |

Jawaban 200:

```json
{ "ok": true, "data": {
  "token": "eyJ1Ijo2LCJ0IjoxNzYwMjU0OTAwLCJlIjoxNzYwMzEyNTAwfQ.4mQb…",
  "kedaluwarsa": "2026-10-13T00:15:00+08:00",
  "pengguna": { "id": 6, "username": "operator1", "peran": "operator" } } }
```

`peran` bernilai `"admin"` atau `"operator"`.

Galat:

| Status | `kode` | Kapan |
|---|---|---|
| 422 | `tidak_valid` | `username` atau `password` kosong atau terlalu panjang; `rincian` per field |
| 401 | `login_gagal` | Username tidak ada, password salah, atau akun bukan admin/operator. Pesannya selalu sama: "Username dan Password anda salah!" |
| 429 | `login_terkunci` | Terlalu banyak percobaan gagal; `sisa_detik` ikut dikirim. Pesan: "Terlalu banyak percobaan gagal. Coba lagi dalam N menit." |
| 503 | `api_mati` | `APP_KEY` kosong |

Penguncian dipakai bersama halaman login web:

- kuncinya kombinasi alamat IP dan username;
- setelah `LOGIN_MAX_ATTEMPTS` kali gagal (bawaan 5) dalam `LOGIN_LOCK_MINUTES` menit, akun terkunci selama `LOGIN_LOCK_MINUTES` menit (bawaan 15);
- login berhasil mengosongkan penghitungnya.

### 6.2 `konfigurasi` — GET

Tanpa parameter. Dipanggil saat aplikasi dibuka dan setelah masuk. Aksi ini sekaligus memeriksa bahwa token masih sah dan membawa peran terbaru.

```json
{ "ok": true, "data": {
  "versi_api": "0.1.0",
  "hari_ini": "2026-10-12",
  "zona_waktu": "Asia/Makassar",
  "nominal_umum": [50000, 100000, 150000, 200000, 250000, 300000, 350000, 500000, 1000000, 2000000],
  "nominal_konfirmasi": 5000000,
  "pengguna": { "id": 6, "username": "operator1", "peran": "operator" } } }
```

- `nominal_umum` adalah daftar tombol nominal cepat; isinya mengikuti konstanta server `NOMINAL_UMUM`.
- Galat: 401 (§8).

### 6.3 `donatur` — GET

| Parameter | Aturan |
|---|---|
| `id` | wajib, bilangan bulat 1–32767 |

```json
{ "ok": true, "data": {
  "id": 1234, "nama": "Fulan bin Fulan", "alamat": "Desa Kapuh, Simpur", "no_hp": "08xx", "keterangan": "",
  "bintang": 2,
  "tahun": 2026,
  "riwayat": [ { "tanggal": "2026-01-04", "waktu": "09:12:40", "jumlah": 200000 } ],
  "total_tahun_ini": 200000,
  "saran_jumlah": 200000 } }
```

| Field | Arti |
|---|---|
| `bintang` | 0–5, dari total sumbangan `Note='y'` donatur pada **tahun kalender lalu** dibagi 12. Ambang: < 50.000 → 0 · < 150.000 → 1 · < 250.000 → 2 · < 600.000 → 3 · < 1.250.000 → 4 · selebihnya 5. |
| `tahun` | Tahun kalender server yang dipakai `riwayat` dan `total_tahun_ini` |
| `riwayat` | Sumbangan donatur pada `tahun`, urut tanggal, jam, lalu id naik. Untuk operator hanya `Note='y'`. Untuk admin juga baris `Note='n'`, yang membawa `"note_n": true`. Field `note_n` tidak pernah dikirim ke operator. |
| `total_tahun_ini` | Jumlah `Note='y'` pada `tahun`, untuk semua peran. Untuk admin bisa lebih kecil dari jumlah baris `riwayat`. |
| `saran_jumlah` | Rata-rata sumbangan `Note='y'` donatur dalam 12 bulan terakhir, bila hasilnya tepat salah satu `nominal_umum`; selain itu `null` |

Galat:

| Status | `kode` | Kapan |
|---|---|---|
| 422 | `tidak_valid` | `id` bukan bilangan bulat 1–32767; `rincian.id` = "Nomor donatur harus angka 1–32767." |
| 404 | `tidak_ada` | Pesan: "Data Donator nomor {id} tidak ditemukan!" |

### 6.4 `caridonatur` — GET

| Parameter | Aturan |
|---|---|
| `q` | wajib, 2–100 karakter setelah dipangkas |

Kecocokan:

- `q` dicari di nomor, nama, atau alamat donatur (bagian dari teks, tanpa membedakan huruf besar-kecil);
- karakter `%`, `_`, dan `\` di `q` diperlakukan sebagai huruf biasa;
- hasil urut nama, lalu id; paling banyak 20.

```json
{ "ok": true, "data": {
  "hasil": [ { "id": 1234, "nama": "Fulan bin Fulan", "alamat": "Desa Kapuh, Simpur" } ],
  "lebih": false } }
```

- `lebih` bernilai `true` bila ada lebih dari 20 kecocokan. Klien menampilkan "Persempit pencarian".
- `hasil` boleh kosong.
- Galat: 422 `tidak_valid` (`rincian.q` = "Ketik minimal 2 huruf.").

### 6.5 `tambahdonasi` — POST, kunci kirim ulang wajib

| Field | Tipe | Aturan |
|---|---|---|
| `id_donatur` | int | wajib; harus nomor donatur yang terdaftar |
| `jumlah` | int | wajib; 1–2.147.483.647 |
| `konfirmasi` | bool | opsional, bawaan `false` |

Urutan pemeriksaan server:

1. **Validasi isian** → 422.

   | Field | Masalah | Pesan |
   |---|---|---|
   | `id_donatur` | tidak ada | "Nomor Register Kosong" |
   | `id_donatur` | bukan int atau tidak terdaftar | "Nomor Register tidak terdaftar" |
   | `jumlah` | tidak ada | "Nominal sumbangan Kosong" |
   | `jumlah` | bukan int dalam rentang | "Nominal sumbangan harus angka tanpa titik atau koma" |

2. **Konfirmasi** (dilewati bila `konfirmasi: true`) → 409 `perlu_konfirmasi`, dengan `alasan` dan `donatur`:
   - **K5:** donatur ini sudah tercatat menyumbang pada hari ini. Yang dihitung adalah semua sumbangannya hari itu, dari operator mana pun. Alasan: "Donatur nomor {id} sudah tercatat menyumbang {n} kali hari ini."
   - **K9:** `jumlah` > `nominal_konfirmasi`. Alasan: "Nominal Rp. {jumlah},- di atas Rp. {batas},-." (angka bertitik ribuan)
3. **Simpan.** Server mengisi sendiri:
   - pengguna dari token;
   - tanggal dan jam dari jam server (WITA);
   - `Note='y'`, juga bila admin yang menginput.

Jawaban **201**:

```json
{ "ok": true, "data": {
  "sumbangan": { "id": 145437, "id_donatur": 1234, "nama_donatur": "Fulan bin Fulan", "tanggal": "2026-10-12", "waktu": "09:15:02", "jumlah": 200000 },
  "ringkasan_hari_ini": { "tanggal": "2026-10-12", "total": 1450000, "transaksi": 9,
                          "terakhir": [ { "id_donatur": 1234, "jumlah": 200000, "waktu": "09:15:02" } ] } } }
```

Contoh 409:

```json
{ "ok": false, "kode": "perlu_konfirmasi", "pesan": "Periksa sebelum menyimpan.",
  "alasan": [ "Donatur nomor 1234 sudah tercatat menyumbang 1 kali hari ini." ],
  "donatur": { "id": 1234, "nama": "Fulan bin Fulan" } }
```

### 6.6 `tambahdonatur` — POST, kunci kirim ulang wajib

| Field | Tipe | Aturan dan pesan galat |
|---|---|---|
| `nama` | string | wajib, ≤ 100 karakter: "Nama donatur kosong." / "Nama donatur terlalu panjang (maks. 100 karakter)." |
| `alamat` | string | wajib, ≤ 255: "Alamat donatur kosong." / "Alamat terlalu panjang (maks. 255 karakter)." |
| `no_hp` | string | boleh `""`, ≤ 20: "Nomor HP terlalu panjang (maks. 20 karakter)." Bentuknya tidak diperiksa, sama dengan web. |
| `keterangan` | string | boleh `""`, ≤ 255: "Keterangan terlalu panjang (maks. 255 karakter)." |
| `sumbangan` | int | wajib, 1–2.147.483.647: "Nominal sumbangan kosong." / "Nominal sumbangan harus angka tanpa titik atau koma." |
| `konfirmasi` | bool | opsional, bawaan `false` |

Teks di luar Latin-1 pada keempat field teks → pesan "Gunakan huruf, angka, dan tanda baca biasa (tanpa emoji)."

Urutan pemeriksaan server:

1. **Validasi** → 422. `rincian` memuat semua field yang salah sekaligus.
2. **Duplikat persis:** ada donatur dengan `nama`, `alamat`, `no_hp`, dan `keterangan` yang sama persis setelah dipangkas → 409 `donatur_sudah_ada`, dengan `id_donatur` dan pesan "Data Donator Sudah Ada!". Berlaku juga bila `konfirmasi: true`.
3. **Konfirmasi K9** (dilewati bila `konfirmasi: true`): `sumbangan` > `nominal_konfirmasi` → 409 `perlu_konfirmasi`, alasan "Nominal di atas Rp. {batas},-." Tidak ada pemeriksaan K5, karena donaturnya baru.
4. **Simpan atomik:** donatur dan sumbangan pertamanya tersimpan bersama atau tidak sama sekali. Sumbangan pertama tercatat dengan pengguna dari token, jam server, dan `Note='y'`.

Peringatan "nama mirip" sebelum menyimpan bukan bagian aksi ini. Klien memakai `caridonatur` dengan isi `nama`.

Jawaban **201**:

```json
{ "ok": true, "data": {
  "donatur": { "id": 7759, "nama": "Fulan bin Fulan", "alamat": "Desa Kapuh, Simpur", "no_hp": "", "keterangan": "" },
  "sumbangan": { "id": 145438, "id_donatur": 7759, "nama_donatur": "Fulan bin Fulan", "tanggal": "2026-10-12", "waktu": "09:20:11", "jumlah": 100000 },
  "ringkasan_hari_ini": { "tanggal": "2026-10-12", "total": 1550000, "transaksi": 10,
                          "terakhir": [ { "id_donatur": 7759, "jumlah": 100000, "waktu": "09:20:11" },
                                        { "id_donatur": 1234, "jumlah": 200000, "waktu": "09:15:02" } ] } } }
```

### 6.7 `donasisaya` — GET

| Parameter | Aturan |
|---|---|
| `tanggal` | opsional, bawaan hari ini (server) |

```json
{ "ok": true, "data": {
  "tanggal": "2026-10-12", "total": 1550000, "transaksi": 10,
  "daftar": [ { "id": 145438, "waktu": "09:20:11", "id_donatur": 7759, "nama_donatur": "Fulan bin Fulan",
                "jumlah": 100000, "boleh_ubah": true } ] } }
```

| Field | Arti |
|---|---|
| `total`, `transaksi` | Jumlah dan banyaknya sumbangan `Note='y'` milik pengguna token pada `tanggal`, untuk semua peran |
| `daftar` | Sumbangan milik pengguna token pada `tanggal`, urut `waktu` lalu `id` menurun. Untuk operator hanya `Note='y'`. Untuk admin juga `Note='n'` dengan `"note_n": true`. |
| `boleh_ubah` | Hasil aturan K6 dari server: operator hanya untuk tanggal hari ini; admin selalu `true`. Klien hanya mengizinkan Ubah pada baris yang `true`. |

Galat: 422 `tidak_valid` (`rincian.tanggal`).

### 6.8 `ubahdonasi` — POST, kunci kirim ulang wajib

| Field | Tipe | Aturan |
|---|---|---|
| `id` | int | wajib; id sumbangan |
| `jumlah` | int | wajib; 1–2.147.483.647 |
| `konfirmasi` | bool | opsional, bawaan `false` |

Hanya nominal yang bisa diubah. `Note`, donatur, tanggal, dan jam tidak berubah, dan field lain diabaikan.

Urutan pemeriksaan server:

1. `id` tidak sah atau tidak ada → 404 `tidak_ada`, "Data sumbangan tidak ditemukan."
2. Bukan hak pengguna (K6) → 403 `tidak_berhak`: "Operator hanya dapat mengubah atau menghapus sumbangan yang ia input sendiri pada hari ini."
3. `jumlah` tidak sah → 422 (`rincian.jumlah` = "Nominal sumbangan harus angka tanpa titik atau koma.").
4. **Konfirmasi K9** (dilewati bila `konfirmasi: true`): `jumlah` > `nominal_konfirmasi` **dan** berbeda dari nominal lama → 409 `perlu_konfirmasi`, alasan "Nominal baru Rp. {jumlah},- di atas Rp. {batas},-."
5. Simpan. Nominal yang sama dengan sebelumnya tetap dijawab sukses.

Jawaban 200: `{ "ok": true, "data": { "sumbangan": Sumbangan + "boleh_ubah": bool } }`

### 6.9 `rekap` — GET

| Parameter | Aturan |
|---|---|
| `periode` | wajib: `hari`, `minggu`, atau `bulan` |
| `tanggal` | opsional, bawaan hari ini (server); tanggal mana pun di dalam periode yang diminta |
| `cakupan` | opsional: `saya` (bawaan) atau `semua` |

Rentang:

| Periode | `dari` | `sampai` |
|---|---|---|
| `hari` | `tanggal` | `tanggal` |
| `minggu` | Senin pekan yang memuat `tanggal` (K14) | Minggu pekan itu |
| `bulan` | tanggal 1 bulan itu | tanggal terakhir bulan itu |

```json
{ "ok": true, "data": {
  "periode": "minggu", "cakupan": "semua", "tanggal": "2026-10-08",
  "dari": "2026-10-05", "sampai": "2026-10-11",
  "total": 27000000, "transaksi": 146, "donatur": 139,
  "per_hari": [ { "tanggal": "2026-10-05", "transaksi": 98, "total": 18100000 },
                { "tanggal": "2026-10-08", "transaksi": 48, "total": 8900000 } ],
  "per_operator": [ { "id_user": 3, "nama": "operator1", "transaksi": 80, "total": 15000000 },
                    { "id_user": 6, "nama": "operator2", "transaksi": 65, "total": 11950000 },
                    { "id_user": null, "nama": "User lama (sudah dihapus)", "transaksi": 1, "total": 50000 } ],
  "navigasi": { "sebelum": "2026-09-28", "sesudah": "2026-10-12" } } }
```

**Semua angka hanya menghitung `Note='y'`**, untuk semua peran. `cakupan=saya` membatasi ke sumbangan pengguna token.

| Field | Arti |
|---|---|
| `total` | Jumlah rupiah |
| `transaksi` | Banyaknya baris sumbangan |
| `donatur` | Banyaknya donatur berbeda. **Bukan** jumlah transaksi. |
| `per_hari` | Hanya hari yang ada sumbangannya, urut tanggal naik. Selalu ada: untuk `hari` berisi 0 atau 1 baris. |
| `per_operator` | Hanya diisi bila `cakupan=semua`; selain itu `[]`. Hanya operator yang punya transaksi di rentang itu, urut `total` menurun lalu `nama`. Sumbangan milik user yang sudah terhapus digabung di baris terakhir dengan `id_user: null` dan nama "User lama (sudah dihapus)". |
| `navigasi.sebelum` | Tanggal awal periode sebelumnya |
| `navigasi.sesudah` | Tanggal awal periode berikutnya; `null` bila periode itu dimulai setelah hari ini |

Galat: 422 `tidak_valid` untuk `periode`, `tanggal`, atau `cakupan` yang tidak sah.

Padanan di web, untuk uji paritas. Angka harus sama untuk tanggal yang sama:

| Halaman web | Angka padanannya |
|---|---|
| `rekapoperator` | `per_operator.transaksi` (kolom "Jumlah Donatur … orang" di web sebenarnya jumlah transaksi) dan `per_operator.total` untuk `hari`/`semua`. Bedanya: web menampilkan operator dengan 0, dan tidak menghitung user terhapus. |
| `rekapalloperator` | `per_hari` untuk `bulan`/`semua` |
| `rekapbulanan` | `donatur` dan `total` untuk `bulan`/`semua` |

### 6.10 `gantipassword` — POST

| Field | Tipe | Aturan |
|---|---|---|
| `lama` | string | wajib |
| `baru` | string | wajib, ≥ 8 karakter |
| `ulang` | string | wajib, sama dengan `baru` |

Server memeriksa berurutan dan berhenti pada galat pertama:

| # | Pemeriksaan | Status | `kode` | Pesan atau `rincian` |
|---|---|---|---|---|
| 1 | Migrasi M1 belum dijalankan di server | 409 | `fitur_belum_tersedia` | "Ganti password belum bisa dipakai karena migrasi M1 belum dijalankan. Hubungi admin." |
| 2 | Sedang terkunci | 429 | `login_terkunci` | `sisa_detik` ikut dikirim |
| 3 | `lama` salah (ikut menambah penghitung penguncian login) | 422 | `tidak_valid` | `rincian.lama` = "Password lama salah." |
| 4 | `baru` < 8 karakter | 422 | `tidak_valid` | `rincian.baru` = "Password baru minimal 8 karakter." |
| 5 | `ulang` berbeda | 422 | `tidak_valid` | `rincian.ulang` = "Ulangan password baru tidak sama." |
| 6 | `baru` sama dengan `lama` | 422 | `tidak_valid` | `rincian.baru` = "Password baru harus berbeda dari password lama." |

Jawaban 200: `{ "ok": true, "data": { "token": "…", "kedaluwarsa": "…" } }`

- Semua token lama pengguna ini, termasuk yang dipakai untuk permintaan ini, langsung batal. Klien mengganti token yang tersimpan dengan token baru.
- Aksi ini **tidak** memakai kunci kirim ulang, karena jawabannya berisi token dan tidak boleh disimpan di server. Bila koneksi putus setelah mengirim, klien meminta pengguna masuk ulang: coba password baru dulu, lalu password lama.

## 7. Kirim ulang aman (`Idempotency-Key`)

Berlaku untuk `tambahdonasi`, `tambahdonatur`, dan `ubahdonasi`.

| Aturan | Isi |
|---|---|
| Header | `Idempotency-Key: <kunci>`, 8–64 karakter `[A-Za-z0-9-]`; disarankan UUID v4. Tidak ada atau salah bentuk → 400 `permintaan_salah`. |
| Membuat kunci | Klien membuat kunci **baru** setiap kali pengguna menekan Simpan. Kiriman `konfirmasi: true` setelah 409 juga memakai kunci baru. |
| Memakai ulang kunci | Kunci yang **sama** hanya dipakai untuk mengirim ulang isi yang persis sama setelah timeout atau putus jaringan. |
| Cakupan | Per pengguna dan per aksi; disimpan server selama 24 jam |
| Yang disimpan | Hanya jawaban 2xx. Galat (4xx/5xx) tidak disimpan, sehingga kiriman ulang dengan kunci yang sama setelah galat diproses ulang. |
| Kunci sama, isi sama | Server memutar ulang jawaban 2xx pertama (status dan isi yang sama, ditambah `"ulang": true`) tanpa menyimpan baris baru |
| Kunci sama, isi berbeda | 409 `kunci_ulang_bentrok` |
| Kiriman bersamaan | Dua permintaan dengan kunci sama yang datang bersamaan diproses berurutan, sehingga tetap hanya satu baris |

## 8. Katalog kode galat

| Status | `kode` | Arti | Tindakan klien |
|---|---|---|---|
| 400 | `permintaan_salah` | Isi bukan JSON objek, atau `Idempotency-Key` hilang/salah bentuk | Bug klien; catat di log debug, tampilkan pesan umum |
| 401 | `token_tidak_sah` | Token tidak ada, rusak, tanda tangan salah, atau tidak berlaku lagi | Hapus token, buka layar Masuk; isian layar asal dipulihkan setelah masuk |
| 401 | `token_kedaluwarsa` | Masa berlaku token habis. Pesan: "Sesi berakhir. Silakan masuk lagi." | Sama dengan `token_tidak_sah` |
| 401 | `akun_nonaktif` | Akun tidak lagi admin/operator. Pesan: "Akun Anda tidak aktif. Hubungi admin." | Hapus token, tampilkan pesan di layar Masuk |
| 401 | `login_gagal` | Hanya pada `login` | Tampilkan `pesan` |
| 403 | `tidak_berhak` | Aturan K6 pada `ubahdonasi` | Tampilkan `pesan` |
| 404 | `aksi_tidak_ada` | Nilai `aksi` tidak dikenal atau tidak ada | Bug klien atau versi tidak cocok |
| 404 | `tidak_ada` | Donatur atau sumbangan tidak ada | Tampilkan `pesan` |
| 405 | `metode_salah` | Metode HTTP tidak sesuai aksi | Bug klien |
| 409 | `perlu_konfirmasi` | K5 atau K9 | Dialog berisi `alasan` dengan tombol **Ya, simpan** / **Tidak**. Ya mengirim ulang isi yang sama dengan `konfirmasi: true` dan kunci baru. |
| 409 | `donatur_sudah_ada` | Duplikat persis pada `tambahdonatur` | Tampilkan `id_donatur`, dengan pilihan "Input sumbangan untuk nomor ini" |
| 409 | `kunci_ulang_bentrok` | `Idempotency-Key` dipakai untuk isi yang berbeda | Bug klien; buat kunci baru |
| 409 | `fitur_belum_tersedia` | `gantipassword` di server tanpa M1 | Tampilkan `pesan` |
| 413 | `terlalu_besar` | Isi permintaan > 16 KB | Bug klien |
| 415 | `tipe_tidak_didukung` | POST bukan `application/json` | Bug klien |
| 422 | `tidak_valid` | Isian salah; lihat `rincian` | Pesan di bawah tiap isian; isian tetap |
| 429 | `login_terkunci` | Penguncian login | "Coba lagi dalam N menit" dari `sisa_detik` |
| 500 | `galat_server` | Galat tak terduga (tercatat di log server, tanpa rincian ke klien) | Pesan umum dan tombol Coba lagi; isian tetap |
| 503 | `api_mati` | `APP_KEY` server kosong | "Layanan mobile belum diaktifkan di server." |
| — | (tanpa jawaban) | Timeout atau tanpa jaringan | Isian tetap; tombol Kirim ulang memakai kunci yang sama |

## 9. Versi dan perubahan kontrak

- **Versi kontrak** mengikuti SemVer dan dikirim di header `X-Api-Versi` serta `konfigurasi.versi_api`.
- **Pemeriksaan klien:** klien menyimpan versi kontrak yang dipakainya saat dibangun.
  - Selama versi 0.x, klien hanya mau bekerja dengan server bermayor dan berminor sama.
  - Mulai 1.0, klien mau bekerja bila mayornya sama dan minor server ≥ minor klien.
  - Bila tidak cocok, klien menampilkan "Versi aplikasi tidak cocok dengan server. Perbarui aplikasi."
- **Minor** (aditif): aksi baru, field jawaban baru, field permintaan opsional baru, atau `kode` galat baru yang tetap bisa ditangani lewat status HTTP-nya.
- **Mayor** (breaking): field dihapus atau diganti nama, makna atau tipe berubah, field opsional menjadi wajib, aturan validasi diperketat, atau status HTTP berubah. Perubahan ini butuh persetujuan pemilik.
- **Alur perubahan:**
  1. Ubah dokumen ini lebih dulu, termasuk nomor versi dan catatan perubahan di bawah.
  2. Minta persetujuan pemilik untuk perubahan mayor.
  3. Ubah server, beserta `tests/api.php`.
  4. Ubah klien.
  5. Uji keduanya.

  Kode tidak boleh mendahului kontrak.

## 10. Uji kepatuhan

| Sisi | Bukti | Lulus bila |
|---|---|---|
| Server | `php tests/api.php` (Fase 12): setiap aksi, setiap baris katalog §8 yang bisa dipicu, aturan §7, paritas rekap §6.9, dan tidak ada `Set-Cookie`/header CORS | mencetak LULUS dan sidik data sama di awal dan akhir |
| Server | `tests/instalasi.php`: `login` dan satu aksi bertoken di php -S, Apache + PHP-FPM, subfolder, `htaccess-root`, Nginx, dan HTTPS | header `Authorization` sampai ke PHP di semua skenario |
| Klien | `flutter test`: klien API dengan `MockClient` untuk setiap status/`kode` §8, pembacaan semua contoh JSON di dokumen ini, dan kunci kirim ulang (baru vs sama) | semua hijau |
| Klien | Mock server untuk klien tanpa server (opsional): Prism dari `openapi.yaml` bila dibuat, atau server lokal | — |

## 11. Catatan perubahan

| Versi | Tanggal | Perubahan |
|---|---|---|
| 0.1.0 | 10 Okt 2026 | Draf pertama dari `UPDATE_PLAN.md` Fase 12 dan `DOSIR_MDONATOR.md` §11, dengan rekomendasi T2 dan T4. Tambahan dari dosir: `navigasi` pada `rekap`, `lebih` pada `caridonatur`, `ringkasan_hari_ini` pada aksi tambah, `donatur` pada 409 `tambahdonasi`, kode `token_kedaluwarsa`, `akun_nonaktif`, `kunci_ulang_bentrok`, `fitur_belum_tersedia`, `terlalu_besar`, dan `tipe_tidak_didukung`, serta penyimpanan `tambahdonatur` yang atomik. |
