import 'package:flutter/material.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';
import 'package:grow_up/features/home/widgets/learning_skills_horizontal_list.dart';

typedef ProfileBackCallback = void Function();

class ProfileScreen extends StatefulWidget {
  final String userId;
  final ProfileBackCallback? onBack;
  const ProfileScreen({super.key, required this.userId, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = HomePageApiService.getUserProfile(widget.userId);
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = HomePageApiService.getUserProfile(widget.userId);
    });
  }

  // 画像アップロードダイアログを表示するメソッド
  void _showImageUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.photo_camera, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'プロフィール画像を変更',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '新しいプロフィール画像を選択してください',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // カメラから撮影
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImageFromCamera();
                          },
                          icon: Icon(
                            Icons.camera_alt,
                            color: AppColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'カメラ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // ギャラリーから選択
                  Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _pickImageFromGallery();
                          },
                          icon: Icon(
                            Icons.photo_library,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'ギャラリー',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'キャンセル',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  // カメラから画像を選択
  void _pickImageFromCamera() {
    // TODO: image_picker パッケージを使用してカメラから画像を取得
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('カメラ機能は準備中です'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  // ギャラリーから画像を選択
  void _pickImageFromGallery() {
    // TODO: image_picker パッケージを使用してギャラリーから画像を取得
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ギャラリー機能は準備中です'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
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
                expandedHeight: 140, // 120 → 140に増加してプロフィール画像のスペースを確保
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: Container(
                    // 新デザイン: 円形の背景を追加
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // 背景画像またはグラデーション
                      Positioned.fill(
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
                            : Container(
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
                              ),
                      ),
                      // 半透明のオーバーレイ
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // プロフィール画像を最前面に配置
                      Positioned(
                        bottom: -30,
                        left: 24,
                        child: GestureDetector(
                          onTap: () {
                            _showImageUploadDialog(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundColor: AppColors.secondary,
                                  child: userData['profileImageUrl'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            userData['profileImageUrl'],
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Icon(
                                                    Icons.person,
                                                    size: 35,
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
                                            fontSize: 25,
                                          ),
                                        ),
                                ),
                                // カメラアイコン
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile content
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 40), // 50 → 40に調整
                  child: Column(
                    children: [
                      // User name and info（プロフィール画像は削除）
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // 左寄せに変更
                          children: [
                            // ユーザー名を左寄せで配置
                            Text(
                              userData['name'] ?? 'ユーザー',
                              style: TextStyle(
                                fontSize: 24,
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

                            SizedBox(height: 20),
                            // Stats and actions row
                            Row(
                              children: [
                                // フォロー中
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start, // 左寄せ
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start, // 左寄せ
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

                            // 学習したいスキル (横スクロール表示)
                            LearningSkillsHorizontalList(
                              rawSkills:
                                  (userData['learningSkills'] ?? []) as List,
                              onSkillAdded: _refreshProfile,
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
