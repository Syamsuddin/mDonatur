# 18 — REPAIR_RULES

## Alur perbaikan bug

1. **Reproduksi.** Tulis uji yang gagal: `MockClient` untuk bug API atau state, uji widget untuk bug tampilan. Bila tidak bisa diuji otomatis, tulis langkah di emulator.
2. **Tentukan sisi.** Cocokkan jawaban server dengan `API_CONTRACT.md`.
   - Server menyimpang dari kontrak → bug server. Perbaiki di repo root mengikuti `../CLAUDE.md`, lalu `php tests/api.php` harus LULUS. **Jangan** menambal klien untuk menutupi bug server.
   - Klien berasumsi di luar kontrak → bug klien.
   - Kontraknya sendiri keliru atau kurang → berhenti, laporkan, dan tunggu keputusan pemilik (kontrak §1).
3. **Akar masalah,** lalu perbaikan minimal di lapisan yang benar (docs/08_ARCHITECTURE.md).
4. **Regresi.** Uji dari langkah 1 jadi hijau; `flutter analyze` dan `flutter test` bersih.

## Larangan

- Memperbaiki melebihi scope bug, atau refactor luas tanpa izin pemilik.
- Menghapus, melewati, atau melonggarkan uji agar hijau.
- Menambah aturan bisnis di Dart untuk menambal perilaku server (docs/20_GUARDRAILS.md).
