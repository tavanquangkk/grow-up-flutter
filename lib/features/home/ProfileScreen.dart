import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';
import 'package:grow_up/features/home/widgets/learning_skills_horizontal_list.dart';
import 'package:grow_up/features/home/FollowingUsersScreen.dart';
import 'package:grow_up/features/home/FollowerUsersScreen.dart';
import 'package:grow_up/features/home/EditProfileScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

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
  int? _actualFollowerCount;

  bool _isFollowingOther = false; // viewing someone else & following
  bool _followProcessing = false;
  @override
  void initState() {
    super.initState();
    _profileFuture = HomePageApiService.getUserProfile(widget.userId);
    _loadCurrentUserId().then((_) {
      _loadFollowingCount();
      _loadFollowerCount();
    });
    _initFollowState();
  }

  Future<void> _initFollowState() async {
    try {
      // 自分のプロフィールなら不要
      if (widget.userId.isEmpty) return;
      // fetch my profile to compare id if not already
      final my = await HomePageApiService.fetchMyProfile();
      final myId = my['data']?['id']?.toString();
      if (myId != null && myId == widget.userId) return; // 自分
      final followingIds = await HomePageApiService.fetchFollowingIds();
      if (mounted) {
        setState(() {
          _isFollowingOther = followingIds.contains(widget.userId);
        });
      }
    } catch (_) {
      // 静かに無視（フォロー状態が分からなくても致命的ではない）
    }
  }

  Future<void> _handleFollowOther(String userId) async {
    if (_followProcessing) return;
    setState(() {
      _followProcessing = true;
      _isFollowingOther = true; // optimistic
    });
    try {
      await HomePageApiService.followUser(userId);
      _loadFollowerCount();
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowingOther = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('フォロー失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _followProcessing = false);
    }
  }

  Future<void> _handleUnfollowOther(String userId) async {
    if (_followProcessing) return;
    setState(() {
      _followProcessing = true;
      _isFollowingOther = false; // optimistic
    });
    try {
      await HomePageApiService.unfollowUser(userId);
      _loadFollowerCount();
    } catch (e) {
      if (mounted) {
        setState(() => _isFollowingOther = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('フォロー解除失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _followProcessing = false);
    }
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

  Future<void> _loadFollowerCount() async {
    // 自分のプロフィールの場合のみフォロワーの数を取得
    if (_isMyProfile) {
      try {
        final followerUsers = await HomePageApiService.getFollowerUsers();
        setState(() {
          _actualFollowerCount = followerUsers.length;
        });
      } catch (e) {
        // エラーの場合はAPIから取得した値を使用
        print('フォロワー一覧の取得に失敗: $e');
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

  // フォロワーの数を取得する（実際の数が取得できていればそれを使用、そうでなければAPIから取得した値を使用）
  int _getFollowerCount(Map<String, dynamic> userData) {
    if (_isMyProfile && _actualFollowerCount != null) {
      return _actualFollowerCount!;
    }
    return userData['followerCount'] ?? 0;
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = HomePageApiService.getUserProfile(widget.userId);
    });
    _loadFollowingCount(); // フォロー中の数も更新
    _loadFollowerCount(); // フォロワーの数も更新
  }

  // 画像アップロードボトムシート
  void _showImageUploadDialog(BuildContext context) {
    if (!_isMyProfile) return; // 自分以外は不可
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AvatarPickerSheet(
        onPicked: (path) async {
          Navigator.of(ctx).pop();
          await _uploadAvatar(path);
        },
      ),
    );
  }

  Future<void> _uploadAvatar(String filePath) async {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final resp = await HomePageApiService.updateMyAvatar(filePath);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp['message'] ?? 'プロフィール画像を更新しました')),
      );
      _refreshProfile();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('画像更新に失敗: $e')));
    }
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
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }
          final userData = snapshot.data?['data'];
          if (userData == null) {
            return const Center(child: Text('ユーザー情報が見つかりません'));
          }

          // Spacing & layout constants (tuned for compact, balanced layout)
          const double avatarRadius = 44;
          const double headerHeight = 160;
          const double hPad = 20; // global horizontal padding
          const double topOffsetAfterAvatar =
              12; // space above first content after avatar
          const double sectionGap = 20; // between major sections
          const double minorGap = 12; // small vertical gap

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: headerHeight,
                    pinned: true,
                    backgroundColor: AppColors.primary,
                    leading: IconButton(
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
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
                        fit: StackFit.expand,
                        children: [
                          userData['backgroundImageUrl'] != null
                              ? Image.network(
                                  userData['backgroundImageUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildFallbackHeaderBg(),
                                )
                              : _buildFallbackHeaderBg(),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.35),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: avatarRadius + topOffsetAfterAvatar,
                        left: hPad,
                        right: hPad,
                        bottom: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User name and info（プロフィール画像は削除）
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ユーザー名を左寄せで配置
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      userData['name'] ?? 'ユーザー',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (_isMyProfile)
                                    IconButton(
                                      tooltip: 'プロフィールを編集',
                                      icon: Icon(
                                        Icons.edit,
                                        color: AppColors.primary,
                                      ),
                                      onPressed: () async {
                                        // 編集画面へ遷移し、更新済みデータ(Map)が返ってきたら局所的に反映
                                        final updated = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditProfileScreen(
                                              initialData:
                                                  Map<String, dynamic>.from(
                                                    userData,
                                                  ),
                                            ),
                                          ),
                                        );
                                        if (updated != null &&
                                            updated is Map<String, dynamic>) {
                                          // userData を直接書き換えると FutureBuilder の snapshot には影響しないため再取得
                                          _refreshProfile();
                                        }
                                      },
                                    ),
                                ],
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
                              if (_isMyProfile)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _StatTile(
                                        label: 'フォロー中',
                                        value: _getFollowingCount(userData),
                                        highlight:
                                            _getFollowingCount(userData) > 0,
                                        onTap: _getFollowingCount(userData) > 0
                                            ? () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FollowingUsersScreen(),
                                                  ),
                                                );
                                                _loadFollowingCount();
                                                _loadFollowerCount();
                                              }
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: _StatTile(
                                        label: 'フォロワー',
                                        value: _getFollowerCount(userData),
                                        highlight:
                                            _getFollowerCount(userData) > 0,
                                        onTap: _getFollowerCount(userData) > 0
                                            ? () async {
                                                await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FollowerUsersScreen(),
                                                  ),
                                                );
                                                _loadFollowerCount();
                                              }
                                            : null,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 44,
                                        child: _followProcessing
                                            ? Center(
                                                child: SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                ),
                                              )
                                            : ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      _isFollowingOther
                                                      ? AppColors.surface
                                                      : AppColors.primary,
                                                  foregroundColor:
                                                      _isFollowingOther
                                                      ? AppColors.primary
                                                      : Colors.white,
                                                  elevation: _isFollowingOther
                                                      ? 0
                                                      : 2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          24,
                                                        ),
                                                    side: _isFollowingOther
                                                        ? BorderSide(
                                                            color: AppColors
                                                                .primary
                                                                .withOpacity(
                                                                  0.4,
                                                                ),
                                                          )
                                                        : BorderSide.none,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  if (_isFollowingOther) {
                                                    _handleUnfollowOther(
                                                      widget.userId,
                                                    );
                                                  } else {
                                                    _handleFollowOther(
                                                      widget.userId,
                                                    );
                                                  }
                                                },
                                                child: Text(
                                                  _isFollowingOther
                                                      ? 'フォロー中'
                                                      : 'フォローする',
                                                ),
                                              ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
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

                          SizedBox(height: minorGap + 8),
                          // Content sections
                          // Main content sections
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 自己紹介
                              _buildSection(
                                '自己紹介',
                                Icons.person_outline,
                                userData['introduction'] ?? '自己紹介はまだ設定されていません',
                              ),

                              SizedBox(height: sectionGap),

                              // 学習したいスキル (横スクロール表示)
                              LearningSkillsHorizontalList(
                                rawSkills:
                                    (userData['learningSkills'] ?? []) as List,
                                onSkillAdded: _refreshProfile,
                                isMyProfile: _isMyProfile,
                              ),

                              SizedBox(height: sectionGap),

                              // シェアできるスキル
                              _buildTeachableSkillsSection(
                                'シェアできるスキル',
                                Icons.share_outlined,
                                userData['teachableSkills'] ?? [],
                                AppColors.secondary,
                              ),

                              SizedBox(height: sectionGap + 4),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // フローティングアバター
              Positioned(
                top: headerHeight - avatarRadius - 10,
                left: hPad,
                child: _FloatingAvatar(
                  radius: avatarRadius,
                  imageUrl: userData['profileImageUrl'],
                  name: userData['name'] ?? 'U',
                  onTap: () => _showImageUploadDialog(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFallbackHeaderBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.secondary],
        ),
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

// ================= Avatar Picker Bottom Sheet =================
class _AvatarPickerSheet extends StatefulWidget {
  final ValueChanged<String> onPicked; // returns local file path
  const _AvatarPickerSheet({required this.onPicked});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  XFile? _picked;
  bool _uploading = false; // reserved future use

  Future<void> _pick(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final res = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (res == null) return;
      setState(() => _picked = res);
    } catch (e) {
      if (!mounted) return;
      final msg = e is PlatformException
          ? '画像アクセスが拒否されました (code: ${e.code}). 設定から権限を許可してください。'
          : '画像取得に失敗: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_camera, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'プロフィール画像を変更',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_picked == null)
              Row(
                children: [
                  Expanded(
                    child: _PickButton(
                      icon: Icons.photo_library,
                      label: 'ギャラリー',
                      color: AppColors.secondary,
                      onTap: () => _pick(ImageSource.gallery),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PickButton(
                      icon: Icons.camera_alt,
                      label: 'カメラ',
                      color: AppColors.primary,
                      onTap: () => _pick(ImageSource.camera),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_picked!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _picked = null),
                        icon: const Icon(Icons.refresh),
                        label: const Text('再選択'),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _uploading
                            ? null
                            : () => widget.onPicked(_picked!.path),
                        icon: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),
                        label: Text(_uploading ? 'アップロード中...' : '更新する'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (_picked == null)
              Text(
                'カメラまたはギャラリーから画像を選択してください。\n推奨: 正方形 512px 以上。',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Floating Avatar (overlapping header & content) =================
class _FloatingAvatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;
  final String name;
  final VoidCallback onTap;

  const _FloatingAvatar({
    required this.radius,
    required this.imageUrl,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.secondary,
              child: imageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        imageUrl!,
                        width: radius * 2,
                        height: radius * 2,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, st) => _fallbackInitial(),
                      ),
                    )
                  : _fallbackInitial(),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackInitial() {
    return Text(
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 28,
      ),
    );
  }
}

// ================= Stat Tile (self profile only) =================
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final bool highlight;
  final VoidCallback? onTap;
  const _StatTile({
    required this.label,
    required this.value,
    required this.highlight,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final baseColor = highlight ? AppColors.primary : AppColors.textPrimary;
    final canTap = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: canTap && highlight
              ? AppColors.primary.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: baseColor,
              ),
            ),
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (canTap && highlight)
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= Follow handlers for other profile =================
