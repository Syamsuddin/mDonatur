// State kosong (docs/26_UI_CONVENTIONS.md §Inventaris): ikon tab layar itu 40 dp di atas teks, keduanya
// teksLemah, di tengah.

import 'package:flutter/material.dart';

import '../tema.dart';

class StateKosong extends StatelessWidget {
  const StateKosong(this.pesan, {super.key, required this.ikon});

  final String pesan;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Jarak.j24, horizontal: Jarak.tepiLayar),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Icon(ikon, size: Bentuk.ikonKosong, color: Warna.teksLemah)),
          const SizedBox(height: Jarak.j8),
          Text(
            pesan,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Warna.teksLemah),
          ),
        ],
      ),
    );
  }
}
