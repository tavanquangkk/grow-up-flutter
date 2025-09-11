import 'package:flutter/material.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/features/home/ProfileScreen.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';

/// 推奨ユーザー一覧 + フォロー/解除ボタン
///  - 初期表示時に自分がフォローしているID一覧を取得し高速判定
///  - ボタン押下は楽観的更新 (失敗時ロールバック & SnackBar)
///  - 個別ユーザー処理中はスピナー + ボタン無効化
class RecommendedUsersSection extends StatefulWidget {
  final Future<List> future; // 推奨ユーザー取得 Future
  const RecommendedUsersSection({super.key, required this.future});

  @override
  State<RecommendedUsersSection> createState() =>
      _RecommendedUsersSectionState();
}

class _RecommendedUsersSectionState extends State<RecommendedUsersSection> {
  Set<String> _followingIds = {};
  bool _loadingFollowingIds = true;
  String? _processingUserId; // follow/unfollow API 呼び出し中のユーザー

  @override
  void initState() {
    super.initState();
    _loadFollowingIds();
  }

  Future<void> _loadFollowingIds() async {
    try {
      final ids = await HomePageApiService.fetchFollowingIds();
      if (mounted) {
        setState(() {
          _followingIds = ids;
          _loadingFollowingIds = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingFollowingIds = false);
      }
      // 取得失敗しても UI は表示 (全て未フォロー表示) させる
      debugPrint('Failed to load following ids: $e');
    }
  }

  bool _isFollowing(String userId) => _followingIds.contains(userId);

  Future<void> _handleFollow(String userId) async {
    if (_processingUserId != null) return; // 重複タップ防止
    setState(() {
      _processingUserId = userId;
      // 楽観的追加
      _followingIds.add(userId);
    });
    try {
      await HomePageApiService.followUser(userId);
    } catch (e) {
      // ロールバック
      setState(() {
        _followingIds.remove(userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('フォローに失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _processingUserId = null);
      }
    }
  }

  Future<void> _handleUnfollow(String userId) async {
    if (_processingUserId != null) return;
    setState(() {
      _processingUserId = userId;
      _followingIds.remove(userId); // 楽観的削除
    });
    try {
      await HomePageApiService.unfollowUser(userId);
    } catch (e) {
      // ロールバック
      setState(() {
        _followingIds.add(userId);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('フォロー解除に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _processingUserId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'オススメユーザー',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Icon(Icons.people, color: AppColors.primary, size: 20),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: FutureBuilder<List>(
            future: widget.future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('エラー: ${snapshot.error}'));
              }
              final users = snapshot.data ?? [];
              if (users.isEmpty) {
                return Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'オススメユーザーはありません',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  final String userId = user['id'].toString();
                  final String? imageUrl = user['profileImageUrl'];
                  final bool isFollowing = _isFollowing(userId);
                  final bool processing = _processingUserId == userId;
                  return Container(
                    width: 150,
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProfileScreen(userId: userId),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: AppColors.primary,
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          imageUrl,
                                          width: 52,
                                          height: 52,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person,
                                                  size: 26,
                                                  color: Colors.white,
                                                );
                                              },
                                          loadingBuilder:
                                              (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                );
                                              },
                                        ),
                                      )
                                    : Text(
                                        (user['name'] ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                user['name'] ?? 'ユーザー',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['department'] ??
                                    user['position'] ??
                                    'ユーザー',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 30,
                                child: _loadingFollowingIds
                                    ? const Center(
                                        child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : isFollowing
                                    ? _buildFollowingButton(userId, processing)
                                    : _buildFollowButton(userId, processing),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFollowButton(String userId, bool processing) {
    return ElevatedButton(
      onPressed: processing ? null : () => _handleFollow(userId),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 1,
      ),
      child: processing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'フォロー',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildFollowingButton(String userId, bool processing) {
    return OutlinedButton(
      onPressed: processing ? null : () => _handleUnfollow(userId),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        side: BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: processing
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              'フォロー中',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
            ),
    );
  }
}
