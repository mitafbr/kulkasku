import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/api_client.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/garden.dart';
import '../widgets/mumu.dart';
import '../widgets/transisi_dapur.dart';
import 'info_pages.dart';
import 'shell_page.dart';

/// Halaman Masuk / Daftar dengan taman kecil dan maskot Mumu.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _mumu = GlobalKey<MumuHidupState>();
  final _kebun = GlobalKey<KebunSceneState>();
  final _form = GlobalKey<FormState>();

  bool _daftar = false;
  bool _lihat = false;
  bool _ingat = true;
  bool _memuat = false;
  String? _error;
  String? _kata;
  Timer? _kataTimer;
  int _baris = 0;

  // Sengaja dikosongkan: setiap pengguna mengetik akunnya sendiri,
  // pengguna baru wajib Daftar dulu.
  final _user = TextEditingController();
  final _pw = TextEditingController();
  final _nama = TextEditingController();
  final _uname = TextEditingController();
  final _email = TextEditingController();
  final _hp = TextEditingController();
  final _fokusPw = FocusNode();
  final _fokusUser = FocusNode();

  late final AnimationController _goyangForm =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  static const _kalimat = [
    'Hihi, geli!',
    'Aku Mumu, penjaga kulkasmu',
    'Aku jamur dongeng, bukan untuk dimakan ya!',
    'Jangan lupa cek tanggal layu ya',
    'Jangan biarkan sayurmu layu ya',
  ];

  @override
  void initState() {
    super.initState();
    // pastikan tidak ada notifikasi dari halaman sebelumnya yang tertinggal
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    });
    _fokusPw.addListener(_ubahFokus);
    _fokusUser.addListener(_ubahFokus);
    for (final c in [_user, _pw, _nama, _uname, _email, _hp]) {
      c.addListener(() => setState(() {}));
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _bicara(_daftar ? 'Yuk daftar, aku jagain sayurmu!' : 'Halo lagi! Sayurmu nungguin.');
    });
  }

  @override
  void dispose() {
    for (final c in [_user, _pw, _nama, _uname, _email, _hp]) {
      c.dispose();
    }
    _fokusPw.dispose();
    _fokusUser.dispose();
    _goyangForm.dispose();
    _kataTimer?.cancel();
    super.dispose();
  }

  void _bicara(String teks, [int ms = 2200]) {
    _kataTimer?.cancel();
    setState(() => _kata = teks);
    _kataTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => _kata = null);
    });
  }

  void _ubahFokus() {
    final m = _mumu.currentState;
    if (m == null) return;
    if (_fokusPw.hasFocus) {
      m.malu(true, intip: _lihat);
      _bicara(_lihat ? 'Ups, aku ngintip dikit…' : 'Aku tutup mata, nggak ngintip kok!', 1800);
    } else {
      m.malu(false);
    }
    if (_fokusUser.hasFocus) {
      m.kunciLirik(const Offset(-.3, 1));
    } else {
      m.kunciLirik(null);
    }
  }

  void _gantiMode(bool daftar) {
    if (daftar == _daftar) return;
    setState(() {
      _daftar = daftar;
      _error = null;
      _pw.clear(); // kata sandi tidak ikut terbawa ke tab lain
      _lihat = false;
    });
    _bicara(daftar ? 'Yuk daftar, aku jagain sayurmu!' : 'Halo lagi! Sayurmu nungguin.');
  }

  // ------------------------------------------------------------ validasi
  String? _cekUser(String? v) => (v ?? '').trim().isEmpty ? 'Isi username atau email' : null;
  String? _cekNama(String? v) => (v ?? '').trim().length < 3 ? 'Nama minimal 3 huruf' : null;
  String? _cekUname(String? v) =>
      RegExp(r'^[a-z0-9._]{3,20}$').hasMatch((v ?? '').trim().toLowerCase()) ? null : 'Username 3–20 karakter: huruf kecil, angka, titik, garis bawah';
  String? _cekEmail(String? v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Format email belum benar';
  String? _cekPw(String? v) => (v ?? '').length < (_daftar ? 6 : 1) ? (_daftar ? 'Kata sandi minimal 6 karakter' : 'Isi kata sandi') : null;
  String? _cekHp(String? v) => (v ?? '').trim().isEmpty || RegExp(r'^[0-9]{10,14}$').hasMatch(v!.trim()) ? null : 'Nomor HP 10–14 digit, atau kosongkan';

  int get _siap => [
        _cekNama(_nama.text),
        _cekUname(_uname.text),
        _cekEmail(_email.text),
        _cekPw(_pw.text),
      ].where((e) => e == null).length;

  ({String label, Color warna, String ikon, double nilai}) get _kekuatan {
    final v = _pw.text;
    var sc = 0;
    if (v.length >= 6) sc++;
    if (v.length >= 10) sc++;
    if (RegExp(r'[0-9]').hasMatch(v) && RegExp(r'[a-zA-Z]').hasMatch(v)) sc++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(v) || RegExp(r'[A-Z]').hasMatch(v)) sc++;
    if (v.length < 6) sc = math.max(0, sc - 1);
    sc = sc.clamp(0, 3).toInt();
    const data = [
      ('Lemah', Color(0xFFE46A4B), 'tunas'),
      ('Lumayan', Color(0xFFE9A23B), 'daun'),
      ('Kuat', Color(0xFF5FAE52), 'brokoli'),
      ('Kuat sekali', Color(0xFF2F7D3A), 'pot'),
    ];
    final d = data[sc];
    return (label: d.$1, warna: d.$2, ikon: d.$3, nilai: (sc + 1) / 4);
  }

  // ------------------------------------------------------------ kirim
  Future<void> _kirim() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    if (!(_form.currentState?.validate() ?? false)) {
      _gagal('Ada isian yang belum pas.');
      return;
    }
    setState(() => _memuat = true);
    try {
      if (_daftar) {
        await AppState.i.daftarAkun(
          nama: _nama.text.trim(),
          username: _uname.text.trim().toLowerCase(),
          email: _email.text.trim(),
          hp: _hp.text.trim(),
          password: _pw.text,
        );
      } else {
        await AppState.i.masukAkun(_user.text.trim(), _pw.text);
      }
      if (!mounted) return;
      _berhasil();
    } on ApiException catch (e) {
      _gagal(e.pesan);
    } catch (e) {
      _gagal('Tidak bisa terhubung. Cek internet kamu.');
    }
  }

  Future<void> _google() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _memuat = true;
    });
    _bicara('Ke Google sebentar ya!', 1600);
    try {
      final selesai = await AppState.i.masukGoogle();
      if (!mounted) return;
      if (selesai) {
        _berhasil();
      } else {
        setState(() => _memuat = false); // web: halaman sedang pindah ke Google
      }
    } on ApiException catch (e) {
      _gagal(e.pesan);
    } catch (_) {
      _gagal('Tidak bisa masuk dengan Google. Coba lagi.');
    }
  }

  void _gagal(String pesan) {
    if (!mounted) return;
    setState(() {
      _error = pesan;
      _memuat = false;
    });
    _goyangForm.forward(from: 0);
    _mumu.currentState?.sedih();
    _bicara('Yah, ada yang belum pas…', 1800);
  }

  Future<void> _berhasil() async {
    _mumu.currentState?.senang();
    _bicara(_daftar ? 'Yeay, kita jadi teman!' : 'Ayo, bawa sayurnya ke dapur!', 1500);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    _kebun.currentState?.pulang();
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(RuteDapur(const ShellPage()));
    if (_daftar) {
      toast(context, 'Akun jadi! Selamat datang, ${AppState.i.user?.nama ?? ''}', ikon: 'pesta');
    }
  }

  // ------------------------------------------------------------ tampilan
  @override
  Widget build(BuildContext context) {
    final lebar = layarLebar(context);
    return Scaffold(
      backgroundColor: lebar ? const Color(0xFFFFFDF8) : AppColors.cream,
      body: Listener(
        onPointerHover: (e) => _mumu.currentState?.lirik(e.position),
        onPointerMove: (e) => _mumu.currentState?.lirik(e.position),
        onPointerDown: (e) => _mumu.currentState?.lirik(e.position),
        child: lebar ? _tataLebar() : _tataHp(),
      ),
    );
  }

  /// Taman Mumu + gelembung kata-katanya.
  Widget _taman({required double tinggi, required double ukuranMumu}) => Stack(clipBehavior: Clip.none, children: [
        KebunScene(
          key: _kebun,
          daftar: _daftar,
          mumuKey: _mumu,
          tinggi: tinggi,
          ukuranMumu: ukuranMumu,
          onMumuTap: () {
            _mumu.currentState?.geli();
            _bicara(_kalimat[_baris++ % _kalimat.length]);
          },
          onPapanTap: _bicara,
        ),
        if (_kata != null)
          Positioned(
            top: math.max(6.0, tinggi - ukuranMumu - 44),
            left: 0,
            right: 0,
            child: Center(child: _Gelembung(_kata!)),
          ),
      ]);

  /// HP: taman di atas, lembar formulir di bawah (bisa digulir).
  Widget _tataHp() {
    final atas = MediaQuery.paddingOf(context).top;
    return SingleChildScrollView(
      child: Column(children: [
        // langit dibuat sampai ke belakang status bar HP
        _taman(tinggi: 236 + atas, ukuranMumu: 172),
        Transform.translate(offset: const Offset(0, -14), child: _lembar()),
      ]),
    );
  }

  /// Laptop/PC: taman besar di kiri, formulir di kanan.
  Widget _tataLebar() {
    final layar = MediaQuery.sizeOf(context);
    final lebarForm = math.min(560.0, math.max(420.0, layar.width * .4));
    return Row(children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, k) => ClipRect(
            child: Stack(children: [
              _taman(tinggi: k.maxHeight, ukuranMumu: math.min(300.0, k.maxHeight * .42)),
              Positioned(
                left: 40,
                top: 36,
                right: 40,
                child: Naik(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Kulkasku.', style: AppText.display(64, color: AppColors.leaf)),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        'Catat isi kulkas, dapat pengingat sebelum sayur & buah layu, dan lihat berapa banyak yang berhasil kamu selamatkan.',
                        style: AppText.body(15, color: AppColors.ink.withValues(alpha: .75), height: 1.5),
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
      SizedBox(
        width: lebarForm,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF8),
            boxShadow: [BoxShadow(color: Color(0x14593F26), blurRadius: 30, offset: Offset(-8, 0))],
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _goyang(Stack(clipBehavior: Clip.none, children: [
                    Positioned(
                      right: 10,
                      top: -26,
                      child: GestureDetector(
                        onTap: () => _bicara('Aku adiknya Mumu!'),
                        child: const _AdikMengintip(),
                      ),
                    ),
                    _isiForm(lebar: true),
                  ])),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  /// Formulir bergoyang saat isian salah.
  Widget _goyang(Widget child) => AnimatedBuilder(
        animation: _goyangForm,
        builder: (_, c) {
          final t = _goyangForm.value;
          return Transform.translate(offset: Offset(math.sin(t * math.pi * 6) * 9 * (1 - t), 0), child: c);
        },
        child: child,
      );

  /// Lembar formulir versi HP (menempel di bawah taman).
  Widget _lembar() {
    return _goyang(Container(
        constraints: BoxConstraints(minHeight: math.max(0.0, MediaQuery.of(context).size.height - 240)),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF8),
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
          boxShadow: [BoxShadow(color: Color(0x14593F26), blurRadius: 22, offset: Offset(0, -8))],
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          const Positioned(left: -4, top: -4, child: _Sulur()),
          Positioned(right: -4, top: -4, child: Transform.flip(flipX: true, child: const _Sulur())),
          Positioned(
            right: 84,
            top: -24,
            child: GestureDetector(
              onTap: () => _bicara('Aku adiknya Mumu!'),
              child: const _AdikMengintip(),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
                child: _isiForm(lebar: false),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// Isi formulir Masuk/Daftar (dipakai di HP dan laptop).
  Widget _isiForm({required bool lebar}) {
    final k = _kekuatan;
    return Form(
              key: _form,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (!lebar) ...[
                  Center(
                    child: Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(3))),
                  ),
                  const SizedBox(height: 14),
                ],
                Text(_daftar ? 'Buat akun baru, gratis' : 'Selamat datang di Kulkasku',
                    style: AppText.body(14, color: AppColors.muted)),
                const SizedBox(height: 6),
                _JudulAnimasi(key: ValueKey(_daftar), baris: _daftar ? ['Mulai', 'sekarang.'] : ['Masuk ke', 'kulkasmu.']),
                const SizedBox(height: 16),
                _Tab(daftar: _daftar, onUbah: _gantiMode),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  transitionBuilder: (child, anim) {
                    final masuk = child.key == ValueKey(_daftar);
                    final dari = (_daftar ? 1 : -1) * (masuk ? 1.0 : -1.0);
                    return FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween(begin: Offset(.15 * dari, 0), end: Offset.zero)
                            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    key: ValueKey(_daftar),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _daftar ? _isianDaftar(k) : _isianMasuk(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: AppText.body(13, color: AppColors.tomatoDark)),
                ],
                const SizedBox(height: 16),
                if (_daftar) ...[_Progres(siap: _siap), const SizedBox(height: 14)],
                ChunkyButton(
                  label: _memuat ? (_daftar ? 'Menyiapkan akun…' : 'Membuka kulkas…') : (_daftar ? 'Daftar' : 'Masuk'),
                  ikon: _daftar ? 'tunas' : 'kulkas',
                  memuat: _memuat,
                  warna: _daftar ? AppColors.carrot : AppColors.leaf,
                  bayangan: _daftar ? AppColors.carrotDark : AppColors.leafDark,
                  onTap: _kirim,
                ),
                const SizedBox(height: 14),
                Row(children: [
                  const Expanded(child: Divider(color: AppColors.line)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('atau', style: AppText.body(12, color: AppColors.muted)),
                  ),
                  const Expanded(child: Divider(color: AppColors.line)),
                ]),
                const SizedBox(height: 12),
                _TombolGoogle(label: _daftar ? 'Daftar dengan Google' : 'Masuk dengan Google', onTap: _memuat ? null : _google),
                if (!_daftar) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    _IngatSaya(nilai: _ingat, onUbah: (v) => setState(() => _ingat = v)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => toast(
                        context,
                        AppConfig.pakaiSupabase
                            ? 'Hubungi admin lewat halaman GitHub Kulkasku untuk reset kata sandi.'
                            : 'Mode lokal: akun hanya tersimpan di perangkat ini. Kalau lupa, daftar akun baru ya.',
                        ikon: 'surat',
                      ),
                      child: Text('Lupa kata sandi?', style: AppText.body(13, color: AppColors.leaf, weight: FontWeight.w800)),
                    ),
                  ]),
                ],
                const SizedBox(height: 18),
                Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
                  for (final n in ['tomat', 'wortel', 'brokoli', 'apel', 'bayam', 'stroberi', 'jagung', 'terong']) Emo(n, size: 22),
                ]),
                const SizedBox(height: 6),
                Text('Sayur & buahmu aman bersama Mumu', textAlign: TextAlign.center, style: AppText.body(11.5, color: AppColors.muted)),
                if (kIsWeb) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse(AppConfig.linkApk), mode: LaunchMode.externalApplication),
                      icon: const Emo('hp', size: 20),
                      label: Text('Unduh APK Android', style: AppText.body(13, color: AppColors.leaf, weight: FontWeight.w800)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.leaf),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TentangPage())),
                    child: Text('Tentang', style: AppText.body(12, color: AppColors.muted)),
                  ),
                  Text('·', style: AppText.body(12, color: AppColors.muted)),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivasiPage())),
                    child: Text('Kebijakan Privasi', style: AppText.body(12, color: AppColors.muted)),
                  ),
                ]),
              ]),
            );
  }

  List<Widget> _isianMasuk() => [
        _Isian(
          label: 'Username atau email',
          ikon: 'tunas',
          warnaIkon: AppColors.lettuce,
          controller: _user,
          fokus: _fokusUser,
          validator: _cekUser,
          ok: _cekUser(_user.text) == null,
          onKetik: () => _mumu.currentState?.kunciLirik(Offset(-1 + math.min(2.0, _user.text.length * .09), 1)),
        ),
        const SizedBox(height: 12),
        _isianSandi(),
      ];

  List<Widget> _isianDaftar(({String label, Color warna, String ikon, double nilai}) k) => [
        _Isian(label: 'Nama lengkap', ikon: 'tunas', warnaIkon: AppColors.lettuce, controller: _nama, validator: _cekNama, ok: _cekNama(_nama.text) == null),
        const SizedBox(height: 12),
        _Isian(label: 'Username', ikon: 'tunas', warnaIkon: AppColors.lettuce, controller: _uname, validator: _cekUname, ok: _cekUname(_uname.text) == null),
        const SizedBox(height: 12),
        _Isian(
          label: 'Email',
          ikon: 'surat',
          warnaIkon: AppColors.carrotLight,
          controller: _email,
          validator: _cekEmail,
          ok: _cekEmail(_email.text) == null,
          keyboard: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _isianSandi(),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: _pw.text.isEmpty ? .08 : k.nilai),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutBack,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE9E3D7),
                  color: k.warna,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Emo(k.ikon, size: 18),
          const SizedBox(width: 4),
          Text(k.label, style: AppText.body(11, color: k.warna, weight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        _Isian(
          label: 'Nomor HP (opsional)',
          ikon: 'hp',
          warnaIkon: const Color(0xFFECE1F3),
          controller: _hp,
          validator: _cekHp,
          ok: _hp.text.isNotEmpty && _cekHp(_hp.text) == null,
          keyboard: TextInputType.phone,
          hint: 'Boleh dikosongkan',
        ),
      ];

  Widget _isianSandi() => _Isian(
        label: _daftar ? 'Buat kata sandi' : 'Kata sandi',
        ikon: _lihat ? 'gembokbuka' : 'gembok',
        warnaIkon: AppColors.tomatoLight,
        controller: _pw,
        fokus: _fokusPw,
        validator: _cekPw,
        ok: _pw.text.isNotEmpty && _cekPw(_pw.text) == null,
        rahasia: !_lihat,
        akhiran: TextButton(
          onPressed: () {
            setState(() => _lihat = !_lihat);
            _fokusPw.requestFocus();
            _mumu.currentState?.malu(true, intip: _lihat);
            _bicara(_lihat ? 'Ups, aku ngintip dikit…' : 'Oke, tutup mata lagi!', 1500);
          },
          child: Text(_lihat ? 'Tutup' : 'Lihat', style: AppText.body(12, color: AppColors.leaf, weight: FontWeight.w800)),
        ),
      );
}

