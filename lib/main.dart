import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const JaapApp());
}

class JaapApp extends StatelessWidget {
  const JaapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Radha Jaap',
      theme: ThemeData(brightness: Brightness.dark),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3500), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const JaapScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/splash_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class JaapScreen extends StatefulWidget {
  const JaapScreen({super.key});

  @override
  State<JaapScreen> createState() => _JaapScreenState();
}

class _JaapScreenState extends State<JaapScreen> {
  int _lifetimeTotal = 0;
  int _todayTotal = 0;
  String _lastDate = "";

  bool _isAudioEnabled = true;
  DateTime? _lastTapTime;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Data phone ki memory se load karne ke liye
  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    setState(() {
      _lifetimeTotal = prefs.getInt('lifetime') ?? 0;
      _lastDate = prefs.getString('lastDate') ?? "";

      // Agar date aaj ki hai toh today ka data load karo, warna 0 kar do
      if (_lastDate == todayStr) {
        _todayTotal = prefs.getInt('today') ?? 0;
      } else {
        _todayTotal = 0;
        _lastDate = todayStr;
      }
    });
  }

  // Har tap par data save karne ke liye
  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lifetime', _lifetimeTotal);
    prefs.setInt('today', _todayTotal);
    prefs.setString('lastDate', _lastDate);
  }

  void _handleTap() async {
    final now = DateTime.now();

    // 1-second pause logic (debounce)
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 1000) {
      return;
    }
    _lastTapTime = now;

    setState(() {
      _lifetimeTotal++;
      _todayTotal++;
    });

    _saveData();

    // Audio play logic (agar switch ON hai)
    if (_isAudioEnabled) {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('radha.mp3'));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1-108 loop logic
    int currentCount =
        (_todayTotal % 108 == 0 && _todayTotal > 0) ? 108 : (_todayTotal % 108);
    if (_todayTotal == 0) currentCount = 0;

    // 108 * x rounds logic (integer division se float automatically handle ho jayega)
    int todayRounds = _todayTotal ~/ 108;
    int lifetimeRounds = _lifetimeTotal ~/ 108;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/main_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Tap Area Overlay
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Bar: Audio Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFD4AF37), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                "Maharaj Ji's Voice",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: _isAudioEnabled,
                                activeColor: const Color(0xFFD4AF37),
                                onChanged: (value) {
                                  setState(() {
                                    _isAudioEnabled = value;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Middle: Main 1-108 Counter aur Stats (Screenshots wale layout par based)
                  Column(
                    children: [
                      Text(
                        '$currentCount',
                        style: const TextStyle(
                            fontSize: 100,
                            color: Colors.white,
                            fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 20),

                      // Today Stats
                      Text(
                        'Today $_todayTotal',
                        style: const TextStyle(
                            fontSize: 22, color: Colors.white70),
                      ),
                      Text(
                        '108 × $todayRounds',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white50),
                      ),

                      const SizedBox(height: 10),
                      Container(width: 150, height: 1, color: Colors.white24),
                      const SizedBox(height: 10),

                      // Lifetime Stats
                      Text(
                        'Lifetime $_lifetimeTotal',
                        style: const TextStyle(
                            fontSize: 20, color: Colors.white60),
                      ),
                      Text(
                        '108 × $lifetimeRounds',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.white38),
                      ),
                    ],
                  ),

                  // Bottom: Instruction
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 40),
                    margin: const EdgeInsets.only(bottom: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132F2B).withOpacity(0.9),
                      border:
                          Border.all(color: const Color(0xFFD4AF37), width: 1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'जाप के लिए स्क्रीन पर कहीं भी टैप करें',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
