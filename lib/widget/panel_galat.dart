// Panel galat (docs/26_UI_CONVENTIONS.md §Inventaris): kotak ber-border 1 dp teksBahaya, teks
// teksBahaya, dan tombol Coba lagi atau Kirim ulang. Pesan server tampil sebagai teks polos.

import 'package:flutter/material.dart';

import '../tema.dart';

class PanelGalat extends StatelessWidget {
  const PanelGalat({super.key, required this.pesan, this.labelTombol, this.padaTombol});

  final String pesan;

  /// "Coba lagi" atau "Kirim ulang"; tanpa label, panel tidak punya tombol.
  final String? labelTombol;
  final VoidCallback? padaTombol;

  @override
  Widget build(BuildContext context) {
    final gaya = Theme.of(context).textTheme.bodyMedium!.copyWith(color: Warna.teksBahaya);
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Jarak.j12),
        decoration: BoxDecoration(
          border: Border.all(color: Warna.teksBahaya, width: Bentuk.garisPemisah),
          borderRadius: BorderRadius.circular(Bentuk.radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pesan, style: gaya),
            if (labelTombol case final label?) ...[
              const SizedBox(height: Jarak.j8),
              OutlinedButton(onPressed: padaTombol, child: Text(label)),
            ],
          ],
        ),
      ),
    );
  }
}
