import 'package:flutter/material.dart';
import '../../../core/design/tokens.dart';

/// Tappable settings row. [destructive] rows are Cherry Grove and show no
/// chevron, so a destructive action never looks like navigation.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.destructive = false,
    this.last = false,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool destructive, last;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Brand.cherry : context.scheme.onSurface;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : Brand.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(Brand.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Brand.sm),
          child: Row(
            children: [
              Icon(icon, color: destructive ? Brand.cherry : Brand.forest),
              const SizedBox(width: Brand.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.text.titleMedium?.copyWith(color: color),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: context.text.bodyMedium?.copyWith(
                          color: Brand.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!destructive)
                const Icon(Icons.chevron_right, color: Brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}
