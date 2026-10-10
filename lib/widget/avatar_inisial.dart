// Avatar inisial (docs/26_UI_CONVENTIONS.md, Avatar): lingkaran primer 40 dp berisi huruf pertama dua
// kata pertama nama, Outfit 800 warna aksen. Hiasan saja: tidak dibacakan, karena namanya tertulis
// di sebelahnya.

import 'package:flutter/material.dart';

import '../tema.dart';

/// "Fulan bin Fulan" → "FB"; kata yang tidak diawali huruf atau angka dilewati.
String inisialNama(String nama) {
  final awalan = RegExp(r'[A-Za-z0-9]');
  final huruf = [
    for (final kata in nama.trim().split(RegExp(r'\s+')))
      if (kata.isNotEmpty && awalan.hasMatch(kata[0])) kata[0].toUpperCase(),
  ];
  return huruf.take(2).join();
}

class AvatarInisial extends StatelessWidget {
  const AvatarInisial(this.nama, {super.key});

  final String nama;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: Bentuk.avatar,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Warna.primer, shape: BoxShape.circle),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Jarak.j4),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(inisialNama(nama), style: Huruf.inisial.copyWith(color: Warna.aksen)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
