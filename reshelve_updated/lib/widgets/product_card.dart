import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme.dart';
import 'shared_widgets.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ProductCard({super.key, required this.product, this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.card, AppColors.card2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(children: [
          // Left status bar
          Container(
            width: 3,
            height: 54,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: product.isOut
                  ? AppColors.danger
                  : product.isLow
                      ? AppColors.warn
                      : AppColors.glassBorder,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Thumbnail — photo or category icon
          _Thumb(product: product),
          const SizedBox(width: 14),
          // Name + category
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Icon(categoryIconFor(product.cat), size: 11, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(product.cat,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ),
          const SizedBox(width: 8),
          trailing ??
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₱${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.accent)),
                const SizedBox(height: 5),
                StockPill(stock: product.stock, lowAt: product.lowAt),
              ]),
        ]),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final Product product;
  const _Thumb({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.imagePath != null && File(product.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(product.imagePath!), width: 54, height: 54, fit: BoxFit.cover),
      );
    }
    // Icon-only thumbnail — no emoji
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.1), AppColors.primary.withOpacity(0.18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Icon(categoryIconFor(product.cat), color: AppColors.accent, size: 24),
    );
  }
}
