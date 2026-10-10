# 27 — API_CONTRACT

## Peran paket dan kontrak

| Butir | Isi |
|---|---|
| Peran paket | **frontend** (klien Flutter). Server ada di repo root dan diatur `../UPDATE_PLAN.md` Fase 12 |
| Kontrak | `API_CONTRACT.md` di folder ini: rumah tunggal alamat, aksi, isi permintaan dan jawaban, amplop, kode galat, kirim ulang aman, dan aturan versi |
| Versi terpin | `0.1.0`. Sama dengan `split.contract_version` di `docs/_MANIFEST.json` dan `const versiKontrak` di `lib/api/klien_api.dart` |
| `openapi.yaml` | Tidak ada (keputusan 10 Okt 2026). 10 aksi berbagi satu path `/api?aksi=`, sedangkan OpenAPI tidak mengizinkan query string di kunci path. Karena itu tidak ada codegen, Prism, maupun `validate-kontrak.sh` |

## Presedensi

Kontrak menang (kontrak §1).

- Server tidak sesuai kontrak = bug server.
- Klien berasumsi di luar kontrak = bug klien.
- Kontrak keliru atau kurang → berhenti, laporkan, dan tunggu keputusan pemilik sebelum mengubah kode.

## Alur perubahan kontrak

1. Ubah `API_CONTRACT.md` lebih dulu: versi SemVer dan catatan perubahan (kontrak §9, §11). Setiap perubahan butuh gerbang manusia (docs/22_CHANGE_POLICY.md).
2. Server di repo root mengikuti, beserta `tests/api.php`.
3. Klien mengikuti dalam satu perubahan:
   - perbarui `split.contract_version` di manifest;
   - perbarui `versiKontrak`;
   - perbarui `lib/api/model.dart` dan `klien_api.dart`;
   - pastikan `test/api/kontrak_test.dart` hijau.
4. `flutter test` hijau dan `php tests/api.php` LULUS.

## Perintah sisi klien

| Tujuan | Perintah |
|---|---|
| Kepatuhan kontrak (tanpa server) | `flutter test test/api/` |
| Server palsu | Tidak ada. Uji memakai `MockClient`; demo memakai server lokal (docs/11_COMMANDS.md) |
| Kepatuhan sisi server **(root)** | `php tests/api.php` |

## Larangan

- Mengetik nama field JSON di luar `lib/api/model.dart`, atau nama aksi di luar `lib/api/klien_api.dart`.
- Memakai aksi, field, header, atau kode galat yang tidak ada di kontrak versi terpin.
- Mengandalkan perilaku server yang tidak tertulis di kontrak (mis. urutan field, isi `pesan`, field yang tidak dijamin).

## Celah kontrak yang diketahui

- [TERBUKA T17] Tidak ada aksi yang mengembalikan `RingkasanHariIni` saat layar Input dibuka. Usulan minor 0.2.0: `konfigurasi` ikut membawa `ringkasan_hari_ini`. Sejak strip satu baris (keputusan pemilik 10 Okt 2026) layar tidak lagi membutuhkannya, karena `donasisaya` sudah memberi total dan banyaknya input.
