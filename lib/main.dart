import 'package:flutter/material.dart';
import 'package:pitdeck/providers/badge_provider.dart';
import 'package:pitdeck/providers/favorite_provider.dart';
import 'package:pitdeck/providers/scroll_notifier.dart';
import 'package:pitdeck/screens/auth/auth_screen.dart';
import 'package:pitdeck/screens/main_screen.dart';
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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(MapboxConfig.accessToken);

  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final token = prefs.getString('token');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
        ChangeNotifierProvider(create: (_) => TradeProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => ScrollNotifier()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn, token: token),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final String? token;

  const MyApp({super.key, required this.isLoggedIn, this.token});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  bool _isInitializing = true;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    if (widget.isLoggedIn && widget.token != null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.getUserDetails();
      } catch (e) {
        print('Error fetching user details: $e');
      }
    }
    setState(() {
      _isInitializing = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CardProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
        ChangeNotifierProvider(create: (_) => TradeProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => BadgeProvider()),
        ChangeNotifierProvider(create: (_) => ScrollNotifier()),
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
        home: const MainWrapper(),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          Image.asset(
            'assets/images/racing_bg.jpg',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0A0A1A).withOpacity(0.7),
                  const Color(0xFF0A0A1A).withOpacity(0.9),
                  const Color(0xFF0A0A1A),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4B9FFF).withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: (_controller.value * 2 * pi) +
                                    (index * pi / 1.5),
                                child: Transform.translate(
                                  offset: Offset(
                                    sin(_controller.value * 2 * pi + index) *
                                        30,
                                    cos(_controller.value * 2 * pi + index) *
                                        30,
                                  ),
                                  child: Container(
                                    width: 80,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF4B9FFF),
                                        width: 1,
                                      ),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          const Color(0xFF4B9FFF)
                                              .withOpacity(0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFFF4B5C),
                      Color(0xFF4B9FFF),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'PITDECK',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF4B9FFF),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4B9FFF).withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Text(
                    'LOADING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                      letterSpacing: 4,
                    ),
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
