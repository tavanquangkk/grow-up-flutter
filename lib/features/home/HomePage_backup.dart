import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/utils/apis/auth_api_service.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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

                          // 2. 開催が近い勉強会（横向き）
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '開催が近い勉強会',
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
                                    final workshops = snapshot.data ?? [];
                                    if (workshops.isEmpty) {
                                      return Center(child: Text('勉強会はありません'));
                                    }
                                    return ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: workshops.length,
                                      itemBuilder: (context, index) {
                                        final workshop = workshops[index];
                                        return Container(
                                          width: 250,
                                          margin: EdgeInsets.only(right: 16),
                                          child: Card(
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    workshop['name'] ?? '',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.textPrimary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    workshop['description'] ??
                                                        '',
                                                    style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  Spacer(),
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 12,
                                                        backgroundColor:
                                                            AppColors.primary,
                                                        child: Icon(
                                                          Icons.person,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          workshop['host']?['name'] ??
                                                              '',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: AppColors
                                                                .textSecondary,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
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

                          SizedBox(height: 32),

                          // 3. 勉強会を作成するボタン
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: 勉強会作成画面へ
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
                                height: 180,
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
                                          child: Card(
                                            elevation: 3,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Column(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 30,
                                                    backgroundColor:
                                                        AppColors.secondary,
                                                    backgroundImage:
                                                        user['profileImageUrl'] !=
                                                            null
                                                        ? NetworkImage(
                                                            user['profileImageUrl'],
                                                          )
                                                        : null,
                                                    child:
                                                        user['profileImageUrl'] ==
                                                            null
                                                        ? Text(
                                                            (user['name'] ??
                                                                    'U')
                                                                .substring(0, 1)
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 18,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  SizedBox(height: 12),
                                                  Text(
                                                    user['name'] ?? 'ユーザー',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color:
                                                          AppColors.textPrimary,
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
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  Spacer(),
                                                  ElevatedButton(
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
                                                            horizontal: 16,
                                                            vertical: 8,
                                                          ),
                                                      minimumSize: Size(0, 30),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'フォロー',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
