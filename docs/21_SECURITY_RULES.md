# 21 — SECURITY_RULES

## Autentikasi dan otorisasi

- **Token.** Token dari `login` (kontrak §3) buram bagi klien: tidak diurai, hanya disimpan dan dikirim di header `Authorization: Bearer`. Token tidak pernah ditaruh di URL, query, atau log.
- **Kedaluwarsa.** `kedaluwarsa` hanya ditampilkan di Pengaturan. Sah atau tidaknya token diputuskan server (401). Klien tidak memeriksa kedaluwarsa dengan jam HP.
- **Hapus token** saat menerima 401 (selain dari `login`), saat Keluar, dan saat alamat server diganti.
- **Otorisasi** milik server (docs/05_USER_ROLE.md). Klien hanya menyembunyikan aksi menurut `boleh_ubah` dan peran.
- **Penguncian login** dipakai bersama web dan dihitung server. Klien tidak mencoba login ulang otomatis.

## Penyimpanan di perangkat

| Data | Tempat | Dihapus saat |
|---|---|---|
| Token, kedaluwarsa | `flutter_secure_storage` | 401, Keluar, ganti alamat server |
| Pengguna (id, username, peran) dan konfigurasi | memori saja, dari `konfigurasi` (docs/05_USER_ROLE.md); tidak disimpan di perangkat | Keluar, ganti alamat server. Setelah 401 di kerangka, konfigurasi dibiarkan agar isi tab tetap; masuk lagi menggantinya |
| Alamat server, username terakhir | `flutter_secure_storage` | tidak dihapus saat Keluar |
| Password | tidak pernah disimpan; isian dikosongkan setelah dikirim | — |
| Nama, alamat, No HP, dan riwayat donatur | memori layar saja | Keluar, atau layar ditutup |

## Transport

- **Build rilis:** `SERVER_URL` dan alamat di Pengaturan wajib `https`, dan cleartext dilarang. Tanpa certificate pinning, karena alamat server bisa diatur.
- **Build debug:** cleartext diizinkan hanya lewat `android/app/src/debug/AndroidManifest.xml` (`android:usesCleartextTraffic="true"`). Manifest `src/main` tidak boleh mengizinkannya.
- **`android/app/src/main/AndroidManifest.xml`:** wajib memuat `<uses-permission android:name="android.permission.INTERNET"/>` dan `android:allowBackup="false"`. Yang kedua mencegah token tersalin ke cadangan cloud dan galat dekripsi setelah dipulihkan.

## Masukan

- Klien hanya mengirim bilangan bulat untuk nomor dan nominal; isian angka hanya menerima digit.
- Panjang isian teks dibatasi `maxLength` sesuai batas kontrak §6.6.
- Validasi isi yang sebenarnya, termasuk Latin-1, dilakukan server.

## Rahasia

- Aplikasi tidak memuat rahasia apa pun. `APP_KEY` hanya ada di `.env` server.
- Pola `*.jks`, `*.keystore`, dan `key.properties` ditambahkan ke `.gitignore` buatan Flutter.

## Di luar MVP

`FLAG_SECURE` (pencegah tangkapan layar) tidak dipakai (T14).
