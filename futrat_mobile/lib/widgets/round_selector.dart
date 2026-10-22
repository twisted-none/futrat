import 'package:flutter/material.dart';

class RoundSelector extends StatelessWidget {
  const RoundSelector({
    super.key,
    required this.current,
    required this.total,
    required this.onChanged,
  });
  final int current;
  final int total;
  final ValueChanged<int> onChanged;

  Future<void> _choose(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _RoundPicker(current: current, total: total),
    );
    if (context.mounted && selected != null && selected != current) {
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Предыдущий тур',
            onPressed: current > 1 ? () => onChanged(current - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: TextButton(
              key: const ValueKey('choose-round'),
              onPressed: () => _choose(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Тур $current из $total',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Следующий тур',
            onPressed: current < total ? () => onChanged(current + 1) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    ),
  );
}

class _RoundPicker extends StatefulWidget {
  const _RoundPicker({required this.current, required this.total});
  final int current;
  final int total;
  @override
  State<_RoundPicker> createState() => _RoundPickerState();
}

class _RoundPickerState extends State<_RoundPicker> {
  final _scroll = ScrollController();
  bool _positioned = false;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final height = 48 + scale * 14;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Выберите тур',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Закрыть',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      (constraints.maxWidth / (scale > 1.4 ? 125 : 90))
                          .floor()
                          .clamp(2, 6);
                  if (!_positioned) {
                    _positioned = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted || !_scroll.hasClients) return;
                      final offset =
                          ((widget.current - 1) ~/ columns - 1) * (height + 10);
                      _scroll.jumpTo(
                        offset
                            .clamp(0, _scroll.position.maxScrollExtent)
                            .toDouble(),
                      );
                    });
                  }
                  return GridView.builder(
                    controller: _scroll,
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: widget.total,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      mainAxisExtent: height,
                    ),
                    itemBuilder: (context, i) {
                      final round = i + 1, selected = round == widget.current;
                      return Semantics(
                        selected: selected,
                        child: OutlinedButton(
                          key: ValueKey('round-choice-$round'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            backgroundColor: selected
                                ? colors.primaryContainer
                                : colors.surface,
                            foregroundColor: selected
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                            side: BorderSide(
                              color: selected
                                  ? colors.primary
                                  : colors.outlineVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context, round),
                          child: Text(
                            'Тур $round',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
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
      ),
    );
  }
}