// ===================================================================== bagian kecil

class _Gelembung extends StatelessWidget {
  final String teks;
  const _Gelembung(this.teks);
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(teks),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (_, v, c) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: c)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Text(teks, style: AppText.body(12.5, weight: FontWeight.w800)),
        ),
      );
}

class _JudulAnimasi extends StatelessWidget {
  final List<String> baris;
  const _JudulAnimasi({super.key, required this.baris});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < baris.length; i++)
            ClipRect(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 550 + i * 100),
                curve: Interval(i * 100 / (550 + i * 100), 1, curve: Curves.easeOutBack),
                builder: (_, v, c) => Transform.translate(offset: Offset(0, 46 * (1 - v)), child: Opacity(opacity: v.clamp(0.0, 1.0), child: c)),
                child: Text(baris[i], style: AppText.display(40)),
              ),
            ),
        ],
      );
}

class _Tab extends StatelessWidget {
  final bool daftar;
  final ValueChanged<bool> onUbah;
  const _Tab({required this.daftar, required this.onUbah});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(color: daftar ? const Color(0xFFF8E3D2) : const Color(0xFFE3EDD8), borderRadius: BorderRadius.circular(26)),
      child: Stack(children: [
        AnimatedAlign(
          duration: const Duration(milliseconds: 450),
          curve: Curves.elasticOut,
          alignment: daftar ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .5,
            heightFactor: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
              ),
            ),
          ),
        ),
        // Positioned.fill: label diisi setinggi tab supaya pas di tengah (atas-bawah)
        Positioned.fill(
          child: Row(children: [
          for (final m in [(false, 'Masuk', 'daun'), (true, 'Daftar', 'tunas')])
            Expanded(
              child: Semantics(
                selected: daftar == m.$1,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onUbah(m.$1),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    // ikon hanya memakan tempat di tab yang aktif, jadi tulisan tetap di tengah
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: daftar == m.$1
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: 1),
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.elasticOut,
                                builder: (_, v, c) => Transform.scale(scale: v, child: c),
                                child: Emo(m.$3, size: 20),
                              ),
                              const SizedBox(width: 6),
                            ])
                          : const SizedBox.shrink(),
                    ),
                    Text(m.$2,
                        style: AppText.body(15, color: daftar == m.$1 ? AppColors.ink : AppColors.muted, weight: FontWeight.w800, height: 1.0)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Isian extends StatelessWidget {
  final String label;
  final String ikon;
  final Color warnaIkon;
  final TextEditingController controller;
  final FocusNode? fokus;
  final FormFieldValidator<String> validator;
  final bool ok;
  final bool rahasia;
  final Widget? akhiran;
  final TextInputType? keyboard;
  final String? hint;
  final VoidCallback? onKetik;

  const _Isian({
    required this.label,
    required this.ikon,
    required this.warnaIkon,
    required this.controller,
    required this.validator,
    required this.ok,
    this.fokus,
    this.rahasia = false,
    this.akhiran,
    this.keyboard,
    this.hint,
    this.onKetik,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppText.body(13, weight: FontWeight.w800)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        focusNode: fokus,
        obscureText: rahasia,
        keyboardType: keyboard,
        validator: validator,
        // Matikan isi otomatis dari browser/HP: kata sandi tidak boleh muncul sendiri.
        autofillHints: null,
        enableSuggestions: false,
        autocorrect: false,
        onChanged: (_) => onKetik?.call(),
        style: AppText.body(15),
        decoration: InputDecoration(
          hintText: hint,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: ok ? const Color(0xFF9ACB86) : AppColors.line, width: 1.2),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: warnaIkon, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Emo(ikon, size: 18),
            ),
          ),
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedScale(
              scale: ok ? 1 : 0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.elasticOut,
              child: const Emo('centang', size: 22),
            ),
            if (akhiran != null) akhiran! else const SizedBox(width: 12),
          ]),
        ),
      ),
    ]);
  }
}

