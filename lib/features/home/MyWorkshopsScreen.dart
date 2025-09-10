import 'package:flutter/material.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';
import 'package:grow_up/features/home/WorkshopDetailDialog.dart';

class MyWorkshopsScreen extends StatefulWidget {
  const MyWorkshopsScreen({Key? key}) : super(key: key);

  @override
  State<MyWorkshopsScreen> createState() => _MyWorkshopsScreenState();
}

class _MyWorkshopsScreenState extends State<MyWorkshopsScreen> {
  late Future<List> _myWorkshopsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _myWorkshopsFuture = HomePageApiService.getMyWorkshops();
    });
  }

  // 日付フォーマット関数
  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.year}年${date.month}月${date.day}日 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '自分の作成した勉強会',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 1,
        shadowColor: AppColors.border,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _refreshData,
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.refresh, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List>(
          future: _myWorkshopsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      '勉強会を読み込み中...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    SizedBox(height: 16),
                    Text(
                      'エラーが発生しました',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _refreshData();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('再試行'),
                    ),
                  ],
                ),
              );
            }

            final workshops = snapshot.data ?? [];
            if (workshops.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'まだ勉強会を作成していません',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '新しい勉強会を作成してみましょう',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context, 'create_workshop');
                      },
                      icon: Icon(Icons.add),
                      label: Text('勉強会を作成'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _myWorkshopsFuture = HomePageApiService.getMyWorkshops();
                });
                // Future の完了を待つ
                await _myWorkshopsFuture;
              },
              color: AppColors.primary,
              child: ListView.builder(
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
                          final dateValue = workshop['date'];
                          final formattedDate = dateValue != null
                              ? _formatDate(dateValue)
                              : '';

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ヘッダー行
                              Row(
                                children: [
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        if (workshop['date'] != null)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                _formatDate(workshop['date']),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  // 編集・削除アクション
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditWorkshopDialog(workshop);
                                      } else if (value == 'delete') {
                                        // TODO: 削除機能
                                        _showDeleteConfirmation(workshop);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('編集'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: AppColors.error,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              '削除',
                                              style: TextStyle(
                                                color: AppColors.error,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              // 説明
                              Text(
                                workshop['description'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 12),
                              // 参加者情報とステータス
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.person,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '主催者',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  Text(
                                    'ID: ${workshop['id'].toString().substring(0, 8)}...',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
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
            );
          },
        ),
      ),
    );
  }

  void _showEditWorkshopDialog(Map<String, dynamic> workshop) {
    final nameController = TextEditingController(text: workshop['name'] ?? '');
    final descriptionController = TextEditingController(
      text: workshop['description'] ?? '',
    );
    DateTime selectedDate = DateTime.now();

    // 既存の日付をパース
    if (workshop['date'] != null) {
      try {
        selectedDate = DateTime.parse(workshop['date'].toString());
      } catch (e) {
        print('日付のパースに失敗: $e');
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('勉強会を編集'),
                ],
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'タイトル',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: '勉強会のタイトルを入力',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '説明',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: '勉強会の詳細を入力',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '開催日時',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                print('日付ピッカーをタップしました'); // デバッグ用
                                try {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate:
                                        selectedDate.isAfter(DateTime.now())
                                        ? selectedDate
                                        : DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now().add(
                                      Duration(days: 365 * 2),
                                    ),
                                  );
                                  print('選択された日付: $date'); // デバッグ用
                                  if (date != null) {
                                    setState(() {
                                      selectedDate = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        selectedDate.hour,
                                        selectedDate.minute,
                                      );
                                    });
                                    print(
                                      '更新された selectedDate: $selectedDate',
                                    ); // デバッグ用
                                  }
                                } catch (e) {
                                  print('日付ピッカーエラー: $e'); // デバッグ用
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              splashColor: AppColors.primary.withOpacity(0.1),
                              highlightColor: AppColors.primary.withOpacity(
                                0.05,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '${selectedDate.month}/${selectedDate.day}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () async {
                                print('時間ピッカーをタップしました'); // デバッグ用
                                try {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(
                                      selectedDate,
                                    ),
                                  );
                                  print('選択された時間: $time'); // デバッグ用
                                  if (time != null) {
                                    setState(() {
                                      selectedDate = DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        time.hour,
                                        time.minute,
                                      );
                                    });
                                    print(
                                      '更新された selectedDate: $selectedDate',
                                    ); // デバッグ用
                                  }
                                } catch (e) {
                                  print('時間ピッカーエラー: $e'); // デバッグ用
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              splashColor: AppColors.primary.withOpacity(0.1),
                              highlightColor: AppColors.primary.withOpacity(
                                0.05,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: AppColors.primary,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    // 選択された日時の完全表示
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '選択された開催日時:',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDate(selectedDate.toIso8601String()),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'キャンセル',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('タイトルを入力してください')));
                      return;
                    }
                    if (descriptionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('説明を入力してください')));
                      return;
                    }

                    try {
                      print('編集ボタンが押されました'); // デバッグ用
                      print('送信するデータ:');
                      print('  ID: ${workshop['id']}');
                      print('  Name: ${nameController.text.trim()}');
                      print(
                        '  Description: ${descriptionController.text.trim()}',
                      );

                      // 元の日付と新しい日付を比較
                      String originalDate = workshop['date'] ?? '';
                      String newDate = selectedDate.toIso8601String();
                      print('  Original Date: $originalDate');
                      print('  New Date: $newDate');

                      // サーバーが期待する形式に日付を調整
                      String formattedDate = newDate;
                      if (originalDate.isNotEmpty) {
                        // 元の日付のフォーマットに合わせる
                        if (originalDate.endsWith('Z') &&
                            !newDate.endsWith('Z')) {
                          formattedDate = newDate.replaceAll('.000', '') + 'Z';
                        }
                      }
                      print('  Formatted Date: $formattedDate');

                      // ローディングダイアログを表示
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (loadingContext) => Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                                SizedBox(height: 16),
                                Text('勉強会を更新中...'),
                              ],
                            ),
                          ),
                        ),
                      );

                      final result = await HomePageApiService.updateWorkshop(
                        id: workshop['id'],
                        name: nameController.text.trim(),
                        description: descriptionController.text.trim(),
                        date: formattedDate,
                      );

                      print('API応答: $result'); // デバッグ用

                      // ローディングダイアログを閉じる
                      Navigator.of(context).pop();
                      // 編集ダイアログを閉じる
                      Navigator.of(context).pop();

                      if (result['status'] == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('勉強会を更新しました'),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // メインのMyWorkshopsScreenのsetStateを呼び出し
                        if (mounted) {
                          setState(() {
                            _refreshData();
                          });
                        }
                      } else {
                        throw Exception(result['message'] ?? '更新に失敗しました');
                      }
                    } catch (e) {
                      print('更新エラー: $e'); // デバッグ用
                      // ローディングダイアログが開いている可能性があるので、安全に閉じる
                      try {
                        Navigator.of(context).pop();
                      } catch (navError) {
                        print('Navigator.pop エラー: $navError');
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('更新エラー: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('更新'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> workshop) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: AppColors.error),
              SizedBox(width: 8),
              Text('勉強会を削除'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('以下の勉強会を削除しますか？'),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop['name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      workshop['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Text(
                'この操作は取り消せません。',
                style: TextStyle(color: AppColors.error, fontSize: 12),
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
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                try {
                  print('削除ボタンが押されました'); // デバッグ用
                  print('削除対象Workshop ID: ${workshop['id']}'); // デバッグ用

                  // ローディングダイアログを表示
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (loadingContext) => Center(
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.error),
                            SizedBox(height: 16),
                            Text('勉強会を削除中...'),
                          ],
                        ),
                      ),
                    ),
                  );

                  final result = await HomePageApiService.deleteWorkshop(
                    id: workshop['id'],
                  );

                  print('削除API応答: $result'); // デバッグ用

                  // ローディングダイアログを閉じる
                  Navigator.of(context).pop();

                  if (result['status'] == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('勉強会を削除しました'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // メインのMyWorkshopsScreenのsetStateを呼び出して画面更新
                    if (mounted) {
                      setState(() {
                        _refreshData();
                      });
                    }
                  } else {
                    throw Exception(result['message'] ?? '削除に失敗しました');
                  }
                } catch (e) {
                  print('削除エラー: $e'); // デバッグ用
                  // ローディングダイアログが開いている可能性があるので、安全に閉じる
                  try {
                    Navigator.of(context).pop();
                  } catch (navError) {
                    print('Navigator.pop エラー: $navError');
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('削除エラー: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text('削除'),
            ),
          ],
        );
      },
    );
  }
}
