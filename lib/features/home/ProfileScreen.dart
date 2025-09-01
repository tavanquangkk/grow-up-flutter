import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';

typedef ProfileBackCallback = void Function();

class ProfileScreen extends StatefulWidget {
  final String userId;
  final ProfileBackCallback? onBack;
  const ProfileScreen({super.key, required this.userId, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: HomePageApiService.getUserProfile(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final userData = snapshot.data?['data'];
          if (userData == null) {
            return Center(child: Text('ユーザー情報が見つかりません'));
          }

          return CustomScrollView(
            slivers: [
              // AppBar with background image
              SliverAppBar(
                expandedHeight: 150, // 200 → 150に減らす
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: userData['backgroundImageUrl'] != null
                          ? null
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [AppColors.primary, AppColors.secondary],
                            ),
                    ),
                    child: userData['backgroundImageUrl'] != null
                        ? Image.network(
                            userData['backgroundImageUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : null,
                  ),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!(); // BottomNav用のコールバック（自分のプロフィール）
                    } else {
                      Navigator.of(context).pop(); // 他人のプロフィール画面から戻る
                    }
                  },
                ),
              ),

              // Profile content
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: Offset(0, -40), // -50 → -40に調整
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        padding: EdgeInsets.all(3), // 4 → 3に調整
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 45, // 50 → 45に減らす
                          backgroundColor: AppColors.secondary,
                          child: userData['profileImageUrl'] != null
                              ? ClipOval(
                                  child: Image.network(
                                    userData['profileImageUrl'],
                                    width: 90, // 100 → 90に調整
                                    height: 90, // 100 → 90に調整
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.person,
                                        size: 45, // 50 → 45に調整
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                )
                              : Text(
                                  (userData['name'] ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 32, // 36 → 32に調整
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 12), // 16 → 12に調整
                      // User name and info
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              userData['name'] ?? 'ユーザー',
                              style: TextStyle(
                                fontSize: 24, // 28 → 24に調整
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8),
                            if (userData['department'] != null ||
                                userData['position'] != null)
                              Text(
                                [
                                  userData['department'],
                                  userData['position'],
                                ].where((e) => e != null).join(' • '),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),

                            SizedBox(height: 20), // 24 → 20に調整
                            // Stats and actions row
                            Row(
                              children: [
                                // フォロー中
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${userData['followingCount'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'フォロー中',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // フォロワー
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${userData['followerCount'] ?? 0}',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'フォロワー',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // DMボタン
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: DM機能
                                    },
                                    icon: Icon(Icons.message, size: 18),
                                    label: Text('DM'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 24), // 32 → 24に調整
                      // Content sections
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 自己紹介
                            _buildSection(
                              '自己紹介',
                              Icons.person_outline,
                              userData['introduction'] ?? '自己紹介はまだ設定されていません',
                            ),

                            SizedBox(height: 24),

                            // 学習したいスキル
                            _buildSkillsSection(
                              '学習したいスキル',
                              Icons.school_outlined,
                              userData['learningSkills'] ?? [],
                              AppColors.primary,
                            ),

                            SizedBox(height: 24),

                            // シェアできるスキル
                            _buildSkillsSection(
                              'シェアできるスキル',
                              Icons.share_outlined,
                              userData['teachableSkills'] ?? [],
                              AppColors.secondary,
                            ),

                            SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsSection(
    String title,
    IconData icon,
    List skills,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: skills.isEmpty
              ? Text(
                  '${title}はまだ設定されていません',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills.map<Widget>((skill) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        skill.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
