// Kartu donatur (docs/26_UI_CONVENTIONS.md §Inventaris), bentuk ringkas agar layar Input muat tanpa
// digulir: avatar inisial dengan nama (judulKartu) dan lencana bintang di sebelahnya; "Alamat …" dan
// "No HP … · Keterangan …" selebar kartu; lalu "Riwayat {tahun}" dengan total tahun ini dan riwayat "dd/MM Rp jumlah" yang
// terlipat. Semua isi dari jawaban `donatur`; riwayat tampil apa adanya, tanpa dijumlah per bulan.
// Tanggal riwayat note_n (hanya untuk admin) tebal tanpa label (docs/26 §Token tipografi).

import 'package:flutter/material.dart';

import '../api/model.dart';
import '../tema.dart';
import '../util/rupiah.dart';
import '../util/tanggal.dart';
import 'avatar_inisial.dart';
import 'lencana_bintang.dart';
import 'muncul.dart';

class KartuDonatur extends StatelessWidget {
  const KartuDonatur({super.key, required this.donatur});

  final Donatur donatur;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    final lemah = teks.bodyMedium!.copyWith(color: Warna.teksLemah);
    final d = donatur;
    final kontak = [
      if (d.noHp.isNotEmpty) ('No HP', d.noHp),
      if (d.keterangan.isNotEmpty) ('Keterangan', d.keterangan),
    ];
    return Muncul(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Jarak.isiKartu),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarInisial(d.nama),
                  const SizedBox(width: Jarak.j12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.nama, style: teks.titleMedium),
                        LencanaBintang(bintang: d.bintang),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Jarak.j4),
              _Keterangan(bagian: [('Alamat', d.alamat)]),
              if (kontak.isNotEmpty) _Keterangan(bagian: kontak),
              const Divider(height: Jarak.j12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text('Riwayat ${d.tahun}', style: lemah)),
                  const SizedBox(width: Jarak.j8),
                  Flexible(
                    child: Text(
                      'Total ${formatRupiah(d.totalTahunIni)}',
                      style: teks.labelLarge!.copyWith(color: Warna.primer),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Jarak.j4),
              if (d.riwayat.isEmpty)
                Text('Belum ada sumbangan tahun ${d.tahun}.', style: lemah)
              else
                Wrap(
                  spacing: Jarak.j12,
                  runSpacing: Jarak.antarBarisRiwayat,
                  children: [
                    for (final r in d.riwayat)
                      Text.rich(TextSpan(children: [
                        TextSpan(
                          text: formatTanggalPendek(r.tanggal),
                          style: r.noteN ? lemah.merge(Huruf.penandaNote) : lemah,
                        ),
                        TextSpan(text: ' ${formatRupiah(r.jumlah)}'),
                      ])),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu baris "Label nilai · Label nilai"; label teksLemah.
class _Keterangan extends StatelessWidget {
  const _Keterangan({required this.bagian});

  final List<(String, String)> bagian;

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme.bodyMedium!;
    final lemah = teks.copyWith(color: Warna.teksLemah);
    return Text.rich(TextSpan(children: [
      for (final (i, (label, nilai)) in bagian.indexed) ...[
        if (i > 0) TextSpan(text: ' · ', style: lemah),
        TextSpan(text: '$label ', style: lemah),
        TextSpan(text: nilai, style: teks),
      ],
    ]));
  }
}
