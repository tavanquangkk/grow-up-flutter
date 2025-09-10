import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';
import 'package:grow_up/features/home/widgets/home_search_bar.dart';
import 'package:grow_up/features/home/widgets/upcoming_workshops_section.dart';
import 'package:grow_up/features/home/widgets/create_workshop_button.dart';
import 'package:grow_up/features/home/widgets/recommended_users_section.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List> _workshopsFuture;
  late Future<List> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() {
      _workshopsFuture = HomePageApiService.getUpComingWorkshops();
      _usersFuture = HomePageApiService.getRecommendedUsers();
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.logout();
              if (!mounted) return;
              context.go('/login');
            },
            child: Text('ログアウト', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              const Text(
                'GrowUp',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.surface,
          elevation: 1,
          shadowColor: AppColors.border,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _showLogoutDialog,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.logout, color: AppColors.error, size: 20),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeSearchBar(),
                    UpcomingWorkshopsSection(
                      future: _workshopsFuture,
                      onSeeAll: () async {
                        if (!mounted) return;
                        await context.push('/workshop-list');
                        if (mounted) _refreshData();
                      },
                    ),
                    const SizedBox(height: 24),
                    CreateWorkshopButton(onCreated: _refreshData),
                    const SizedBox(height: 24),
                    RecommendedUsersSection(future: _usersFuture),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
