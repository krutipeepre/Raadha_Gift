import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

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
  int _counter = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  void _incrementCounter() async {
    setState(() {
      _counter++;
    });
    await _audioPlayer.stop();
    await _audioPlayer.play(AssetSource('radha.mp3'));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _incrementCounter,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/main_bg.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1B0A).withValues(alpha: 0.85),
                    border:
                        Border.all(color: const Color(0xFFD4AF37), width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_counter',
                        style: const TextStyle(
                            fontSize: 48,
                            color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.bold),
                      ),
                      const Text('१०८',
                          style:
                              TextStyle(fontSize: 20, color: Colors.white70)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132F2B).withValues(alpha: 0.9),
                    border:
                        Border.all(color: const Color(0xFFD4AF37), width: 1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'जाप के लिए टैप करें',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
