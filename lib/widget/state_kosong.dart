// State kosong (docs/26_UI_CONVENTIONS.md §Inventaris): teks teksLemah di tengah.

import 'package:flutter/material.dart';

import '../tema.dart';

class StateKosong extends StatelessWidget {
  const StateKosong(this.pesan, {super.key});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Jarak.j24),
      child: Center(
        child: Text(
          pesan,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Warna.teksLemah),
        ),
      ),
    );
  }
}
