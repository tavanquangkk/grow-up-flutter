import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';
import 'package:grow_up/features/home/widgets/learning_skills_horizontal_list.dart';
import 'package:grow_up/features/home/FollowingUsersScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String? _currentUserId;
  int? _actualFollowingCount;

  @override
  void initState() {
    super.initState();
    _profileFuture = HomePageApiService.getUserProfile(widget.userId);
    _loadCurrentUserId().then((_) => _loadFollowingCount());
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('userId');
    });
  }

  Future<void> _loadFollowingCount() async {
    // 自分のプロフィールの場合のみフォロー中の数を取得
    if (_isMyProfile) {
      try {
        final followingUsers = await HomePageApiService.getFollowingUsers();
        setState(() {
          _actualFollowingCount = followingUsers.length;
        });
      } catch (e) {
        // エラーの場合はAPIから取得した値を使用
        print('フォロー中一覧の取得に失敗: $e');
      }
    }
  }

  bool get _isMyProfile =>
      _currentUserId != null && _currentUserId == widget.userId;

  // フォロー中の数を取得する（実際の数が取得できていればそれを使用、そうでなければAPIから取得した値を使用）
  int _getFollowingCount(Map<String, dynamic> userData) {
    if (_isMyProfile && _actualFollowingCount != null) {
      return _actualFollowingCount!;
    }
    return userData['followingCount'] ?? 0;
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = HomePageApiService.getUserProfile(widget.userId);
    });
    _loadFollowingCount(); // フォロー中の数も更新
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

  // 連絡先ダイアログを表示するメソッド
  void _showContactDialog(BuildContext context, Map<String, dynamic> userData) {
    final userEmail = userData['email'] ?? '';
    final userName = userData['name'] ?? 'ユーザー';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.email, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                '連絡先情報',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${userName}さんへの連絡方法',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'こちらのメールに連絡してくださいね✉️',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userEmail.isNotEmpty ? userEmail : 'メールアドレスが設定されていません',
                        style: TextStyle(
                          fontSize: 16,
                          color: userEmail.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (userEmail.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: userEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('メールアドレスをコピーしました'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.copy,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        tooltip: 'コピー',
                      ),
                  ],
                ),
              ),
              if (userEmail.isNotEmpty) ...[
                SizedBox(height: 12),
                Text(
                  '💡 タップしてメールアドレスをコピーできます',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '閉じる',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            if (userEmail.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: userEmail));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('メールアドレスをコピーしました'),
                      backgroundColor: AppColors.primary,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(Icons.copy, size: 18),
                label: Text('コピー'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
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
                                  child: GestureDetector(
                                    onTap:
                                        _isMyProfile &&
                                            _getFollowingCount(userData) > 0
                                        ? () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    FollowingUsersScreen(),
                                              ),
                                            );
                                            // 画面から戻った時にフォロー中の数を更新
                                            _loadFollowingCount();
                                          }
                                        : null,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color:
                                            _isMyProfile &&
                                                _getFollowingCount(userData) > 0
                                            ? AppColors.primary.withOpacity(
                                                0.05,
                                              )
                                            : Colors.transparent,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start, // 左寄せ
                                        children: [
                                          Text(
                                            '${_getFollowingCount(userData)}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  _isMyProfile &&
                                                      _getFollowingCount(
                                                            userData,
                                                          ) >
                                                          0
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                'フォロー中',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              if (_isMyProfile &&
                                                  _getFollowingCount(userData) >
                                                      0)
                                                Icon(
                                                  Icons.chevron_right,
                                                  size: 16,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
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

                                // DMボタン (他の人の場合のみ表示)
                                if (!_isMyProfile)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showContactDialog(context, userData);
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
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
                              isMyProfile: _isMyProfile,
                            ),

                            SizedBox(height: 24),

                            // シェアできるスキル
                            _buildTeachableSkillsSection(
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

  Widget _buildTeachableSkillsSection(
    String title,
    IconData icon,
    List skills,
    Color color,
  ) {
    // skills: List<Map> or List<String>
    // 1. Extract skill names, deduplicate, sort
    final skillNames = skills
        .map(
          (s) => s is Map && s['name'] != null
              ? s['name'].toString().replaceAll('"', '').trim()
              : s.toString().replaceAll('"', '').trim(),
        )
        .where((n) => n.isNotEmpty)
        .toSet()
        .toList();
    skillNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            // Add teachable skill button (only for own profile)
            if (_isMyProfile)
              IconButton(
                tooltip: 'スキルを追加',
                onPressed: () => _openAddTeachableSkillDialog(context),
                icon: Container(
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Icon(Icons.add, size: 18, color: color),
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
          child: skillNames.isEmpty
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
                  children: skillNames.map<Widget>((skillName) {
                    return Chip(
                      avatar: Icon(Icons.star, color: color, size: 18),
                      label: Text(
                        skillName,
                        style: TextStyle(
                          fontSize: 14,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: color.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Future<void> _openAddTeachableSkillDialog(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final list = await HomePageApiService.getSkillsList();
      if (context.mounted) Navigator.of(context).pop(); // close loader

      // Normalize & deduplicate (case-insensitive)
      final names = <String>{};
      for (final m in list) {
        final raw = m['name']?.toString() ?? '';
        final cleaned = raw.replaceAll('"', '').trim();
        if (cleaned.isNotEmpty) names.add(cleaned);
      }
      final allNames = names.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      String? selected;

      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text('シェアできるスキルを追加'),
                content: SizedBox(
                  width: 340,
                  height: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '追加したいスキルを選択',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: allNames.length,
                          itemBuilder: (_, i) {
                            final n = allNames[i];
                            // Check against current teachableSkills in _profileFuture
                            final isSelected = selected == n;
                            return ListTile(
                              dense: true,
                              title: Text(
                                n,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              leading: isSelected
                                  ? Icon(
                                      Icons.radio_button_checked,
                                      color: AppColors.secondary,
                                      size: 20,
                                    )
                                  : const Icon(Icons.circle_outlined, size: 20),
                              selected: isSelected,
                              selectedTileColor: AppColors.secondary
                                  .withOpacity(0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: () => setState(() => selected = n),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: selected == null
                        ? null
                        : () async {
                            try {
                              await HomePageApiService.addTeachableSkill(
                                selected!,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              _refreshProfile();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"$selected" を追加しました'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('追加に失敗: $e')),
                                );
                              }
                            }
                          },
                    child: const Text('追加'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // ensure any loader closed
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('スキル一覧取得に失敗: $e')));
      }
    }
  }
}
