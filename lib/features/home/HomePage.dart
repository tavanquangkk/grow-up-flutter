import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';
import 'package:grow_up/features/home/ProfileScreen.dart';
import 'package:grow_up/features/home/WorkshopDetailDialog.dart';
import 'package:grow_up/features/home/WorkshopListScreen.dart';

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

  void _refreshData() {
    _workshopsFuture = HomePageApiService.getUpComingWorkshops();
    _usersFuture = HomePageApiService.getRecommendedUsers();
  }

  // 日付フォーマット関数
  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
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
                          onPressed: () => Navigator.pop(context),
                          child: Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 検索バー
                          Container(
                            margin: EdgeInsets.only(bottom: 20),
                            height: 48,
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: '勉強会やユーザーを検索...',
                                hintStyle: TextStyle(fontSize: 14),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: AppColors.textSecondary,
                                  size: 20,
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
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.surface,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),

                          // 2. 勉強会一覧
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '開催が近い勉強会',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Icon(
                                    Icons.event_note,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              FutureBuilder<List>(
                                future: _workshopsFuture,
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
                                    return Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border,
                                        ),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.event_busy,
                                              color: AppColors.textSecondary,
                                              size: 32,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              '勉強会はありません',
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

                                  // 最初の5つだけ表示
                                  final displayWorkshops =
                                      allWorkshops.length > 5
                                      ? allWorkshops.sublist(0, 5)
                                      : allWorkshops;

                                  return Column(
                                    children: [
                                      // 勉強会リスト（横向き）
                                      Container(
                                        height: 180, // 高さを調整
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          itemCount: displayWorkshops.length,
                                          itemBuilder: (context, index) {
                                            final workshop =
                                                displayWorkshops[index];
                                            return Container(
                                              width: 260, // カードの幅を少し狭く
                                              margin: EdgeInsets.only(
                                                right: 12,
                                              ),
                                              child: Card(
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    // 勉強会詳細ダイアログを表示
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (
                                                            BuildContext
                                                            context,
                                                          ) {
                                                            final dateValue =
                                                                workshop['date'];
                                                            final formattedDate =
                                                                dateValue !=
                                                                    null
                                                                ? _formatDate(
                                                                    dateValue,
                                                                  )
                                                                : '';

                                                            return WorkshopDetailDialog(
                                                              workshop:
                                                                  workshop,
                                                              formattedDate:
                                                                  formattedDate,
                                                            );
                                                          },
                                                    );
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(14),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        // アイコンとタイトル行
                                                        Row(
                                                          children: [
                                                            // アイコン
                                                            Container(
                                                              width: 36,
                                                              height: 36,
                                                              decoration: BoxDecoration(
                                                                color: AppColors
                                                                    .primary
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      8,
                                                                    ),
                                                              ),
                                                              child: Icon(
                                                                Icons.event,
                                                                color: AppColors
                                                                    .primary,
                                                                size: 18,
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            // タイトル
                                                            Expanded(
                                                              child: Text(
                                                                workshop['name'] ??
                                                                    '',
                                                                style: TextStyle(
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: AppColors
                                                                      .textPrimary,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 10),
                                                        // 説明
                                                        Expanded(
                                                          child: Text(
                                                            workshop['description'] ??
                                                                '',
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppColors
                                                                  .textSecondary,
                                                              height: 1.3,
                                                            ),
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        SizedBox(height: 8),
                                                        // ホストと日時情報
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons.person,
                                                                  size: 14,
                                                                  color: AppColors
                                                                      .textSecondary,
                                                                ),
                                                                SizedBox(
                                                                  width: 4,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    workshop['host']?['name'] ??
                                                                        '',
                                                                    style: TextStyle(
                                                                      fontSize:
                                                                          11,
                                                                      color: AppColors
                                                                          .textSecondary,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            if (workshop['date'] !=
                                                                null) ...[
                                                              SizedBox(
                                                                height: 2,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .schedule,
                                                                    size: 14,
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
                                                                          11,
                                                                      color: AppColors
                                                                          .textSecondary,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // すべて見るボタン
                                      Container(
                                        width: double.infinity,
                                        margin: EdgeInsets.only(top: 12),
                                        child: OutlinedButton(
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    WorkshopListScreen(),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: BorderSide(
                                              color: AppColors.primary,
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'すべて見る (${allWorkshops.length}件)',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 12,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),

                          SizedBox(height: 24),

                          // 3. 勉強会を作成するボタン
                          Container(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () async {
                                final result = await context.push(
                                  '/create-workshop',
                                );
                                if (result == true) {
                                  _refreshData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    '新しい勉強会を作成する',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // 4. オススメユーザー一覧（横向き）
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'オススメユーザー',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Icon(
                                    Icons.people,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Container(
                                height: 180,
                                child: FutureBuilder<List>(
                                  future: _usersFuture,
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
                                      return Container(
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                color: AppColors.textSecondary,
                                                size: 32,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'オススメユーザーはありません',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
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
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      itemCount: users.length,
                                      itemBuilder: (context, index) {
                                        final user = users[index];
                                        return Container(
                                          width: 140,
                                          margin: EdgeInsets.only(right: 12),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => ProfileScreen(
                                                    userId: user['id'],
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Card(
                                              elevation: 3,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Padding(
                                                padding: EdgeInsets.all(10),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // プロフィール画像
                                                    CircleAvatar(
                                                      radius: 26,
                                                      backgroundColor:
                                                          AppColors.secondary,
                                                      child:
                                                          user['profileImageUrl'] !=
                                                              null
                                                          ? ClipOval(
                                                              child: Image.network(
                                                                user['profileImageUrl'],
                                                                width: 52,
                                                                height: 52,
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
                                                                            26,
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
                                                                fontSize: 16,
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
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      user['department'] ??
                                                          user['position'] ??
                                                          'ユーザー',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    SizedBox(height: 8),
                                                    // フォローボタン
                                                    SizedBox(
                                                      width: double.infinity,
                                                      height: 28,
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
                                                                horizontal: 6,
                                                                vertical: 2,
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
                                                            fontSize: 10,
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
                          SizedBox(height: 20), // 最下部の余白
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
