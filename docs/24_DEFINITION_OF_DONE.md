# 24 — DEFINITION_OF_DONE

Sebuah task atau slice selesai bila semua butir ini benar. Perintahnya di docs/11_COMMANDS.md.

**Kriteria dan uji klien**

- [ ] Kriteria fitur terkait di docs/23_ACCEPTANCE_CRITERIA.md terpenuhi.
- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → `All tests passed!`, tanpa uji yang dihapus, di-`skip`, atau dilonggarkan.
- [ ] "Cek warna literal", "Cek gradien dan huruf", "Cek `print`", dan "Cek alamat tertanam" → keluaran kosong.

**Server (bila slice punya bagian server)**

- [ ] `php tests/api.php` LULUS.
- [ ] Regresi web LULUS, termasuk HTML 129/129 SAMA.
- [ ] Sidik data identik.
- [ ] Tidak ada entri baru di `../storage/logs/php-error.log`.
- [ ] Skema DB tidak berubah.

**Demo dan kepatuhan**

- [ ] Alur slice didemokan di emulator terhadap server lokal.
- [ ] `pubspec.yaml` tidak menambah paket di luar docs/09_STACK.md.
- [ ] Tidak melanggar docs/20_GUARDRAILS.md maupun docs/21_SECURITY_RULES.md.

**Dokumen**

- [ ] Bila ada dokumen paket yang berubah: `docs/_MANIFEST.json` diperbarui dan `bash scripts/validate.sh` → `FAIL=0`.
- [ ] Bagian "Hasil uji" `../UPDATE_PLAN.md` Fase 12 mencatat slice ini.
- [ ] Fitur yang sudah diterima: blok kriterianya dipindah ke `docs/_archive/23-<fitur>.md`.
