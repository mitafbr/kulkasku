import 'dart:async';

import 'package:flutter/material.dart';

import '../data/katalog.dart';
import '../data/logic.dart';
import '../data/models.dart';
import '../services/kalender.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Form tambah sayur/buah. Kalau [ubah] diisi, form dipakai untuk mengedit.
class FormBahanPage extends StatefulWidget {
  final Bahan? ubah;
  const FormBahanPage({super.key, this.ubah});
  @override
  State<FormBahanPage> createState() => _FormBahanPageState();
}

class _FormBahanPageState extends State<FormBahanPage> {
  late String _kat;
  late String _grup;
  String _cari = '';
  late String _jenis;
  late String _tempat;
  late double _jumlah;
  late DateTime _beli;
  late int _awet;
  bool _namaDiubah = false;
  bool _memuat = false;
  late final TextEditingController _nama;
  String? _error;

  bool get _edit => widget.ubah != null;

  @override
  void initState() {
    super.initState();
    final b = widget.ubah;
    if (b != null) {
      _kat = b.kat;
      _jenis = b.jenis;
      _tempat = b.tempat;
      _jumlah = b.jumlah;
      _beli = b.beli;
      _awet = b.awet;
      _nama = TextEditingController(text: b.nama);
      _namaDiubah = true;
      _grup = Katalog.info(b.jenis).grup;
    } else {
      final awal = Katalog.info('bayam');
      _kat = awal.kat;
      _jenis = awal.id;
      _tempat = awal.tempat;
      _jumlah = 1;
      _beli = hariIni();
      _awet = awal.awet;
      _nama = TextEditingController(text: awal.label);
      _grup = awal.grup;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _pilihJenis(SayurInfo j) {
    setState(() {
      _jenis = j.id;
      _kat = j.kat;
      if (j.grup.isNotEmpty) _grup = j.grup;
      _tempat = j.tempat;
      _jumlah = j.satuan == 'gram' ? 250 : 1;
      if (!_namaDiubah) _nama.text = j.label;
      _awetOtomatis();
    });
  }

  void _awetOtomatis() {
    final j = Katalog.info(_jenis);
    _awet = (j.awet * (_tempat == 'freezer' ? 3 : 1)).clamp(1, 60).toInt();
  }

  Future<void> _pilihTanggal() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _beli,
      firstDate: tambahHari(hariIni(), -60),
      lastDate: hariIni(),
      helpText: 'Tanggal beli',
    );
    if (d != null) setState(() => _beli = DateTime(d.year, d.month, d.day));
  }