class _Progres extends StatelessWidget {
  final int siap;
  const _Progres({required this.siap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF1F7EA), borderRadius: leafRadius(18)),
      child: Row(children: [
        SizedBox(
          width: 132,
          height: 30,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: siap / 4),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, __) => CustomPaint(painter: _RantingProgres(v, siap)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            siap == 4 ? 'Semua siap, tinggal tekan Daftar!' : siap == 0 ? 'Ayo isi datanya' : '$siap dari 4 sudah siap',
            style: AppText.body(12.5, color: AppColors.leafDark, weight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }
}

class _RantingProgres extends CustomPainter {
  final double v;
  final int daun;
  _RantingProgres(this.v, this.daun);
  @override
  void paint(Canvas canvas, Size s) {
    final jalur = Path()
      ..moveTo(4, 22)
      ..cubicTo(30, 14, 60, 26, 90, 18)
      ..cubicTo(110, 13, 124, 12, 128, 16);
    final kuas = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(jalur, kuas..color = const Color(0xFFE2D8C2));
    final m = jalur.computeMetrics().first;
    canvas.drawPath(m.extractPath(0, m.length * v.clamp(0.0, 1.0)), kuas..color = const Color(0xFF5FAE52));
    const warna = [Color(0xFF7CC765), Color(0xFF5FAE52), Color(0xFF6DBB5A), Color(0xFF4E9A4A)];
    for (var i = 0; i < daun; i++) {
      final x = 22.0 + i * 30;
      canvas.drawPath(
        Path()
          ..moveTo(x, i.isOdd ? 20 : 17)
          ..relativeCubicTo(-7, -9, 2, -16, 9, -13)
          ..relativeCubicTo(0, 8, -4, 12, -9, 13)
          ..close(),
        Paint()..color = warna[i],
      );
    }
  }

  @override
  bool shouldRepaint(_RantingProgres old) => old.v != v || old.daun != daun;
}

class _IngatSaya extends StatelessWidget {
  final bool nilai;
  final ValueChanged<bool> onUbah;
  const _IngatSaya({required this.nilai, required this.onUbah});
  @override
  Widget build(BuildContext context) => Semantics(
        checked: nilai,
        label: 'Ingat saya',
        child: JellyTap(
          onTap: () => onUbah(!nilai),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: nilai ? AppColors.mumuRed : Colors.white,
                borderRadius: leafRadius(8),
                border: Border.all(color: nilai ? AppColors.mumuRedDark : const Color(0xFFD9CFBC), width: 2),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: nilai ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.elasticOut,
                child: const Emo('centang', size: 16),
              ),
            ),
            const SizedBox(width: 8),
            Text('Ingat saya', style: AppText.body(13, color: AppColors.muted, weight: FontWeight.w800)),
          ]),
        ),
      );
}

