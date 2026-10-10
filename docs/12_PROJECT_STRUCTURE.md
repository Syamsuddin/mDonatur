# 12 — PROJECT_STRUCTURE

```text
mDonator/                      root paket; perintah flutter dijalankan dari sini
├── CLAUDE.md · INDEX.md       inti agen dan router dokumen
├── API_CONTRACT.md            kontrak API (rumah tunggal alamat, aksi, payload)
├── DOSIR_MDONATOR.md          bahan asal blueprint; bila beda dengan docs/, docs menang
├── docs/                      00–27, _MANIFEST.json, _TOKEN_LEDGER.json
├── scripts/                   validate.sh, token_ledger.py (alat blueprint, bukan Flutter)
├── pubspec.yaml · pubspec.lock · analysis_options.yaml
├── assets/                    logo_yayasan.png (docs/26_UI_CONVENTIONS.md, Logo)
├── lib/
│   ├── main.dart              runApp, MaterialApp (locale id_ID), SesiScope, orientasi potret
│   ├── tema.dart              ThemeData + konstanta token 26: satu-satunya tempat Color(0x…), ukuran huruf, dan jarak
│   ├── api/
│   │   ├── klien_api.dart     KlienApi; const versiKontrak = '0.1.0'; nama aksi
│   │   ├── galat_api.dart     GalatApi, GalatJaringan, GalatVersi
│   │   └── model.dart         kelas permintaan dan jawaban (fromJson/toJson): satu-satunya tempat nama field JSON
│   ├── state/
│   │   ├── sesi.dart          Sesi + SesiScope (token, pengguna, konfigurasi, alamat server)
│   │   ├── kerangka_notifier.dart  tab aktif + pesan antartab (Donatur → Cek di tab Input, strip hari ini)
│   │   └── <layar>_notifier.dart   satu ChangeNotifier per layar ber-data
│   ├── layar/                 awal (gerbang P0, layar gagal dan blokir versi), masuk, kerangka,
│   │                          input_sumbangan, cari_donatur, tambah_donatur, input_saya,
│   │                          ubah_sumbangan, rekap, ganti_password, pengaturan (.dart)
│   ├── widget/                komponen bersama (inventaris: docs/26_UI_CONVENTIONS.md)
│   └── util/                  rupiah.dart, tanggal.dart, kunci.dart (UUID v4 dari Random.secure)
├── test/
│   ├── api/                   klien_api_test.dart, kontrak_test.dart
│   ├── util/                  rupiah_test.dart, tanggal_test.dart
│   └── layar/                 <layar>_test.dart; bantu.dart (server tiruan, secure storage tiruan, layar 360 dp)
├── integration_test/          alur_test.dart (opsional, server lokal)
└── android/                   applicationId com.kapuhmadani.mdonator; manifest: docs/21_SECURITY_RULES.md
                               ikon peluncur di res/mipmap-*, layar pembuka di res/drawable*/launch_background.xml
```

## Penamaan

| Unsur | Aturan | Contoh |
|---|---|---|
| Berkas Dart | `snake_case` | `input_sumbangan.dart` |
| Layar | `Layar` + nama | `LayarInputSumbangan` |
| Notifier | nama + `Notifier` | `InputSumbanganNotifier` di `lib/state/input_sumbangan_notifier.dart` |
| Kelas lain | `UpperCamelCase`; anggota `lowerCamelCase` | `KlienApi.tambahDonasi()` |
| Kata domain | bahasa Indonesia, sama dengan kontrak dan server | `donatur`, `sumbangan`, `jumlah`, `rekap` |
| Field Dart dari JSON | `lowerCamelCase` dari nama kontrak | `idDonatur` ← `id_donatur` |
| Paket Dart / applicationId | `mdonator` / `com.kapuhmadani.mdonator` | — |

## Lokasi jenis kode

- **HTTP** hanya di `lib/api/klien_api.dart`. **Nama field JSON** hanya di `lib/api/model.dart`.
- **Warna, ukuran huruf, jarak, dan radius** hanya di `lib/tema.dart`. Widget membaca dari `Theme.of(context)` atau dari konstanta di `tema.dart`.
- **Format rupiah dan tanggal** hanya lewat `lib/util/`. Widget tidak memanggil `NumberFormat` atau `DateFormat` langsung.
- **Teks UI** ditulis langsung dalam bahasa Indonesia di widget, tanpa berkas l10n. `pesan` dari server ditampilkan apa adanya.
- **Alamat server** tidak pernah tertanam di `lib/`. Asalnya hanya `SERVER_URL` dan Pengaturan.
