// Logo Yayasan Ibnu Atha'illah (docs/26_UI_CONVENTIONS.md, Logo). Bagian putih di dalam logo tembus
// pandang, jadi di atas `primer` logo memakai alas lingkaran `latar`.

import 'package:flutter/material.dart';

import '../tema.dart';

const asetLogoYayasan = 'assets/logo_yayasan.png';

class LogoYayasan extends StatelessWidget {
  const LogoYayasan({super.key, required this.ukuran, this.alas = false, this.label});

  /// Diameter logo dalam dp, dari [Bentuk].
  final double ukuran;

  /// Alas lingkaran `latar` selebar [ukuran] + 2 × [Jarak.j4], untuk latar `primer`.
  final bool alas;

  /// Label pembaca layar; null bila nama yayasan sudah tertulis di sebelahnya.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final gambar = Image.asset(
      asetLogoYayasan,
      width: ukuran,
      height: ukuran,
      semanticLabel: label,
      excludeFromSemantics: label == null,
    );
    if (!alas) return gambar;
    return DecoratedBox(
      decoration: const BoxDecoration(color: Warna.latar, shape: BoxShape.circle),
      child: Padding(padding: const EdgeInsets.all(Jarak.j4), child: gambar),
    );
  }
}
