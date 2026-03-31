import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/app_store.dart';
import '../theme.dart';
import 'app_sheet.dart';
import 'add_edit_product_sheet.dart';
import 'toast.dart';

class ProductDetailSheet extends StatelessWidget {
  final Product product;
  final bool showAddToCart;

  const ProductDetailSheet({super.key, required this.product, this.showAddToCart = false});

  @override
  Widget build(BuildContext context) {
    return AppSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.accent.withOpacity(0.08), AppColors.primary.withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                _thumbnail(product),
                const SizedBox(height: 12),
                Text(product.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textColor),
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text(product.cat, style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.0,
            children: [
              _statTile('₱${product.price.toStringAsFixed(0)}', 'Sell Price'),
              _statTile('${product.stock}', 'In Stock'),
              _statTile('₱${product.capital.toStringAsFixed(0)}', 'Capital'),
              _statTile('₱${product.profit.toStringAsFixed(0)}', 'Profit/item'),
            ],
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(children: [
            if (showAddToCart)
              Expanded(
                child: _actionBtn(
                  context,
                  label: 'Add to Cart',
                  icon: Icons.shopping_cart_outlined,
                  gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                  onTap: () {
                    context.read<AppStore>().addToCart(product);
                    Navigator.pop(context);
                    showToast(context, 'Added to cart');
                  },
                ),
              ),
            if (showAddToCart) const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(context,
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  color: AppColors.card2,
                  borderColor: AppColors.glassBorder,
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AddEditProductSheet(product: product),
                    );
                  }),
            ),
            const SizedBox(width: 10),
            _deleteBtn(context),
          ]),
        ],
      ),
    );
  }

  Widget _thumbnail(Product p) {
    if (p.imagePath != null && File(p.imagePath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(File(p.imagePath!), width: 80, height: 80, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(categoryIconFor(p.cat), color: AppColors.accent, size: 40),
    );
  }

  Widget _statTile(String val, String key) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent)),
          const SizedBox(height: 2),
          Text(key.toUpperCase(),
              style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Gradient? gradient,
    Color? color,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: gradient,
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: borderColor != null ? Border.all(color: borderColor) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _deleteBtn(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.dark2,
            title: const Text('Delete Product?', style: TextStyle(color: AppColors.textColor)),
            content: Text('${product.name} will be permanently deleted.',
                style: const TextStyle(color: AppColors.muted)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
              TextButton(
                onPressed: () {
                  context.read<AppStore>().deleteProduct(product.id);
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // close sheet
                  showToast(context, 'Product deleted', color: AppColors.danger);
                },
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger.withOpacity(0.3)),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
      ),
    );
  }
}
