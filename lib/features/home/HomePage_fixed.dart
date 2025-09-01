import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showAllWorkshops = false;

  // 日付フォーマット関数
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
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
                child: Icon(Icons.school, color: Colors.white, size: 16),
              ),
              SizedBox(width: 12),
              Text(
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
              margin: EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('ログアウト'),
                      content: Text('ログアウトしますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () async {
                            context.pop();
                            await ApiService.logout();
                            if (!context.mounted) return;
                            context.go("/login");
                          },
                          child: Text(
                            'ログアウト',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                icon: Container(
                  padding: EdgeInsets.all(8),
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
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                // Content Section
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 検索バー
                          Container(
                            margin: EdgeInsets.only(bottom: 24),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '勉強会やユーザーを検索...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.textSecondary,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                              ),
                            ),
                          ),

                          // 2. 勉強会一覧
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '勉強会一覧',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 16),
                              FutureBuilder<List>(
                                future:
                                    HomePageApiService.getUpComingWorkshops(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text('エラー: ${snapshot.error}'),
                                    );
                                  }
                                  final allWorkshops = snapshot.data ?? [];
                                  if (allWorkshops.isEmpty) {
                                    return Center(child: Text('勉強会はありません'));
                                  }

                                  // 表示する勉強会数を決定
                                  final displayWorkshops = _showAllWorkshops
                                      ? allWorkshops
                                      : allWorkshops.take(3).toList();

                                  return Column(
                                    children: [
                                      // 勉強会リスト
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: displayWorkshops.length,
                                        itemBuilder: (context, index) {
                                          final workshop =
                                              displayWorkshops[index];
                                          return Container(
                                            margin: EdgeInsets.only(bottom: 12),
                                            child: Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(16),
                                                child: Row(
                                                  children: [
                                                    // アイコン
                                                    Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.event,
                                                        color:
                                                            AppColors.primary,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    SizedBox(width: 16),
                                                    // コンテンツ
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            workshop['name'] ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                          SizedBox(height: 4),
                                                          Text(
                                                            workshop['description'] ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: AppColors
                                                                  .textSecondary,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.person,
                                                                size: 16,
                                                                color: AppColors
                                                                    .textSecondary,
                                                              ),
                                                              SizedBox(
                                                                width: 4,
                                                              ),
                                                              Text(
                                                                workshop['host']?['name'] ??
                                                                    '',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                ),
                                                              ),
                                                              if (workshop['date'] !=
                                                                  null) ...[
                                                                SizedBox(
                                                                  width: 16,
                                                                ),
                                                                Icon(
                                                                  Icons
                                                                      .schedule,
                                                                  size: 16,
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                ),
                                                                SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Text(
                                                                  _formatDate(
                                                                    workshop['date'],
                                                                  ),
                                                                  style: TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: AppColors
                                                                        .textSecondary,
                                                                  ),
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      // もっと見るボタン
                                      if (!_showAllWorkshops &&
                                          allWorkshops.length > 3)
                                        Container(
                                          width: double.infinity,
                                          margin: EdgeInsets.only(top: 16),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAllWorkshops = true;
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primary,
                                              side: BorderSide(
                                                color: AppColors.primary,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              'もっと見る (${allWorkshops.length - 3}件)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      // 閉じるボタン
                                      if (_showAllWorkshops &&
                                          allWorkshops.length > 3)
                                        Container(
                                          width: double.infinity,
                                          margin: EdgeInsets.only(top: 16),
                                          child: OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _showAllWorkshops = false;
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.textSecondary,
                                              side: BorderSide(
                                                color: AppColors.border,
                                              ),
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: Text(
                                              '閉じる',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 32),

                          // 3. 勉強会を作成するボタン
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.push('/create-workshop');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    '新しい勉強会を作成する',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 32),

                          // 4. オススメユーザー一覧（横向き）
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'オススメユーザー',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                height: 200,
                                child: FutureBuilder<List>(
                                  future:
                                      HomePageApiService.getRecommendedUsers(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Center(
                                        child: Text('エラー: ${snapshot.error}'),
                                      );
                                    }
                                    final users = snapshot.data ?? [];
                                    if (users.isEmpty) {
                                      return Center(
                                        child: Text('オススメユーザーはありません'),
                                      );
                                    }
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: users.length,
                                      itemBuilder: (context, index) {
                                        final user = users[index];
                                        return Container(
                                          width: 150,
                                          margin: EdgeInsets.only(right: 16),
                                          child: GestureDetector(
                                            onTap: () {
                                              context.push(
                                                '/profile/${user['id']}',
                                              );
                                            },
                                            child: Card(
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // プロフィール画像 - エラーハンドリング付き
                                                    CircleAvatar(
                                                      radius: 30,
                                                      backgroundColor:
                                                          AppColors.secondary,
                                                      child:
                                                          user['profileImageUrl'] !=
                                                              null
                                                          ? ClipOval(
                                                              child: Image.network(
                                                                user['profileImageUrl'],
                                                                width: 60,
                                                                height: 60,
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) {
                                                                      return Icon(
                                                                        Icons
                                                                            .person,
                                                                        size:
                                                                            30,
                                                                        color: Colors
                                                                            .white,
                                                                      );
                                                                    },
                                                                loadingBuilder:
                                                                    (
                                                                      context,
                                                                      child,
                                                                      loadingProgress,
                                                                    ) {
                                                                      if (loadingProgress ==
                                                                          null)
                                                                        return child;
                                                                      return CircularProgressIndicator(
                                                                        strokeWidth:
                                                                            2,
                                                                        valueColor:
                                                                            AlwaysStoppedAnimation<
                                                                              Color
                                                                            >(
                                                                              Colors.white,
                                                                            ),
                                                                      );
                                                                    },
                                                              ),
                                                            )
                                                          : Text(
                                                              (user['name'] ??
                                                                      'U')
                                                                  .substring(
                                                                    0,
                                                                    1,
                                                                  )
                                                                  .toUpperCase(),
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      user['name'] ?? 'ユーザー',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .textPrimary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 6),
                                                    Flexible(
                                                      child: Text(
                                                        user['department'] ??
                                                            user['position'] ??
                                                            'ユーザー',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    // レスポンシブボタン
                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 32,
                                                      child: ElevatedButton(
                                                        onPressed: () {
                                                          // TODO: フォロー機能
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              AppColors.primary,
                                                          foregroundColor:
                                                              Colors.white,
                                                          padding:
                                                              EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  6,
                                                                ),
                                                          ),
                                                          elevation: 1,
                                                        ),
                                                        child: Text(
                                                          'フォロー',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
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
      ),
    );
  }
}
