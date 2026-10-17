import 'dart:convert';
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
  Map<String, int> _historyData = {};

  bool _isAudioEnabled = true;
  bool _isImageBackgroundEnabled = true; // Naya Background Theme state
  bool _isProcessingTap = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadData();

    _audioPlayer.onPlayerComplete.listen((event) {
      _isProcessingTap = false;
    });
  }

  void _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    List<String> months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    final todayStr = "${now.day} ${months[now.month - 1]} ${now.year}";

    setState(() {
      _lifetimeTotal = prefs.getInt('lifetime') ?? 0;
      _lastDate = prefs.getString('lastDate') ?? todayStr;

      // Load switch preferences
      _isAudioEnabled = prefs.getBool('isAudioEnabled') ?? true;
      _isImageBackgroundEnabled =
          prefs.getBool('isImageBackgroundEnabled') ?? true;

      // History data load
      String historyJson = prefs.getString('historyData') ?? '{}';
      Map<String, dynamic> decoded = jsonDecode(historyJson);
      _historyData = decoded.map((key, value) => MapEntry(key, value as int));

      if (_lastDate == todayStr) {
        _todayTotal = prefs.getInt('today') ?? 0;
      } else {
        _todayTotal = 0;
        _lastDate = todayStr;
      }

      _historyData[todayStr] = _todayTotal;
    });
  }

  void _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('lifetime', _lifetimeTotal);
    prefs.setInt('today', _todayTotal);
    prefs.setString('lastDate', _lastDate);

    // Save switch preferences
    prefs.setBool('isAudioEnabled', _isAudioEnabled);
    prefs.setBool('isImageBackgroundEnabled', _isImageBackgroundEnabled);

    _historyData[_lastDate] = _todayTotal;
    prefs.setString('historyData', jsonEncode(_historyData));
  }

  void _handleTap() async {
    if (_isProcessingTap) return;

    _isProcessingTap = true;

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

      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('bell.mp3'));
    } else {
      HapticFeedback.lightImpact();

      if (_isAudioEnabled) {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('radha.mp3'));
      } else {
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
      backgroundColor: Colors.black, // Default dark background
      body: Stack(
        children: [
          // Background UI: Conditional Background Image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: _isImageBackgroundEnabled
                ? const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/main_bg.jpg'),
                      fit: BoxFit.cover,
                    ),
                  )
                : const BoxDecoration(
                    color: Color(
                        0xFF0A0A0A), // Ekdum deep dark blackish grey theme
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
                  // Top Bar: History Button & Switches
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // History Button
                        IconButton(
                          icon: const Icon(Icons.history,
                              color: Colors.white, size: 28),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    HistoryScreen(historyData: _historyData),
                              ),
                            );
                          },
                        ),

                        // Switches Column (Voice and Theme)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Audio Toggle
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
                                      _saveData();
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Background Toggle
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
                                    "Background Image",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14),
                                  ),
                                  const SizedBox(width: 10),
                                  Switch(
                                    value: _isImageBackgroundEnabled,
                                    activeColor: const Color(0xFFD4AF37),
                                    onChanged: (value) {
                                      setState(() {
                                        _isImageBackgroundEnabled = value;
                                      });
                                      _saveData();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Middle Data Area
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

class HistoryScreen extends StatelessWidget {
  final Map<String, int> historyData;
  const HistoryScreen({super.key, required this.historyData});

  @override
  Widget build(BuildContext context) {
    List<String> dates = historyData.keys.toList().reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Counter History',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          String date = dates[index];
          int count = historyData[date] ?? 0;

          if (count == 0) return const SizedBox.shrink();

          int rounds = count ~/ 108;

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Radha Jaap',
                        style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 10),
                    const Text('On that day',
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text('$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w300)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(date,
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 10),
                    const Text('108 ×',
                        style: TextStyle(color: Colors.white54, fontSize: 14)),
                    const SizedBox(height: 5),
                    Text('$rounds',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w300)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
