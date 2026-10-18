import 'package:flutter_test/flutter_test.dart';
import 'package:kulkasku/data/logic.dart';
import 'package:kulkasku/data/models.dart';

Bahan _bahan({required int lalu, required int awet, String tempat = 'rak'}) => Bahan(
      id: 't',
      nama: 'Sawi',
      jenis: 'bayam',
      kat: 'Sayur',
      jumlah: 1,
      satuan: 'ikat',
      tempat: tempat,
      beli: tambahHari(hariIni(), -lalu),
      awet: awet,
    );

void main() {
  setUp(() {
    Hitung.suhuKl = 4;
    Hitung.suhuFz = -18;
  });

  test('tanggal layu = tanggal beli + umur simpan', () {
    final b = _bahan(lalu: 1, awet: 4);
    expect(Hitung.sisaHari(b), 3);
    expect(Hitung.status(b), Status.segar);
  });

  test('status hampir layu dan basi', () {
    expect(Hitung.status(_bahan(lalu: 3, awet: 4)), Status.layu);
    expect(Hitung.status(_bahan(lalu: 6, awet: 4)), Status.basi);
  });

  test('kulkas lebih hangat membuat sayur lebih cepat layu', () {
    final b = _bahan(lalu: 0, awet: 10);
    final normal = Hitung.sisaHari(b);
    Hitung.suhuKl = 8;
    expect(Hitung.sisaHari(b), lessThan(normal));
  });

  test('pengingat H-1 dan hari-H dibuat', () {
    final jadwal = Hitung.jadwal([_bahan(lalu: 0, awet: 5)]);
    expect(jadwal.map((e) => e.jenis), containsAll(['h1', 'h0']));
  });
}
