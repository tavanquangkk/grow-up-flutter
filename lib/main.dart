import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/utils/router.dart';
import 'package:grow_up/features/auth/screens/Login.dart';
import 'package:grow_up/features/auth/screens/Register.dart';
import 'package:grow_up/features/home/HomePage.dart';
import 'package:grow_up/features/home/MyWorkshopsScreen.dart';
import 'package:grow_up/features/home/ProfileScreen.dart';
import 'package:grow_up/screens/ChatScreen.dart';
import 'package:grow_up/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web用のスクロール設定クラス
class WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

void main() {
  runApp(const MyApp());
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
  }

  List<Widget> get _screens => [
    HomePage(),
    MyWorkshopsScreen(),
    _currentUserId != null
        ? ProfileScreen(
            userId: _currentUserId!,
            onBack: () {
              setState(() {
                _selectedIndex = 0;
              });
            },
          )
        : const Center(child: CircularProgressIndicator()),
    const ChatScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // デバッグ用ログ
    print('Tab tapped: $index');

    // 各タブに対応するルートに遷移（オプション）
    switch (index) {
      case 0:
        // ホーム画面への明示的な遷移は不要（既にMainScaffold内で管理）
        break;
      case 1:
        // 勉強会画面
        break;
      case 2:
        // プロフィール画面
        break;
      case 3:
        // チャット画面
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: '自分の勉強会',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'チャット'),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: WebScrollBehavior(),
      child: MaterialApp.router(
        routerDelegate: goRouter.routerDelegate,
        routeInformationParser: goRouter.routeInformationParser,
        routeInformationProvider: goRouter.routeInformationProvider,
        title: 'Grow up',
        theme: AppTheme.lightTheme,
        scrollBehavior: WebScrollBehavior(),
      ),
    );
  }
}
