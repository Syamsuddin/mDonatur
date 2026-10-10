// Layar Masuk (P1 docs/06_BUSINESS_PROCESS.md, docs/26_UI_CONVENTIONS.md §Layar → pola): kepala
// primer berisi logo, nama yayasan (aksen), dan "mDonator", ikon Pengaturan, Username, Password, Masuk.
// Tampil sebagai layar awal tanpa token, atau didorong di atas kerangka saat 401 (lib/layar/awal.dart).

import 'package:flutter/material.dart';

import '../state/masuk_notifier.dart';
import '../state/sesi.dart';
import '../tema.dart';
import '../widget/kerangka_memuat.dart';
import '../widget/logo_yayasan.dart';
import '../widget/panel_galat.dart';
import 'pengaturan.dart';

/// Batas panjang isian `login` (API_CONTRACT.md §6.1).
const _panjangUsername = 50;
const _panjangPassword = 200;

class LayarMasuk extends StatefulWidget {
  const LayarMasuk({super.key});

  @override
  State<LayarMasuk> createState() => _LayarMasukState();
}

class _LayarMasukState extends State<LayarMasuk> {
  late final MasukNotifier _notifier = MasukNotifier(SesiScope.baca(context));

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: Theme.of(context).appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        body: ListenableBuilder(
          listenable: _notifier,
          builder: (context, _) {
            final n = _notifier;
            final memuat = n.status == StatusMasuk.memuat;
            final labelTombol = switch (n.tombol) {
              TombolPanel.tidakAda => null,
              TombolPanel.cobaLagi => 'Coba lagi',
              TombolPanel.kirimUlang => 'Kirim ulang',
            };
            return ListView(
              children: [
                const _Kepala(),
                Padding(
                  padding: const EdgeInsets.all(Jarak.tepiLayar),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // autofillHints null (bukan bawaan []) mematikan autofill: tanpa itu Android
                      // menawarkan menyimpan password ke pengelola password, padahal password tidak
                      // disimpan di perangkat (docs/21_SECURITY_RULES.md).
                      TextField(
                        controller: n.username,
                        enabled: !memuat,
                        maxLength: _panjangUsername,
                        buildCounter: _tanpaPenghitung,
                        autocorrect: false,
                        autofillHints: null,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: 'Username', errorText: n.galatUsername),
                      ),
                      const SizedBox(height: Jarak.antarIsian),
                      TextField(
                        controller: n.password,
                        enabled: !memuat,
                        maxLength: _panjangPassword,
                        buildCounter: _tanpaPenghitung,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        autofillHints: null,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => n.kirim(),
                        decoration: InputDecoration(labelText: 'Password', errorText: n.galatPassword),
                      ),
                      if (n.status == StatusMasuk.gagal && n.pesanPanel != null) ...[
                        const SizedBox(height: Jarak.antarIsian),
                        PanelGalat(
                          pesan: n.pesanPanel!,
                          labelTombol: labelTombol,
                          padaTombol: memuat ? null : n.kirim,
                        ),
                      ],
                      const SizedBox(height: Jarak.antarIsian),
                      FilledButton(
                        onPressed: memuat ? null : n.kirim,
                        child: memuat ? const IndikatorTombol() : const Text('Masuk'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static Widget? _tanpaPenghitung(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) =>
      null;
}

class _Kepala extends StatelessWidget {
  const _Kepala();

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return ColoredBox(
      color: Warna.primer,
      child: SafeArea(
        bottom: false,
        // Ikon Pengaturan sebaris dengan logo, supaya kepala tidak lebih tinggi daripada sebelum ada
        // logo dan tombol Masuk tetap terlihat di layar 360×640 dp dengan huruf 1,3.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Jarak.tepiLayar, Jarak.j16, Jarak.j4, Jarak.j24),
          child: Row(
            children: [
              const LogoYayasan(ukuran: Bentuk.logoKepala, alas: true),
              const SizedBox(width: Jarak.j12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Yayasan Ibnu Atha'illah",
                      style: teks.titleLarge!.copyWith(color: Warna.aksen),
                    ),
                    const SizedBox(height: Jarak.j4),
                    Text('mDonator', style: teks.bodyLarge!.copyWith(color: Warna.diAtasPrimer)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings),
                color: Warna.diAtasPrimer,
                tooltip: 'Pengaturan',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const LayarPengaturan()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
