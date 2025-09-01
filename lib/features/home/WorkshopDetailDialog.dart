import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grow_up/core/theme/app_colors.dart';

class WorkshopDetailDialog extends StatelessWidget {
  final Map<String, dynamic> workshop;
  final String formattedDate;

  const WorkshopDetailDialog({
    Key? key,
    required this.workshop,
    this.formattedDate = '', // デフォルト値を設定
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 安全にホスト情報を取得
    final hostMap = workshop['host'] is Map
        ? workshop['host'] as Map<String, dynamic>
        : <String, dynamic>{};
    final hostName = hostMap['name'] ?? '未設定';
    final hostEmail = hostMap['email'] ?? '';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10.0,
              offset: Offset(0.0, 10.0),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー部分
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.event,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      workshop['name'] ?? '勉強会',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 24),

              // 開催日時
              if (workshop['date'] != null) ...[
                _buildInfoRow(Icons.calendar_today, '開催日時', formattedDate),
                SizedBox(height: 16),
              ],

              // 内容
              _buildInfoRow(
                Icons.description,
                '内容',
                workshop['description'] ?? '説明はありません',
                isMultiLine: true,
              ),
              SizedBox(height: 16),

              // 開催者情報
              _buildInfoRow(Icons.person, '開催者', hostName),
              if (hostEmail.isNotEmpty) ...[
                SizedBox(height: 8),
                _buildInfoRow(Icons.email, 'メール', hostEmail),
              ],

              SizedBox(height: 24),

              // アクションボタン
              Row(
                children: [
                  // 開催者へ連絡するボタン
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.mail_outline),
                      label: Text('開催者へ連絡'),
                      onPressed: () {
                        if (hostEmail.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: hostEmail));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('メールアドレスをコピーしました')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('開催者のメールアドレスが設定されていません')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  // 参加するボタン
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.check_circle_outline),
                      label: Text('参加する'),
                      onPressed: () {
                        // TODO: 参加機能の実装
                        Navigator.pop(context);
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('参加登録しました')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isMultiLine = false,
  }) {
    return Builder(
      builder: (BuildContext context) {
        return Row(
          crossAxisAlignment: isMultiLine
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: isMultiLine ? null : 1,
                    overflow: isMultiLine ? null : TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
