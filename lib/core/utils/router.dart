import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/features/auth/screens/Login.dart';
import 'package:grow_up/features/auth/screens/Register.dart';
import 'package:grow_up/features/home/CreateWorkshopScreen.dart';
import 'package:grow_up/features/home/HomePage.dart';
import 'package:grow_up/features/home/ProfileScreen.dart';
import 'package:grow_up/features/home/WorkshopListScreen.dart';
import 'package:grow_up/main.dart';

final goRouter = GoRouter(
  // アプリが起動した時
  initialLocation: '/login',
  // パスと画面の組み合わせ
  routes: [
    GoRoute(
      path: '/',
      name: 'initial',
      pageBuilder: (context, state) {
        return MaterialPage(key: state.pageKey, child: const MainScaffold());
      },
    ),
    // ex) アカウント画面
    GoRoute(
      path: '/login',
      name: 'login',
      pageBuilder: (context, state) {
        return MaterialPage(key: state.pageKey, child: const LoginScreen());
      },
    ),
    // ex) アカウント詳細画面
    GoRoute(
      path: '/register',
      name: 'register',
      pageBuilder: (context, state) {
        return MaterialPage(key: state.pageKey, child: Register());
      },
    ),
    // 勉強会作成画面
    GoRoute(
      path: '/create-workshop',
      name: 'create-workshop',
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: const CreateWorkshopScreen(),
        );
      },
    ),
    // 勉強会一覧画面
    GoRoute(
      path: '/workshop-list',
      name: 'workshop-list',
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: const WorkshopListScreen(),
        );
      },
    ),
    // プロフィール画面
    GoRoute(
      path: '/profile/:userId',
      name: 'profile',
      pageBuilder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return MaterialPage(
          key: state.pageKey,
          child: ProfileScreen(userId: userId),
        );
      },
    ),
  ],
  // 遷移ページがないなどのエラーが発生した時に、このページに行く
);
