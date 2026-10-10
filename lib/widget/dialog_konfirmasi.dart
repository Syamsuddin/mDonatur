// Dialog konfirmasi (docs/26_UI_CONVENTIONS.md §Inventaris): judul, nama donatur bila ada, daftar
// alasan, TextButton Tidak + FilledButton Ya, simpan. Dipakai juga untuk dialog Keluar (P7).

import 'package:flutter/material.dart';

import '../tema.dart';

/// `true` bila [tombolYa] ditekan; `false` bila [tombolTidak] ditekan atau dialog ditutup.
Future<bool> tampilkanDialogKonfirmasi(
  BuildContext context, {
  String? judul,
  String? nama,
  required List<String> isi,
  String tombolTidak = 'Tidak',
  String tombolYa = 'Ya, simpan',
}) async {
  final ya = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: judul == null ? null : Text(judul),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nama != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Jarak.j8),
                child: Text(nama, style: Theme.of(context).textTheme.titleLarge),
              ),
            for (final (i, baris) in isi.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : Jarak.j8),
                child: Text(baris),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tombolTidak)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(tombolYa)),
      ],
    ),
  );
  return ya ?? false;
}
