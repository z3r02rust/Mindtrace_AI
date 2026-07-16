import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/ai_chat_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/home_screen.dart';
import 'screens/level_screen.dart';
import 'screens/people_screen.dart';
import 'screens/profile_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart'; // Import 1
import 'firebase_options.dart'; // Import 2

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stack) {
    // Firebase sozlanmagan platformalarda ilova lokal rejimda ishlayveradi.
    debugPrint('Firebase ishga tushmadi, lokal rejim yoqildi: $error');
    debugPrintStack(stackTrace: stack);
  }

  runApp(const MindTraceApp());
}

class MindTraceApp extends StatelessWidget {
  const MindTraceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..load(),
      child: MaterialApp(
        title: 'MindTrace AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    AnalysisScreen(),
    LevelScreen(),
    PeopleScreen(),
    AiChatScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: _screens),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Bosh sahifa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Tahlil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Daraja',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Insonlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'AI Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
