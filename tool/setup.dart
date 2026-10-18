// Menyiapkan folder android/ dan web/ setelah `flutter create .`
//
// Jalankan sekali dari folder proyek:
//   flutter create --org id.mitafbr --project-name kulkasku --platforms=android,web .
//   dart run tool/setup.dart
//
// Yang dilakukan:
//  1. Mengaktifkan core library desugaring (wajib untuk flutter_local_notifications)
//  2. Menambah izin, receiver notifikasi, dan jalur balik login Google di AndroidManifest.xml
//  3. Mengganti nama aplikasi menjadi "Kulkasku"
//  4. Memasang ikon Mumu untuk Android & web
//  5. Mengisi judul, deskripsi, dan warna tema web
// Aman dijalankan berkali-kali.

import 'dart:io';

void main() {
  _gradle();
  _manifest();
  _ikon();
  _web();
  stdout.writeln('\nSelesai! Lanjut: flutter pub get, lalu flutter run');
}

void _info(String s) => stdout.writeln('• $s');

void _gradle() {
  final kts = File('android/app/build.gradle.kts');
  final groovy = File('android/app/build.gradle');
  if (kts.existsSync()) {
    var s = kts.readAsStringSync();
    if (!s.contains('isCoreLibraryDesugaringEnabled')) {
      s = s.replaceFirst(RegExp(r'compileOptions\s*\{'), 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true');
    }
    if (!s.contains('desugar_jdk_libs')) {
      s += '\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n';
    }
    kts.writeAsStringSync(s);
    _info('build.gradle.kts: desugaring aktif');
  } else if (groovy.existsSync()) {
    var s = groovy.readAsStringSync();
    if (!s.contains('coreLibraryDesugaringEnabled')) {
      s = s.replaceFirst(RegExp(r'compileOptions\s*\{'), 'compileOptions {\n        coreLibraryDesugaringEnabled true');
    }
    if (!s.contains('desugar_jdk_libs')) {
      s += "\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n";
    }
    groovy.writeAsStringSync(s);
    _info('build.gradle: desugaring aktif');
  } else {
    _info('Folder android belum ada. Jalankan dulu: flutter create --platforms=android,web .');
  }
}

void _manifest() {
  final f = File('android/app/src/main/AndroidManifest.xml');
  if (!f.existsSync()) return;
  var s = f.readAsStringSync();
  const izin = [
    'android.permission.INTERNET',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.RECEIVE_BOOT_COMPLETED',
    'android.permission.VIBRATE',
  ];
  for (final p in izin) {
    if (!s.contains(p)) {
      s = s.replaceFirst(RegExp(r'<manifest[^>]*>'), '${RegExp(r'<manifest[^>]*>').firstMatch(s)!.group(0)}\n    <uses-permission android:name="$p"/>');
    }
  }
  if (!s.contains('ScheduledNotificationReceiver')) {
    s = s.replaceFirst('</application>', '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
    </application>''');
  }
  if (!s.contains('flutter_web_auth_2.CallbackActivity')) {
    // Supaya setelah masuk dengan Google, browser kembali ke aplikasi (kulkasku://login-callback)
    s = s.replaceFirst('</application>', '''
        <activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true">
            <intent-filter android:label="flutter_web_auth_2">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="kulkasku" />
            </intent-filter>
        </activity>
    </application>''');
  }
  s = s.replaceFirst(RegExp(r'android:label="[^"]*"'), 'android:label="Kulkasku"');
  f.writeAsStringSync(s);
  _info('AndroidManifest.xml: izin & receiver notifikasi');
}

void _salin(String dari, String ke) {
  final a = File(dari);
  if (!a.existsSync()) return;
  final b = File(ke);
  if (!b.parent.existsSync()) return;
  a.copySync(ke);
}

void _ikon() {
  const d = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];
  for (final x in d) {
    _salin('tool/ikon/mipmap-$x.png', 'android/app/src/main/res/mipmap-$x/ic_launcher.png');
  }
  _salin('tool/ikon/Icon-192.png', 'web/icons/Icon-192.png');
  _salin('tool/ikon/Icon-512.png', 'web/icons/Icon-512.png');
  _salin('tool/ikon/Icon-maskable-192.png', 'web/icons/Icon-maskable-192.png');
  _salin('tool/ikon/Icon-maskable-512.png', 'web/icons/Icon-maskable-512.png');
  _salin('tool/ikon/favicon.png', 'web/favicon.png');
  _info('Ikon Mumu terpasang');
}

void _web() {
  final idx = File('web/index.html');
  if (idx.existsSync()) {
    var s = idx.readAsStringSync();
    s = s.replaceFirst(RegExp(r'<title>[^<]*</title>'), '<title>Kulkasku</title>');
    s = s.replaceFirst(RegExp(r'<meta name="description" content="[^"]*">'),
        '<meta name="description" content="Kulkasku - pengingat sayur & buah di kulkas sebelum layu. Dibuat oleh Mita.">');
    s = s.replaceFirst(RegExp(r'<meta name="apple-mobile-web-app-title" content="[^"]*">'),
        '<meta name="apple-mobile-web-app-title" content="Kulkasku">');
    if (!s.contains('kk-muat')) {
      // Layar "sedang memuat" bergambar Mumu, tampil selama Flutter web disiapkan
      s = s.replaceFirst('<body>', r'''<body>
  <div id="kk-muat">
    <style>
      #kk-muat{position:fixed;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;
        background:radial-gradient(circle at 50% 40%,#FFF8E6,#F3EFE7);font-family:system-ui,sans-serif;color:#2F7D3A;
        transition:opacity .4s;z-index:9}
      #kk-muat img{width:96px;height:96px;border-radius:24px;animation:kk-lompat 1s ease-in-out infinite}
      #kk-muat b{font-size:15px;letter-spacing:.3px}
      #kk-muat i{display:block;width:120px;height:6px;border-radius:6px;background:#E3EDD8;overflow:hidden;position:relative}
      #kk-muat i:after{content:"";position:absolute;inset:0;width:40%;border-radius:6px;background:#5FAE52;animation:kk-jalan 1.2s ease-in-out infinite}
      @keyframes kk-lompat{0%,100%{transform:translateY(0)}50%{transform:translateY(-12px)}}
      @keyframes kk-jalan{0%{left:-40%}100%{left:100%}}
    </style>
    <img src="icons/Icon-192.png" alt="Mumu">
    <b>Menyiapkan Kulkasku…</b>
    <i></i>
  </div>
  <script>
    window.addEventListener('flutter-first-frame', function () {
      var e = document.getElementById('kk-muat');
      if (e) { e.style.opacity = 0; setTimeout(function () { e.remove(); }, 450); }
    });
  </script>''');
    }
    idx.writeAsStringSync(s);
  }
  final man = File('web/manifest.json');
  if (man.existsSync()) {
    var s = man.readAsStringSync();
    s = s
        .replaceFirst(RegExp(r'"name":\s*"[^"]*"'), '"name": "Kulkasku"')
        .replaceFirst(RegExp(r'"short_name":\s*"[^"]*"'), '"short_name": "Kulkasku"')
        .replaceFirst(RegExp(r'"background_color":\s*"[^"]*"'), '"background_color": "#F3EFE7"')
        .replaceFirst(RegExp(r'"theme_color":\s*"[^"]*"'), '"theme_color": "#2F7D3A"')
        .replaceFirst(RegExp(r'"description":\s*"[^"]*"'), '"description": "Pengingat sayur & buah di kulkas sebelum layu."');
    man.writeAsStringSync(s);
  }
  // Halaman Kebijakan Privasi & Syarat Penggunaan (dipakai juga di layar login Google)
  _salin('tool/web/privasi.html', 'web/privasi.html');
  _salin('tool/web/syarat.html', 'web/syarat.html');
  _salin('tool/web/kembali.html', 'web/kembali.html');
  _info('web/index.html & manifest.json: judul dan warna Kulkasku');
}
