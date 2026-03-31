import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/app_store.dart';
import '../theme.dart';
import 'shared_widgets.dart';
import 'app_sheet.dart';
import 'toast.dart';

class AddEditProductSheet extends StatefulWidget {
  final Product? product; // null = add mode

  const AddEditProductSheet({super.key, this.product});

  @override
  State<AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends State<AddEditProductSheet> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capitalCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _lowAtCtrl = TextEditingController();
  String _cat = 'Pantry & Dry Goods';
  String? _imagePath;
  bool get _isEdit => widget.product != null;

  // Emoji is now auto-assigned from category; no manual emoji field

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.product!;
      _nameCtrl.text = p.name;
      _priceCtrl.text = p.price.toString();
      _capitalCtrl.text = p.capital.toString();
      _stockCtrl.text = p.stock.toString();
      _lowAtCtrl.text = p.lowAt.toString();
      _cat = kCategories.contains(p.cat) ? p.cat : 'Others';
      _imagePath = p.imagePath;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _capitalCtrl.dispose();
    _stockCtrl.dispose();
    _lowAtCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Show source selection
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.dark2,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('Product Photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textColor)),
          const SizedBox(height: 16),
          _sourceBtn(Icons.camera_alt_outlined, 'Take Photo', AppColors.accent, () => Navigator.pop(context, ImageSource.camera)),
          const SizedBox(height: 10),
          _sourceBtn(Icons.photo_library_outlined, 'Choose from Gallery', AppColors.info, () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );
    if (source == null) return;
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: source, imageQuality: 80);
      if (img != null && mounted) setState(() => _imagePath = img.path);
    } catch (e) {
      if (mounted) showToast(context, '⚠️ Camera permission required. Check app settings.', color: AppColors.warn);
    }
  }

  Widget _sourceBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    );
  }

  void _save(BuildContext context) {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text);
    final stock = int.tryParse(_stockCtrl.text);

    if (name.isEmpty || price == null || stock == null) {
      showToast(context, '⚠️ Fill all required fields', color: AppColors.warn);
      return;
    }

    final store = context.read<AppStore>();

    // ── Duplicate name check ──────────────────────────────────────────────────
    if (store.productNameExists(name, excludeId: widget.product?.id)) {
      showToast(context, '⚠️ A product named "$name" already exists', color: AppColors.warn);
      return;
    }

    // Auto-assign emoji from category
    final emoji = categoryEmoji(_cat);

    if (_isEdit) {
      store.updateProduct(widget.product!.copyWith(
        name: name,
        emoji: emoji,
        price: price,
        capital: double.tryParse(_capitalCtrl.text) ?? 0,
        stock: stock,
        lowAt: int.tryParse(_lowAtCtrl.text) ?? 5,
        cat: _cat,
        imagePath: _imagePath,
      ));
      showToast(context, '✅ Product updated!');
    } else {
      store.addProduct(Product(
        id: store.newId(),
        name: name,
        emoji: emoji,
        price: price,
        capital: double.tryParse(_capitalCtrl.text) ?? 0,
        stock: stock,
        lowAt: int.tryParse(_lowAtCtrl.text) ?? 5,
        cat: _cat,
        imagePath: _imagePath,
      ));
      showToast(context, '✅ Product added!');
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final autoEmoji = categoryEmoji(_cat);

    return AppSheet(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.accent, size: 22),
              const SizedBox(width: 10),
              Text(_isEdit ? 'Edit Product' : 'Add Product',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textColor)),
            ]),
            const SizedBox(height: 22),

            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: _imagePath != null && File(_imagePath!).existsSync()
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        // Auto emoji preview
                        Text(autoEmoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.camera_alt_outlined, color: AppColors.accent, size: 22),
                          const SizedBox(height: 4),
                          const Text('Tap to add photo', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                          Text('(auto icon: $autoEmoji from category)',
                              style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                        ]),
                      ]),
              ),
            ),
            const SizedBox(height: 14),

            _field('Product Name *', _nameCtrl, hint: 'e.g. Coke 8oz'),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field('Price ₱ *', _priceCtrl, hint: '20', numeric: true)),
              const SizedBox(width: 10),
              Expanded(child: _field('Capital ₱', _capitalCtrl, hint: '14', numeric: true)),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _field('Stock *', _stockCtrl, hint: '30', numeric: true)),
              const SizedBox(width: 10),
              Expanded(child: _field('Low at', _lowAtCtrl, hint: '5', numeric: true)),
            ]),
            const SizedBox(height: 14),

            // Category selector — emoji icon auto-shows
            AppFormField(
              label: 'Category  →  auto icon: $autoEmoji',
              child: DropdownButtonFormField<String>(
                value: _cat,
                dropdownColor: AppColors.dark2,
                isExpanded: true,
                style: const TextStyle(color: AppColors.textColor, fontSize: 15),
                decoration: InputDecoration(
                  fillColor: AppColors.card,
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.glassBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.glassBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: kCategories.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Row(children: [
                      Text(categoryEmoji(c), style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Text(c, style: const TextStyle(fontSize: 14)),
                    ]),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _cat = v ?? _cat),
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
                label: _isEdit ? 'Save Changes' : 'Save Product',
                icon: Icons.save_outlined,
                onTap: () => _save(context),
                width: double.infinity),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, bool numeric = false}) {
    return AppFormField(
      label: label,
      child: TextField(
        controller: ctrl,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.textColor, fontSize: 15),
        decoration: InputDecoration(hintText: hint),
      ),
    );
  }
}
