import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';

/// Compact rounded filter chip (1px border), with an optional color [swatch]
/// square before the label (e.g. hair colors).
class PixelChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? swatch;

  const PixelChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.swatch,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? p.primary : p.surfaceVariant,
            borderRadius: AppRadius.rChip,
            border: Border.all(color: selected ? p.primaryLight : p.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (swatch case final color?) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(color: p.borderDeep, width: 1),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: selected ? p.buttonText : p.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
