import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isProcessingTap = false; // Naya Lock System
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadData();

    // Background listener: Jaise hi audio khatam hoga, screen automatically unlock ho jayegi
    _audioPlayer.onPlayerComplete.listen((event) {
      _isProcessingTap = false;
    });
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";

    setState(() {
      _lifetimeTotal = prefs.getInt('lifetime') ?? 0;
      _lastDate = prefs.getString('lastDate') ?? "";

      if (_lastDate == todayStr) {
        _todayTotal = prefs.getInt('today') ?? 0;
      } else {
        _todayTotal = 0;
        _lastDate = todayStr;
      }
    });
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lifetime', _lifetimeTotal);
    prefs.setInt('today', _todayTotal);
    prefs.setString('lastDate', _lastDate);
  }

  void _handleTap() async {
    // Agar screen pehle se locked hai (audio chal raha hai ya 1-sec pause hai), toh naya tap ignore karo
    if (_isProcessingTap) return;

    _isProcessingTap = true; // Screen ko lock kar diya

    setState(() {
      _lifetimeTotal++;
      _todayTotal++;
    });

    _saveData();

    bool isRoundComplete = _todayTotal % 108 == 0 && _todayTotal > 0;

    if (isRoundComplete) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 150),
          () => HapticFeedback.heavyImpact());
      Future.delayed(const Duration(milliseconds: 300),
          () => HapticFeedback.heavyImpact());

      if (_isAudioEnabled) {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('bell.mp3'));
        // Screen unlock hone ka kaam ab onPlayerComplete listener khud handle karega
      } else {
        // Agar aawaz band hai, toh exactly 1 second baad screen unlock karo
        Future.delayed(const Duration(seconds: 1), () {
          _isProcessingTap = false;
        });
      }
    } else {
      HapticFeedback.lightImpact();

      if (_isAudioEnabled) {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('radha.mp3'));
        // Screen unlock hone ka kaam ab onPlayerComplete listener khud handle karega
      } else {
        // Agar aawaz band hai, toh exactly 1 second baad screen unlock karo
        Future.delayed(const Duration(seconds: 1), () {
          _isProcessingTap = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int currentCount =
        (_todayTotal % 108 == 0 && _todayTotal > 0) ? 108 : (_todayTotal % 108);
    if (_todayTotal == 0) currentCount = 0;

    int todayRounds = _todayTotal ~/ 108;
    int lifetimeRounds = _lifetimeTotal ~/ 108;

    return Scaffold(
      body: Stack(
        children: [
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
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
                      Text(
                        'Today $_todayTotal',
                        style: const TextStyle(
                            fontSize: 22, color: Colors.white70),
                      ),
                      Text(
                        '108 × $todayRounds',
                        style: const TextStyle(
                            fontSize: 18, color: Colors.white54),
                      ),
                      const SizedBox(height: 10),
                      Container(width: 150, height: 1, color: Colors.white24),
                      const SizedBox(height: 10),
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
