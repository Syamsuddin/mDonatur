// Layar Ganti Password (P6 docs/06_BUSINESS_PROCESS.md, docs/26_UI_CONVENTIONS.md §Layar → pola):
// formulir dari menu ⋮. Sukses menampilkan pesan di layar seperti Pengaturan; pengguna kembali lewat
// tombol kembali. Bila koneksi putus setelah mengirim, Sesi mendorong Masuk (P6.3) dan layar ini
// menutup dirinya, sehingga setelah masuk lagi pengguna kembali ke tab, bukan ke formulir ini.

import 'package:flutter/material.dart';

import '../state/ganti_password_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/latar_dasbor.dart';
import '../widget/panel_galat.dart';
import '../widget/tombol_utama.dart';

class LayarGantiPassword extends StatefulWidget {
  const LayarGantiPassword({super.key});

  @override
  State<LayarGantiPassword> createState() => _LayarGantiPasswordState();
}

class _LayarGantiPasswordState extends State<LayarGantiPassword> {
  late final GantiPasswordNotifier _notifier = GantiPasswordNotifier(SesiScope.baca(context));

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    await _notifier.kirim();
    if (!mounted || _notifier.status != StatusGantiPassword.putus) return;
    // Masuk sudah di atas layar ini; yang dibuang hanya rute layar ini.
    final rute = ModalRoute.of(context);
    if (rute != null && rute.isActive) Navigator.of(context).removeRoute(rute);
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Ganti Password')),
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) {
          final n = _notifier;
          final memuat = n.status == StatusGantiPassword.memuat;
          final labelTombol = switch (n.tombol) {
            TombolPanel.tidakAda => null,
            TombolPanel.cobaLagi => 'Coba lagi',
            TombolPanel.kirimUlang => 'Kirim ulang',
          };
          return LatarDasbor(
            isi: ListView(
              padding: const EdgeInsets.all(Jarak.tepiLayar),
              children: [
                _IsianPassword(
                  controller: n.lama,
                  label: 'Password Lama',
                  galat: n.galatLama,
                  aktif: !memuat,
                ),
                const SizedBox(height: Jarak.antarIsian),
                _IsianPassword(
                  controller: n.baru,
                  label: 'Password Baru',
                  galat: n.galatBaru,
                  aktif: !memuat,
                ),
                const SizedBox(height: Jarak.antarIsian),
                _IsianPassword(
                  controller: n.ulang,
                  label: 'Ulangi Password Baru',
                  galat: n.galatUlang,
                  aktif: !memuat,
                  padaKirim: _simpan,
                ),
                if (n.status == StatusGantiPassword.sukses) ...[
                  const SizedBox(height: Jarak.j8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Password berhasil diganti.',
                      style: teks.bodyMedium!.copyWith(color: Warna.teksSukses),
                    ),
                  ),
                ],
                if (n.status == StatusGantiPassword.gagal && n.pesanPanel != null) ...[
                  const SizedBox(height: Jarak.antarIsian),
                  PanelGalat(
                    pesan: n.pesanPanel!,
                    labelTombol: labelTombol,
                    padaTombol: memuat ? null : _simpan,
                  ),
                ],
                const SizedBox(height: Jarak.antarIsian),
                TombolUtama(
                  onPressed: memuat ? null : _simpan,
                  child: memuat ? const IndikatorTombol() : const Text('Simpan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Isian password: tersamar, tanpa saran keyboard, dan tanpa autofill (sama dengan layar Masuk),
/// supaya Android tidak menawarkan menyimpan password (docs/21_SECURITY_RULES.md).
class _IsianPassword extends StatelessWidget {
  const _IsianPassword({
    required this.controller,
    required this.label,
    required this.galat,
    required this.aktif,
    this.padaKirim,
  });

  final TextEditingController controller;
  final String label;
  final String? galat;
  final bool aktif;

  /// Isian terakhir: tombol Selesai di keyboard menyimpan.
  final VoidCallback? padaKirim;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: aktif,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: null,
      textInputAction: padaKirim == null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: padaKirim == null ? null : (_) => padaKirim!(),
      decoration: InputDecoration(labelText: label, errorText: galat),
    );
  }
}
