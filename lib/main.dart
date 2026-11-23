import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const DizsApp());

const _core = MethodChannel('dizs/core');
const _bg = Color(0xFF0A0A0F);
const _card = Color(0xFF161622);
const _border = Color(0xFF2A2A3D);
const _accent = Color(0xFFFF4D6D);
const _gold = Color(0xFFFFB84D);
const _green = Color(0xFF3DDC84);

class Game {
  final String name;
  final String pkg;
  const Game(this.name, this.pkg);
}

const games = <Game>[
  Game('Free Fire', 'com.dts.freefireth'),
  Game('Free Fire MAX', 'com.dts.freefiremax'),
  Game('PUBG Mobile', 'com.tencent.ig'),
  Game('Mobile Legends', 'com.mobile.legends'),
  Game('Call of Duty Mobile', 'com.activision.callofduty.shooter'),
];

class DizsApp extends StatelessWidget {
  const DizsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dizs Ware',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent, secondary: _gold),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic> _info = {};
  final List<String> _term = ['Dizs Ware siap. Pastikan Shizuku aktif.'];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _log(String s) {
    if (mounted) setState(() => _term.add(s));
  }

  Future<void> _refresh() async {
    try {
      final m = await _core.invokeMapMethod<String, dynamic>('info');
      if (mounted) setState(() => _info = m ?? {});
    } catch (e) {
      _log('gagal baca info: $e');
    }
  }

  Future<String> _sh(String cmd) async {
    _log('\$ $cmd');
    final out = (await _core.invokeMethod<String>('exec', {'cmd': cmd}) ?? '').trim();
    _log(out.isEmpty ? '(tanpa output)' : out);
    return out;
  }

  Future<void> _askShizuku() async {
    setState(() => _busy = true);
    final ok = await _core.invokeMethod<bool>('requestShizuku') ?? false;
    _log(ok ? 'Izin Shizuku diberikan.' : 'Izin ditolak atau Shizuku belum aktif.');
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _boost() async {
    setState(() => _busy = true);
    _log('=== BOOST DEVICE ===');
    await _sh('id');
    await _sh('whoami');
    await _sh('getprop ro.product.model');
    await _sh('settings put global window_animation_scale 0.5');
    await _sh('settings put global transition_animation_scale 0.5');
    await _sh('settings put global animator_duration_scale 0.5');
    await _sh('setprop debug.egl.force_msaa true');
    await _sh('getprop debug.egl.force_msaa');
    _log('Boost selesai.');
    if (mounted) setState(() => _busy = false);
    if (mounted) _pickGame();
  }

  Future<void> _reset() async {
    setState(() => _busy = true);
    _log('=== RESET ===');
    await _sh('settings put global window_animation_scale 1');
    await _sh('settings put global transition_animation_scale 1');
    await _sh('settings put global animator_duration_scale 1');
    await _sh('setprop debug.egl.force_msaa false');
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pickGame() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: _card,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            const Text('Masuk ke game mana?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            for (final g in games)
              ListTile(
                leading: const Icon(Icons.sports_esports, color: _gold),
                title: Text(g.name),
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _core.invokeMethod<bool>('launch', {'pkg': g.pkg}) ?? false;
                  _log(ok ? 'Membuka ${g.name}...' : '${g.name} belum terinstal');
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _card2({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: child,
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.white54))),
            Expanded(child: SelectableText(v)),
          ],
        ),
      );

  Widget _btn(String label, IconData icon, Color c, VoidCallback? onTap) => SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: c,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final off = _busy ? null : () {};
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('DIZS WARE',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 4)),
        actions: [
          IconButton(
            tooltip: 'Segarkan info',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
          children: [
            _card2(
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: _gold, size: 40),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dizs Ware', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        Text('Booster v1.0', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Text('BATERAI', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text(_info['battery']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _card2(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Info perangkat',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  _row('Merek', _info['brand']?.toString() ?? '-'),
                  _row('Model', _info['model']?.toString() ?? '-'),
                  _row('Android', '${_info['android'] ?? '-'} (SDK ${_info['sdk'] ?? '-'})'),
                  _row('Android ID', _info['androidId']?.toString() ?? '-'),
                  _row('Shizuku', _info['shizuku']?.toString() ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _btn('IZIN SHIZUKU', Icons.verified_user_outlined, const Color(0xFF8B5CFF),
                _busy ? null : _askShizuku),
            const SizedBox(height: 10),
            _btn('BOOST DEVICE', Icons.rocket_launch_outlined, _gold, _busy ? null : _boost),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset ke default'),
            ),
            if (off == null) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(color: _accent),
            ],
            const SizedBox(height: 14),
            Container(
              height: 280,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  _term.join('\n'),
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12, height: 1.4, color: _green),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