class _Sulur extends StatelessWidget {
  const _Sulur();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 76, height: 44, child: CustomPaint(painter: _SulurPainter()));
}

class _SulurPainter extends CustomPainter {
  const _SulurPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final k = s.width / 96;
    canvas.scale(k, k);
    canvas.drawPath(
      Path()
        ..moveTo(4, 8)
        ..cubicTo(30, 6, 50, 12, 70, 26)
        ..cubicTo(80, 34, 86, 44, 88, 52),
      Paint()
        ..color = const Color(0xFF5FAE52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    for (final d in const [
      [18.0, 6.0, -20.0],
      [38.0, 9.0, 10.0],
      [58.0, 18.0, 30.0],
      [76.0, 34.0, 60.0],
    ]) {
      canvas.save();
      canvas.translate(d[0], d[1]);
      canvas.rotate(d[2] * math.pi / 180);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..cubicTo(4, -9, 14, -9, 16, -4)
          ..cubicTo(11, 2, 5, 3, 0, 0)
          ..close(),
        Paint()..color = const Color(0xFF6DBB5A),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdikMengintip extends StatefulWidget {
  const _AdikMengintip();
  @override
  State<_AdikMengintip> createState() => _AdikMengintipState();
}

class _AdikMengintipState extends State<_AdikMengintip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 40,
        height: 30,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, c) {
              final v = _c.value;
              final naik = v < .3 ? 0.0 : v < .4 ? (v - .3) / .1 : v < .7 ? 1.0 : v < .8 ? 1 - (v - .7) / .1 : 0.0;
              return Transform.translate(offset: Offset(0, 22 * (1 - Curves.easeOutBack.transform(naik.clamp(0.0, 1.0)))), child: c);
            },
            child: const MumuMini(size: 40),
          ),
        ),
      );
}


