import 'package:flutter/material.dart';
import 'package:pitdeck/providers/badge_provider.dart';
import 'package:pitdeck/providers/favorite_provider.dart';
import 'package:pitdeck/providers/scroll_notifier.dart';
import 'package:pitdeck/screens/auth/auth_screen.dart';
import 'package:pitdeck/screens/main_screen.dart';
import 'package:pitdeck/screens/user_profile_screen.dart';
import 'package:pitdeck/services/daily_reward_service.dart';
import 'package:provider/provider.dart';
import 'package:pitdeck/providers/auth_provider.dart';
import 'package:pitdeck/providers/user_provider.dart';
import 'package:pitdeck/providers/navigation_provider.dart';
import 'package:pitdeck/providers/card_provider.dart';
import 'package:pitdeck/providers/listing_provider.dart';
import 'package:pitdeck/providers/trade_provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:pitdeck/config/mapbox_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show pi, sin, cos;
import 'package:pitdeck/screens/main_wrapper.dart';
import 'package:pitdeck/services/cache_service.dart';
import 'package:pitdeck/providers/achievement_provider.dart';
import 'package:pitdeck/services/quest_service.dart';
import 'package:firebase_core/firebase_core.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(MapboxConfig.accessToken);
  await SharedPreferences.getInstance();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
        ChangeNotifierProvider(create: (_) => TradeProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => ScrollNotifier()),
        ChangeNotifierProvider(create: (_) => AchievementProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => DailyRewardService()),
        ChangeNotifierProvider(create: (_) => QuestService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          textTheme: ThemeData.dark().textTheme.copyWith(
                bodyLarge: const TextStyle(fontFamily: 'Orbitron'),
                bodyMedium: const TextStyle(fontFamily: 'Orbitron'),
                titleLarge: const TextStyle(fontFamily: 'Orbitron'),
                titleMedium: const TextStyle(fontFamily: 'Orbitron'),
                titleSmall: const TextStyle(fontFamily: 'Orbitron'),
              ),
        ),
        home: Builder(
          builder: (context) => FutureBuilder(
            future: Future.wait([
              CacheService().initialize(),
              Provider.of<UserProvider>(context, listen: false)
                  .initializeFromCache(),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final prefs = snapshot.data?[0] as SharedPreferences;
                return prefs.getBool('isLoggedIn') ?? false
                    ? const MainWrapper()
                   : const AuthScreen();
               // : const MainWrapper();
                // : const UserProfileScreen(userId: '1');
              }

              return const Scaffold(
                backgroundColor: Color(0xFF040412),
                body: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF4B9FFF),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // Start the animation
    _controller.forward();

    // Start repeating after the first forward animation
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.repeat();
      }
    });

    // Navigate after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween =
                  Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3D1212),
                  Color(0xFF0A0A1A),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.speed,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFF3B82F6),
                      Color(0xFFEFB344),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'PITDECK',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Collect • Explore • Compete',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    color: Color(0xFF3B82F6),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 200,
                  child: AnimatedBuilder(
                    animation: _loadingAnimation,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: LoadingTrackPainter(
                          _loadingAnimation.value,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFEF4444),
                              Color(0xFF3B82F6),
                            ],
                          ),
                        ),
                        size: const Size(
                          200,
                          20,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoadingTrackPainter extends CustomPainter {
  final double progress;
  final Gradient gradient;

  LoadingTrackPainter(this.progress, {required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..shader =
          gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      trackPaint,
    );

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width * progress, size.height / 2),
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
