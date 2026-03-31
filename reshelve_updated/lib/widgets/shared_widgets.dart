import 'package:flutter/material.dart';
import '../theme.dart';

// ── Stock Pill ────────────────────────────────────────────────────────────────
class StockPill extends StatelessWidget {
  final int stock;
  final int lowAt;

  const StockPill({super.key, required this.stock, required this.lowAt});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (stock == 0) {
      bg = AppColors.danger.withOpacity(0.12);
      fg = AppColors.danger;
      label = 'OUT';
    } else if (stock <= lowAt) {
      bg = AppColors.warn.withOpacity(0.12);
      fg = AppColors.warn;
      label = '$stock left';
    } else {
      bg = AppColors.accent.withOpacity(0.1);
      fg = AppColors.accent;
      label = '$stock in stock';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.5),
      ),
    );
  }
}

// ── Gradient Button ────────────────────────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double? width;

  const GradientButton({super.key, required this.label, this.icon, required this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: Colors.white), const SizedBox(width: 8)],
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1.2),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ),
      ],
    );
  }
}

// ── Glass Card ─────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: child,
      ),
    );
  }
}

// ── Category Chip ──────────────────────────────────────────────────────────────
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withOpacity(0.15) : AppColors.glass,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? AppColors.accent.withOpacity(0.5) : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.accent : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? valueColor;

  const StatCard({super.key, required this.value, required this.label, required this.icon, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? AppColors.textColor;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 4),
                Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w500, letterSpacing: 0.8)),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Icon(icon, size: 20, color: AppColors.accent.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Top Bar ─────────────────────────────────────────────────────────────────────
class AppTopBar extends StatelessWidget {
  final String wordmark;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const AppTopBar({
    super.key,
    required this.wordmark,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.dark, AppColors.dark.withOpacity(0)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wordmark.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 3, color: AppColors.accent)),
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textColor, letterSpacing: -0.5, height: 1)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 8),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }
}

// ── Icon Button ────────────────────────────────────────────────────────────────
class AppIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const AppIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.glass,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 18, color: AppColors.muted2),
      ),
    );
  }
}

// ── Form Field Wrapper ─────────────────────────────────────────────────────────
class AppFormField extends StatelessWidget {
  final String label;
  final Widget child;

  const AppFormField({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ── Qty Stepper ────────────────────────────────────────────────────────────────
class QtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback onInc;
  final VoidCallback onDec;

  const QtyStepper({super.key, required this.value, required this.onInc, required this.onDec});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(Icons.remove, onDec),
        SizedBox(
          width: 32,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textColor)),
        ),
        _btn(Icons.add, onInc),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.card2,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 16, color: AppColors.textColor),
      ),
    );
  }
}