/// Tombol "Masuk/Daftar dengan Google".
class _TombolGoogle extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _TombolGoogle({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => JellyTap(
        onTap: onTap,
        semantik: label,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: AppColors.line, width: 1.4),
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _LogoGoogle())),
            const SizedBox(width: 10),
            Text(label, style: AppText.body(15, weight: FontWeight.w800)),
          ]),
        ),
      );
}

/// Logo "G" Google sederhana (empat warna).
class _LogoGoogle extends CustomPainter {
  const _LogoGoogle();
  @override
  void paint(Canvas canvas, Size s) {
    final r = s.width / 2;
    final c = Offset(r, r);
    final kuas = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * .2;
    final kotak = Rect.fromCircle(center: c, radius: r * .78);
    const d = math.pi / 180;
    canvas.drawArc(kotak, -40 * d, -100 * d, false, kuas..color = const Color(0xFFEA4335));
    canvas.drawArc(kotak, -140 * d, -90 * d, false, kuas..color = const Color(0xFFFBBC05));
    canvas.drawArc(kotak, 130 * d, -100 * d, false, kuas..color = const Color(0xFF34A853));
    canvas.drawArc(kotak, 30 * d, -30 * d, false, kuas..color = const Color(0xFF4285F4));
    canvas.drawLine(Offset(r, r), Offset(r + r * .86, r), kuas..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
