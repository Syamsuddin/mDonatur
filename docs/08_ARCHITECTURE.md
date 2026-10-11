# 08 — ARCHITECTURE

```text
mDonator (Android, folder ini)                                Server Donatur (repo root, ../UPDATE_PLAN.md Fase 12)
lib/layar/* ─► lib/state/*_notifier.dart ─► lib/api/klien_api.dart ══HTTP(S)══► public/index.php → app/halaman/api.php
 (widget)       (ChangeNotifier per layar)   (http, Bearer, Idempotency-Key)      → app/api/<aksi>.php → app/donasi.php
                lib/state/sesi.dart ◄──► flutter_secure_storage                    (logika bersama web + API)
```

## Lapisan

| Lapisan | Tanggung jawab | Dilarang |
|---|---|---|
| `lib/layar/` | Menampilkan state, mengambil isian, navigasi | Memanggil `http`; aturan bisnis; warna atau ukuran literal |
| `lib/widget/` | Komponen bersama (inventaris di docs/26_UI_CONVENTIONS.md) | Memanggil API |
| `lib/state/` | `Sesi` global, ditambah satu `ChangeNotifier` per layar ber-data. Memegang isian, status (kosong/memuat/gagal/sukses), hasil, dan kunci kirim ulang yang tertunda | Mengurai JSON |
| `lib/api/` | Satu `KlienApi`: alamat, header, timeout, amplop → model atau galat (docs/14_ERROR_HANDLING.md), cek `X-Api-Versi`. `model.dart` berisi `fromJson`/`toJson` | State UI; mengulang POST otomatis |
| `lib/util/` | Format rupiah dan tanggal; pembuatan kunci UUID v4 | — |
| `lib/tema.dart` | `ThemeData` dan konstanta token dari docs/26_UI_CONVENTIONS.md | — |

## Kabel antarlapisan

- **Sesi**
  - `Sesi` (ChangeNotifier) disediakan di akar lewat `SesiScope` (`InheritedNotifier`).
  - `Sesi` membuat `KlienApi` dari alamat server dan token, lalu memberinya callback `padaTidakSah`.
- **Notifier per layar**
  - Setiap notifier layar menerima `KlienApi` lewat konstruktor, sehingga bisa diuji dengan `MockClient`.
- **Alur 401 tanpa kehilangan isian**
  - Layar `Kerangka` (AppBar, `NavigationBar` 4 tab, `IndexedStack`) memegang state keempat tab.
  - Setiap 401 selain dari `login` memanggil `padaTidakSah`. `Sesi` lalu menghapus token dan mendorong layar Masuk (layar penuh, tanpa tombol kembali) di atas Kerangka.
  - Setelah masuk berhasil, layar Masuk ditutup dan state tab tetap utuh.

## Keputusan arsitektural

| Keputusan | Alasan |
|---|---|
| Flutter native, Android dulu | K12, K19 |
| Aturan bisnis hanya di server; klien menampilkan hasil | Kontrak §1: web dan mobile tidak boleh punya dua salinan aturan K5, K6, K9, Note, bintang, saran, rekap |
| Klien API ditulis tangan dari `API_CONTRACT.md`, tanpa codegen | Keputusan 10 Okt 2026: semua aksi berbagi satu path `/api?aksi=`, yang tidak bisa dinyatakan OpenAPI. Aksinya kecil |
| `ChangeNotifier` + `InheritedNotifier`, tanpa paket state | 10 layar; dependensi minimal |
| `Navigator` bawaan, `NavigationBar` + `IndexedStack` | Isian setiap tab tetap saat berpindah tab |
| "Hari ini" dari `konfigurasi.hari_ini` | Jam HP bisa salah; data dicap jam server |
| Tanpa offline; POST tidak diulang otomatis | Data uang tidak boleh antre di HP atau tersimpan ganda. Kirim ulang manual memakai kunci yang sama |
| Alamat server bisa diatur | Server bisa dipasang di domain atau subfolder mana pun |
| Tanpa telemetri pihak ketiga | Data donatur tidak boleh keluar dari server yayasan (A3) |

**Integrasi eksternal:** tidak ada, selain server Donatur.
