import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/utils/router.dart';
import 'package:grow_up/features/auth/screens/Login.dart';
import 'package:grow_up/features/auth/screens/Register.dart';
import 'package:grow_up/features/home/HomePage.dart';
import 'package:grow_up/features/home/MyWorkshopsScreen.dart';
import 'package:grow_up/features/home/ProfileScreen.dart';
import 'package:grow_up/core/theme/app_theme.dart';

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
  final String myUserId = 'me'; // TODO: ログインユーザーID取得

  List<Widget> get _screens => [
    HomePage(),
    MyWorkshopsScreen(),
    ProfileScreen(
      userId: 'me',
      onBack: () {
        setState(() {
          _selectedIndex = 0;
        });
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: '自分の勉強会',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'プロフィール'),
        ],
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerDelegate: goRouter.routerDelegate,
      routeInformationParser: goRouter.routeInformationParser,
      routeInformationProvider: goRouter.routeInformationProvider,
      title: 'Grow up',
      theme: ThemeData(primarySwatch: Colors.orange),
    );
  }
}
