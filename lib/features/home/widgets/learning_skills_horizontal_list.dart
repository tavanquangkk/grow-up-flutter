import 'package:flutter/material.dart';
import 'package:grow_up/core/theme/app_colors.dart';
import 'package:grow_up/core/utils/apis/home_page_api_service.dart';

class LearningSkillsHorizontalList extends StatelessWidget {
  final List<dynamic> rawSkills;
  final EdgeInsetsGeometry? padding;
  final String title;
  final double height;
  final VoidCallback? onMore; // optional action (e.g., navigate to edit)
  final VoidCallback? onSkillAdded; // notify parent to refresh profile
  final bool isMyProfile; // whether this is the current user's profile

  const LearningSkillsHorizontalList({
    super.key,
    required this.rawSkills,
    this.padding,
    this.title = '学習したいスキル',
    this.height = 58,
    this.onMore,
    this.onSkillAdded,
    this.isMyProfile = true, // default to true for backward compatibility
  });

  List<String> _normalize(List<dynamic> input) {
    final set = <String>{};
    for (final s in input) {
      if (s == null) continue;
      if (s is Map) {
        final name = s['name']?.toString().trim();
        if (name != null && name.isNotEmpty) set.add(name.replaceAll('"', ''));
      } else {
        final name = s.toString().trim();
        if (name.isNotEmpty) set.add(name.replaceAll('"', ''));
      }
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    final skills = _normalize(rawSkills);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Add skill button (only for own profile)
            if (isMyProfile)
              IconButton(
                tooltip: 'スキルを追加',
                onPressed: () => _openAddDialog(context),
                icon: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(6),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (onMore != null)
              TextButton(
                onPressed: onMore,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('編集'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12),
          child: skills.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '未設定',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, i) {
                    final label = skills[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.bolt,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .3,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: skills.length,
                ),
        ),
      ],
    );
  }
}

extension _AddSkillDialog on LearningSkillsHorizontalList {
  Future<void> _openAddDialog(BuildContext context) async {
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
                title: const Text('スキルを追加'),
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
                            final already = rawSkills.any(
                              (r) =>
                                  r
                                      .toString()
                                      .replaceAll('"', '')
                                      .trim()
                                      .toLowerCase() ==
                                  n.toLowerCase(),
                            );
                            final isSelected = selected == n;
                            return ListTile(
                              dense: true,
                              title: Text(
                                n,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              leading: already
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    )
                                  : (isSelected
                                        ? Icon(
                                            Icons.radio_button_checked,
                                            color: AppColors.primary,
                                            size: 20,
                                          )
                                        : const Icon(
                                            Icons.circle_outlined,
                                            size: 20,
                                          )),
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(
                                0.08,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onTap: already
                                  ? null
                                  : () => setState(() => selected = n),
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
                              await HomePageApiService.addLearningSkill(
                                selected!,
                              );
                              if (ctx.mounted) Navigator.of(ctx).pop();
                              onSkillAdded?.call();
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
