# 09 — STACK

| Lapisan | Teknologi | Versi |
|---|---|---|
| Klien | Flutter (stable) / Dart | 3.47.5 / 3.13.4 |
| Android | SDK platforms, build-tools, AVD `Pixel_5-Android_13` | android-28 s.d. android-36 |
| Build Android | JDK | 17.0.18 |
| Paket Dart | `http`, `flutter_secure_storage`, `intl` | dipin saat S0 oleh `flutter pub add` (versi terbaru yang cocok dengan Dart 3.13.4), tercatat di `pubspec.lock` |
| Paket SDK | `flutter_localizations`; dev: `flutter_test`, `integration_test`, `flutter_lints` | bawaan Flutter |
| State | `ChangeNotifier`, `InheritedNotifier` bawaan | — |
| Server (di luar paket) | PHP native, mysqli prosedural, tanpa Composer | 8.4 lokal / 8.x produksi |
| DB (milik server) | MySQL / MariaDB | 8.4 lokal / 10.11 produksi |

Empat paket Dart di atas sudah disetujui pemilik. Paket atau plugin lain harus lewat gerbang docs/22_CHANGE_POLICY.md.

## Terlarang

| Terlarang | Alasan |
|---|---|
| WebView yang membungkus halaman web | K12 memilih aplikasi native |
| Paket state management (bloc, riverpod, getx, provider, dsb.) | Layarnya sedikit; bawaan Flutter cukup |
| Paket router (go_router, auto_route, dsb.) | `Navigator` bawaan cukup untuk 10 layar |
| `dio`, `built_value`, codegen OpenAPI | Dependensi berat; klien ditulis tangan (docs/08_ARCHITECTURE.md) |
| SDK telemetri, analytics, atau crash reporting (Firebase dan sejenisnya) | Data donatur tidak boleh keluar dari server yayasan |
| Pustaka komponen UI di luar Material bawaan; font yang dibundel | Mencegah gaya campur aduk (docs/26_UI_CONVENTIONS.md) |
| `shared_preferences` atau berkas biasa untuk token | Token wajib di secure storage (docs/21_SECURITY_RULES.md) |
| `http://` di build rilis | Token dan data donatur lewat jaringan seluler |
| Framework PHP, Composer, dan tabel DB baru | Batasan pemilik untuk server (`../UPDATE_PLAN.md` §1) |
