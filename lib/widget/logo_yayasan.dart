// Logo Yayasan Ibnu Atha'illah (docs/26_UI_CONVENTIONS.md, Logo). Bagian putih di dalam logo tembus
// pandang, jadi di atas gradien kepala logo memakai alas lingkaran `latar`, bercincin `aksen`.

import 'package:flutter/material.dart';

import '../tema.dart';

const asetLogoYayasan = 'assets/logo_yayasan.png';

class LogoYayasan extends StatelessWidget {
  const LogoYayasan({super.key, required this.ukuran, this.alas, this.cincin = false, this.label});

  /// Diameter logo dalam dp, dari [Bentuk].
  final double ukuran;

  /// Diameter alas lingkaran `latar` ([Bentuk.alasLogoKepala] atau [Bentuk.alasLogoBar]), untuk latar
  /// gradien; `null` tanpa alas.
  final double? alas;

  /// Cincin `aksen` [Bentuk.cincinLogo] di luar alas.
  final bool cincin;

  /// Label pembaca layar; null bila nama yayasan sudah tertulis di sebelahnya atau logo hanya hiasan.
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
    final alas = this.alas;
    if (alas == null) return gambar;
    final tebalCincin = cincin ? Bentuk.cincinLogo : 0.0;
    return SizedBox.square(
      dimension: alas + 2 * tebalCincin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Warna.latar,
          shape: BoxShape.circle,
          border: cincin ? Border.all(color: Warna.aksen, width: Bentuk.cincinLogo) : null,
        ),
        child: Center(child: gambar),
      ),
    );
  }
}
