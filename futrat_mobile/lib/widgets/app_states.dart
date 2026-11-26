import 'package:flutter/material.dart';
import '../core/app_theme.dart';

enum LoadingLayout { matches, table, profile }

/// Static skeletons respect reduced-motion settings and do not invent content.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.layout = LoadingLayout.matches,
    this.label = 'Загрузка матчей',
  });
  final LoadingLayout layout;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    liveRegion: true,
    child: ExcludeSemantics(
      child: ListView(
        padding: const EdgeInsets.all(AppLayout.pageInset),
        children: [
          if (layout == LoadingLayout.profile)
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  SkeletonBox(width: 64, height: 64, radius: 16),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 160, height: 20),
                        SizedBox(height: 10),
                        SkeletonBox(width: 110, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < (layout == LoadingLayout.table ? 9 : 4); i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(AppLayout.cardRadius),
              ),
              child: Row(
                children: [
                  const SkeletonBox(width: 32, height: 32, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonBox(width: double.infinity, height: 14),
                        if (layout != LoadingLayout.table) ...[
                          const SizedBox(height: 12),
                          const SkeletonBox(width: 120, height: 14),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  const SkeletonBox(width: 26, height: 20),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 5,
  });
  final double width, height, radius;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.sports_soccer_outlined,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? message, actionLabel;
  final IconData icon;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(AppLayout.sectionGap),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 20),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    ),
  );
}

class UpdateNotice extends StatelessWidget {
  const UpdateNotice({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodySmall),
        TextButton(onPressed: onRetry, child: const Text('Повторить')),
      ],
    ),
  );
}

TabBar appTabs(
  BuildContext context,
  List<String> labels, {
  TabController? controller,
  ValueChanged<int>? onTap,
  bool fixedEqualWidth = true,
}) {
  final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
  final lines = scale > 1.5 ? 3 : 2;
  final scrollable = labels.length > 3 || (!fixedEqualWidth && scale > 1.4);
  double? width;
  if (scrollable) {
    width = 100;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: Theme.of(context).textTheme.labelLarge?.merge(
            Theme.of(context).tabBarTheme.labelStyle,
          ),
        ),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
      )..layout();
      if (painter.width + 24 > width!) width = painter.width + 24;
      painter.dispose();
    }
  }
  return TabBar(
    controller: controller,
    onTap: onTap,
    isScrollable: scrollable,
    tabAlignment: scrollable ? TabAlignment.start : TabAlignment.fill,
    labelPadding: EdgeInsets.zero,
    indicatorSize: TabBarIndicatorSize.tab,
    tabs: [
      for (var i = 0; i < labels.length; i++)
        Tab(
          key: ValueKey('league-tab-$i'),
          height: scrollable
              ? (13 * scale * 1.2 + 20).clamp(52, 90).toDouble()
              : (13 * scale * lines * 1.2 + 12).clamp(52, 120).toDouble(),
          child: SizedBox(
            width: scrollable ? width : double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                maxLines: scrollable ? 1 : lines,
                softWrap: !scrollable,
              ),
            ),
          ),
        ),
    ],
  );
}
