import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/branch_nav.dart';
import '../widgets/common.dart';

/// Edit profil: upload foto sendiri atau pilih avatar sayur, ubah nama & kontak.
class EditProfilPage extends StatefulWidget {
  const EditProfilPage({super.key});
  @override
  State<EditProfilPage> createState() => _EditProfilPageState();
}

class _EditProfilPageState extends State<EditProfilPage> {
  static const _avatar = [
    ('brokoli', Color(0xFFDDF0D0)),
    ('tomat', Color(0xFFFCE1DA)),
    ('wortel', Color(0xFFFDE8D2)),
    ('alpukat', Color(0xFFE6F0D2)),
    ('jamur', Color(0xFFF3E7DC)),
    ('stroberi', Color(0xFFFBDDE2)),
    ('terong', Color(0xFFECE1F3)),
    ('jeruk', Color(0xFFFFEFCF)),
  ];

  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama, _uname, _email, _hp;
  late String _ava;
  String? _foto; // foto lama (URL/data URI)
  Uint8List? _fotoBaru;
  bool _memuat = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = AppState.i.user!;
    _nama = TextEditingController(text: u.nama);
    _uname = TextEditingController(text: u.username);
    _email = TextEditingController(text: u.email);
    _hp = TextEditingController(text: u.hp);
    _ava = u.ava;
    _foto = u.foto;
  }

  @override
  void dispose() {
    _nama.dispose();
    _uname.dispose();
    _email.dispose();
    _hp.dispose();
    super.dispose();
  }

  Color _warnaAva(String k) => _avatar.firstWhere((a) => a.$1 == k, orElse: () => _avatar.first).$2;

  Future<void> _pilihFoto() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 480, maxHeight: 480, imageQuality: 82);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => _fotoBaru = bytes);
    } catch (e) {
      setState(() => _error = 'Gambar tidak bisa dibuka, coba file lain');
    }
  }

  Future<void> _simpan() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _memuat = true;
      _error = null;
    });
    try {
      final s = AppState.i;
      String? foto = _foto;
      final baru = _fotoBaru;
      if (baru != null) foto = await s.unggahFoto(baru);
      final p = s.user!.salin()
        ..nama = _nama.text.trim()
        ..username = _uname.text.trim().toLowerCase()
        ..email = s.repo.online ? s.user!.email : _email.text.trim()
        ..hp = _hp.text.trim()
        ..ava = _ava
        ..foto = foto;
      await s.simpanProfil(p);
      if (!mounted) return;
      toast(context, 'Profil tersimpan', ikon: 'centang');
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _memuat = false;
        _error = 'Gagal menyimpan: $e';
      });
    }
  }

  Widget _gambarBesar() {
    final baru = _fotoBaru;
    if (baru != null) return Image.memory(baru, fit: BoxFit.cover, width: 130, height: 130);
    final f = _foto;
    if (f != null) return SizedBox(width: 130, height: 130, child: FotoProfil(f));
    return Container(
      width: 130,
      height: 130,
      color: _warnaAva(_ava),
      alignment: Alignment.center,
      child: Emo(_ava, size: 92),
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = AppState.i.repo.online;
    final adaFoto = _fotoBaru != null || _foto != null;
    return Scaffold(
      body: IsiTengah(maxWidth: 600, child: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Row(children: [
                const TombolKembali(),
                Expanded(child: Text('EDIT PROFIL', textAlign: TextAlign.center, style: AppText.label())),
                const SizedBox(width: 46),
              ]),
              const SizedBox(height: 14),
              Center(
                child: JellyTap(
                  onTap: _pilihFoto,
                  semantik: 'Upload foto dari galeri',
                  child: Stack(clipBehavior: Clip.none, children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: ClipOval(key: ValueKey('${_fotoBaru?.length}-$_foto-$_ava'), child: _gambarBesar()),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 4,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Color(0x2E000000), blurRadius: 8, offset: Offset(0, 3))],
                        ),
                        alignment: Alignment.center,
                        child: const Emo('kamera', size: 30),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('Ketuk lingkaran untuk upload foto dari galeri', style: AppText.body(13, color: AppColors.muted)),
                  if (adaFoto)
                    TextButton(
                      onPressed: () => setState(() {
                        _fotoBaru = null;
                        _foto = null;
                      }),
                      child: Text('Hapus foto', style: AppText.body(13, color: AppColors.tomatoDark)),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              Text('ATAU PILIH AVATAR', style: AppText.label()),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (final a in _avatar)
                    JellyTap(
                      onTap: () => setState(() {
                        _ava = a.$1;
                        _fotoBaru = null;
                        _foto = null;
                      }),
                      semantik: 'Avatar ${a.$1}',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: !adaFoto && _ava == a.$1 ? AppColors.leaf : Colors.transparent, width: 3),
                        ),
                        child: Container(
                          decoration: BoxDecoration(color: a.$2, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Emo(a.$1, size: 40),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _isian('Nama', 'tunas', _nama, (v) => (v ?? '').trim().length < 3 ? 'Nama minimal 3 huruf' : null),
              _isian(
                'Username',
                'tunas',
                _uname,
                (v) => RegExp(r'^[a-z0-9._]{3,20}$').hasMatch((v ?? '').trim().toLowerCase())
                    ? null
                    : 'Username 3–20 karakter: huruf kecil, angka, titik, garis bawah',
              ),
              _isian(
                online ? 'Email (tidak bisa diubah di sini)' : 'Email',
                'surat',
                _email,
                (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Format email belum benar',
                aktif: !online,
              ),
              _isian(
                'Nomor HP (opsional)',
                'hp',
                _hp,
                (v) => (v ?? '').trim().isEmpty || RegExp(r'^[0-9]{10,14}$').hasMatch(v!.trim()) ? null : 'Nomor HP 10–14 digit, atau kosongkan',
                hint: 'Boleh dikosongkan',
              ),
              if (_error != null) Text(_error!, style: AppText.body(13, color: AppColors.tomatoDark)),
              const SizedBox(height: 12),
              ChunkyButton(label: 'Simpan', ikon: 'centang', memuat: _memuat, onTap: _simpan),
            ],
          ),
        ),
      )),
    );
  }

  Widget _isian(String label, String ikon, TextEditingController c, FormFieldValidator<String> v, {bool aktif = true, String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppText.body(13, weight: FontWeight.w800)),
          const SizedBox(height: 6),
          TextFormField(
            controller: c,
            enabled: aktif,
            validator: aktif ? v : null,
            style: AppText.body(15),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Padding(padding: const EdgeInsets.all(10), child: Emo(ikon, size: 22)),
            ),
          ),
        ]),
      );
}