  Future<void> _simpan() async {
    final nama = _nama.text.trim();
    if (nama.length < 2) {
      setState(() => _error = 'Nama minimal 2 huruf');
      return;
    }
    setState(() {
      _error = null;
      _memuat = true;
    });
    final info = Katalog.info(_jenis);
    final b = Bahan(
      id: widget.ubah?.id ?? '',
      nama: nama,
      jenis: _jenis,
      kat: info.kat,
      jumlah: _jumlah,
      satuan: info.satuan,
      tempat: _tempat,
      beli: _beli,
      awet: _awet,
    );
    try {
      if (_edit) {
        await AppState.i.ubahBahan(b);
        if (!mounted) return;
        toast(context, 'Data $nama diperbarui. Pengingat ikut disesuaikan.', ikon: 'centang');
      } else {
        final baru = await AppState.i.tambahBahan(b);
        if (!mounted) return;
        final m = ScaffoldMessenger.of(context);
        m.hideCurrentSnackBar();
        final notif = m.showSnackBar(SnackBar(
          duration: const Duration(seconds: 5),
          content: Row(children: [
            Emo(_jenis, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text('$nama masuk ${_tempat == 'freezer' ? 'freezer' : 'kulkas'}!', style: AppText.body(14, color: Colors.white))),
          ]),
          action: AppState.i.user?.kalender == true
              ? SnackBarAction(label: 'Ke Kalender', textColor: AppColors.leafLight, onPressed: () => simpanKeKalender(baru))
              : null,
        ));
        // SnackBar yang punya tombol tidak hilang sendiri di Flutter versi baru,
        // jadi ditutup otomatis setelah 5 detik.
        var tertutup = false;
        notif.closed.then((_) => tertutup = true);
        Timer(const Duration(seconds: 5), () {
          if (!tertutup) notif.close();
        });
      }
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _memuat = false;
        _error = 'Gagal menyimpan: $e';
      });
    }
  }

  Future<void> _hapus() async {
    final b = widget.ubah!;
    final ok = await konfirmasi(context,
        judul: 'Hapus ${b.nama}?', isi: 'Dipakai kalau salah input. Tidak tercatat di riwayat.', ya: 'Hapus', ikon: 'sampah');
    if (!ok) return;
    await AppState.i.hapusBahan(b);
    if (!mounted) return;
    toast(context, '${b.nama} dihapus dari kulkas', ikon: 'sampah');
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final info = Katalog.info(_jenis);
    final bayangan = Bahan(
      id: 'x',
      nama: _nama.text,
      jenis: _jenis,
      kat: _kat,
      jumlah: _jumlah,
      satuan: info.satuan,
      tempat: _tempat,
      beli: _beli,
      awet: _awet,
    );
    final aE = Hitung.awetEfektif(bayangan);
    final layu = Hitung.tanggalLayu(bayangan);
    final h1 = tambahHari(layu, -1);
    final h0 = hariIni();
    final u = AppState.i.user;
    final jam = (u?.jam ?? '07:00').replaceAll(':', '.');
    final grupList = Katalog.grupDari(_kat);
    if (!grupList.contains(_grup) && grupList.isNotEmpty) _grup = grupList.first;
    final pilihan = _cari.trim().isNotEmpty
        ? Katalog.cari(_cari)
        : (grupList.isEmpty ? Katalog.kategori(_kat) : Katalog.diGrup(_grup));

    return Scaffold(
      body: IsiTengah(maxWidth: 640, child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Row(children: [
              const TombolKembali(),
              Expanded(
                child: Text(_edit ? 'EDIT ISI KULKAS' : 'TAMBAH SAYUR / BUAH', textAlign: TextAlign.center, style: AppText.label()),
              ),
              const SizedBox(width: 46),
            ]),
            const SizedBox(height: 10),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 150,
                height: 150,
                decoration: BoxDecoration(color: info.tint, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
                  child: Melayang(key: ValueKey(_jenis), child: Emo(_jenis, size: 116)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text(_edit ? 'Ubah datanya' : 'Mau simpan apa?', style: AppText.display(32))),
            const SizedBox(height: 14),
            Wrap(alignment: WrapAlignment.center, runSpacing: 8, children: [
              for (final k in const [('Sayur', 'brokoli'), ('Buah', 'apel'), ('Lainnya', 'telur')]) ...[
                LeafChip(
                  label: k.$1,
                  ikon: k.$2,
                  aktif: _kat == k.$1 && _cari.isEmpty,
                  onTap: () {
                    final g = Katalog.grupDari(k.$1);
                    final isi = g.isEmpty ? Katalog.kategori(k.$1) : Katalog.diGrup(g.first);
                    setState(() {
                      _cari = '';
                      _kat = k.$1;
                      if (g.isNotEmpty) _grup = g.first;
                    });
                    if (isi.isNotEmpty) _pilihJenis(isi.first);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ]),
            const SizedBox(height: 12),
            // cari langsung, contoh: "blueberry", "kangkung", "jahe"
            TextField(
              onChanged: (v) => setState(() => _cari = v),
              decoration: InputDecoration(
                hintText: 'Cari ${Katalog.semua.length}+ bahan… (mis. blueberry, ayam, susu)',
                prefixIcon: const Padding(padding: EdgeInsets.all(10), child: Emo('kaca', size: 22)),
              ),
            ),
            const SizedBox(height: 10),
            // grup: Sayur daun, Umbi & akar, Buah beri, dst.
            if (_cari.trim().isEmpty && grupList.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: grupList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final g = grupList[i];
                    final aktif = g == _grup;
                    return JellyTap(
                      onTap: () => setState(() => _grup = g),
                      semantik: g,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: aktif ? AppColors.leaf : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: aktif ? AppColors.leaf : AppColors.line),
                        ),
                        child: Text('$g · ${Katalog.diGrup(g).length}',
                            style: AppText.body(12.5, color: aktif ? Colors.white : AppColors.ink, weight: FontWeight.w800, height: 1.0)),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            if (pilihan.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Belum ada di katalog. Pilih yang paling mirip, lalu ubah namanya di kolom Nama.',
                    textAlign: TextAlign.center, style: AppText.body(12.5, color: AppColors.muted)),
              )
            else
              SizedBox(
                // dua baris pilihan, geser ke samping
                height: 204,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pilihan.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 80,
                  ),
                  itemBuilder: (_, i) {
                    final j = pilihan[i];
                    final aktif = j.id == _jenis;
                    return JellyTap(
                      onTap: () => _pilihJenis(j),
                      semantik: j.label,
                      child: Column(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: j.tint,
                            borderRadius: leafRadius(22),
                            border: Border.all(color: aktif ? AppColors.leaf : Colors.transparent, width: 3),
                          ),
                          alignment: Alignment.center,
                          child: Emo(j.id, size: 44),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          j.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppText.body(10.5, weight: aktif ? FontWeight.w900 : FontWeight.w700, height: 1.1),
                        ),
                      ]),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _cari.trim().isNotEmpty ? '${pilihan.length} hasil untuk "${_cari.trim()}"' : '${pilihan.length} pilihan · geser ke samping untuk melihat semua',
                style: AppText.body(11, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 14),
            Text('Nama', style: AppText.body(13, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            TextField(
              controller: _nama,
              onChanged: (_) => setState(() => _namaDiubah = true),
              decoration: InputDecoration(
                prefixIcon: const Padding(padding: EdgeInsets.all(10), child: Emo('pensil', size: 22)),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 14),
            Text('Simpan di mana?', style: AppText.body(13, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(children: [
              for (final t in tempatLabel.entries) ...[
                Expanded(
                  child: JellyTap(
                    onTap: () => setState(() {
                      _tempat = t.key;
                      _awetOtomatis();
                    }),
                    semantik: t.value,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _tempat == t.key ? AppColors.leaf : Colors.white,
                        borderRadius: leafRadius(20),
                        border: Border.all(color: _tempat == t.key ? AppColors.leaf : AppColors.line),
                      ),
                      child: Column(children: [
                        Emo(tempatIkon[t.key]!, size: 24),
                        const SizedBox(height: 4),
                        Text(t.value,
                            textAlign: TextAlign.center,
                            style: AppText.body(11, color: _tempat == t.key ? Colors.white : AppColors.ink, weight: FontWeight.w800)),
                      ]),
                    ),
                  ),
                ),
                if (t.key != 'pintu') const SizedBox(width: 8),
              ],
            ]),
            const SizedBox(height: 14),
            Text('Jumlah', style: AppText.body(13, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.line)),
              child: Row(children: [
                RoundBtn(
                  size: 44,
                  warna: AppColors.lettuce,
                  semantik: 'Kurangi',
                  onTap: () => setState(() {
                    final l = info.satuan == 'gram' ? 50.0 : 1.0;
                    _jumlah = (_jumlah - l).clamp(l, 99999).toDouble();
                  }),
                  child: Text('−', style: AppText.body(22, color: AppColors.leaf, weight: FontWeight.w900)),
                ),
                Expanded(
                  child: Text(bayangan.jumlahTeks, textAlign: TextAlign.center, style: AppText.body(17, weight: FontWeight.w900)),
                ),
                RoundBtn(
                  size: 44,
                  warna: AppColors.lettuce,
                  semantik: 'Tambah',
                  onTap: () => setState(() => _jumlah += info.satuan == 'gram' ? 50 : 1),
                  child: Text('+', style: AppText.body(22, color: AppColors.leaf, weight: FontWeight.w900)),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Text('Tanggal beli', style: AppText.body(13, weight: FontWeight.w800)),
            const SizedBox(height: 6),
            JellyTap(
              onTap: _pilihTanggal,
              semantik: 'Pilih tanggal beli',
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                child: Row(children: [
                  const Emo('keranjang', size: 24),
                  const SizedBox(width: 10),
                  Expanded(child: Text('${namaHari(_beli)}, ${tgl(_beli)} ${_beli.year}', style: AppText.body(15, weight: FontWeight.w800))),
                  const Emo('kalender', size: 22),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: leafRadius(30)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  FreshRing(nilai: aE / 30, warna: AppColors.leafLight, size: 58, tebal: 6, label: '${aE}h', warnaLabel: Colors.white),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('DIHITUNG OTOMATIS', style: AppText.label(color: AppColors.leafLight, size: 10)),
                      Text('Layu sekitar ${tglHari(layu)}', style: AppText.body(15, color: Colors.white, weight: FontWeight.w900)),
                      Text('Beli ${tglHari(_beli)} + $aE hari (${tempatLabel[_tempat]!.toLowerCase()}, ${formatSuhu(_tempat == 'freezer' ? Hitung.suhuFz : Hitung.suhuKl)})',
                          style: AppText.body(12, color: const Color(0xFFC9D6BE), weight: FontWeight.w600)),
                    ]),
                  ),
                ]),
                const Divider(color: Color(0xFF3A4A33), height: 22),
                if (!h1.isBefore(h0)) _info('lonceng', 'Notifikasi ${tglHari(h1)} jam $jam (H-1)'),
                _info('jam', layu.isBefore(h0) ? 'Tanggal ini sudah lewat masa segar' : 'Notifikasi ${tglHari(layu)} jam $jam (hari-H)'),
                if (u?.kalender == true) _info('kalender', 'Bisa disimpan ke Kalender HP setelah ditambahkan'),
                const SizedBox(height: 4),
                Text('Geser kalau perkiraannya kurang pas', style: AppText.body(11, color: const Color(0xFFC9D6BE))),
                Slider(
                  value: _awet.clamp(1, 60).toDouble(),
                  min: 1,
                  max: 60,
                  divisions: 59,
                  activeColor: AppColors.carrot,
                  label: '$_awet hari',
                  onChanged: (v) => setState(() => _awet = v.round()),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            ChunkyButton(
              label: _edit ? 'Simpan perubahan' : 'Masukkan ke kulkas',
              ikon: _edit ? 'centang' : 'kulkas',
              warna: AppColors.carrot,
              bayangan: AppColors.carrotDark,
              memuat: _memuat,
              onTap: _simpan,
            ),
            if (_edit) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _hapus,
                  icon: const Emo('sampah', size: 18),
                  label: Text('Hapus dari kulkas (salah input)', style: AppText.body(13, color: AppColors.tomatoDark)),
                ),
              ),
            ],
          ],
        ),
      )),
    );
  }

  Widget _info(String ikon, String teks) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Emo(ikon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(teks, style: AppText.body(12.5, color: const Color(0xFFE3EAD9), weight: FontWeight.w600))),
        ]),
      );
}
