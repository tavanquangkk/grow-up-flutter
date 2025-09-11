import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';
import 'package:grow_up/features/home/WorkshopDetailDialog.dart';

class WorkshopListScreen extends StatefulWidget {
  const WorkshopListScreen({Key? key}) : super(key: key);

  @override
  State<WorkshopListScreen> createState() => _WorkshopListScreenState();
}

class _WorkshopListScreenState extends State<WorkshopListScreen> {
  late Future<List> _workshopsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    _workshopsFuture = HomePageApiService.getUpComingWorkshops();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('勉強会一覧'),
        backgroundColor: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.border,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List>(
          future: _workshopsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('エラー: ${snapshot.error}'));
            }

            final workshops = snapshot.data ?? [];
            if (workshops.isEmpty) {
              return Center(child: Text('勉強会はありません'));
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: workshops.length,
              itemBuilder: (context, index) {
                final workshop = workshops[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () {
                        // 勉強会詳細ダイアログを表示
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            final dateValue = workshop['date'];
                            final formattedDate = dateValue != null
                                ? _formatDate(dateValue)
                                : '';

                            return WorkshopDetailDialog(
                              workshop: workshop,
                              formattedDate: formattedDate,
                            );
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // アイコン
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.event,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            // コンテンツ
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    workshop['name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    workshop['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        workshop['host']?['name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      if (workshop['date'] != null) ...[
                                        SizedBox(width: 16),
                                        Icon(
                                          Icons.schedule,
                                          size: 16,
                                          color: AppColors.textSecondary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          _formatDate(workshop['date']),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
