import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/app_store.dart';
import '../services/database_service.dart';
import '../theme.dart';
import '../widgets/shared_widgets.dart';
import '../widgets/toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pinEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkPin();
  }

  Future<void> _checkPin() async {
    final has = await DatabaseService.instance.hasPin();
    if (mounted) setState(() => _pinEnabled = has);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();

    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const AppTopBar(
          wordmark: 'Settings',
          title: 'Settings',
          subtitle: 'Security, backup & preferences',
        ),

        // ── Security ──────────────────────────────────────────────────────────
        _Section(title: 'Security', children: [
          _SettingTile(
            icon: Icons.lock_outline,
            iconColor: AppColors.primary,
            label: _pinEnabled ? 'Change PIN' : 'Set Admin PIN',
            sub: _pinEnabled
                ? 'PIN is active — protects delete operations'
                : 'Lock destructive actions with a PIN',
            onTap: () => _showPinSetup(context),
          ),
          if (_pinEnabled)
            _SettingTile(
              icon: Icons.lock_open_outlined,
              iconColor: AppColors.danger,
              label: 'Remove PIN',
              sub: 'Disable PIN protection',
              onTap: () => _removePin(context),
            ),
        ]),

        // ── Backup ────────────────────────────────────────────────────────────
        _Section(title: 'Backup & Export', children: [
          _SettingTile(
            icon: Icons.cloud_done_outlined,
            iconColor: AppColors.accent,
            label: 'Auto Backup',
            sub: 'Saves automatically after every change (always on)',
            onTap: null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('ON', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
          _SettingTile(
            icon: Icons.download_outlined,
            iconColor: AppColors.info,
            label: 'Export JSON Backup',
            sub: 'Share full data backup file',
            onTap: () async {
              final json = await store.exportJson();
              final dir = await getTemporaryDirectory();
              final file = File('${dir.path}/reshelve_backup_${DateTime.now().millisecondsSinceEpoch}.json');
              await file.writeAsString(json);
              await Share.shareXFiles([XFile(file.path)], text: 'Reshelve Backup');
            },
          ),
          _SettingTile(
            icon: Icons.folder_outlined,
            iconColor: AppColors.info,
            label: 'Local Backup Location',
            sub: 'Auto-saved to app documents folder',
            onTap: () async {
              final path = await DatabaseService.instance.getBackupPath();
              if (context.mounted) showToast(context, path, color: AppColors.info);
            },
          ),
        ]),

        // ── Data ──────────────────────────────────────────────────────────────
        _Section(title: 'Data & Statistics', children: [
          _InfoTile(label: 'Total Products', value: '${store.products.length}'),
          _InfoTile(label: 'Total Sales', value: '${store.sales.length}'),
          _InfoTile(label: 'Open Debts', value: '${store.debts.where((d) => !d.paid).length}'),
          _InfoTile(label: 'Total Revenue', value: '₱${store.totalRevenue.toStringAsFixed(2)}'),
          _InfoTile(label: 'Inventory Value', value: '₱${store.totalInventoryValue.toStringAsFixed(2)}'),
        ]),

        // ── About ─────────────────────────────────────────────────────────────
        _Section(title: 'About', children: [
          _InfoTile(label: 'App', value: 'Reshelve POS'),
          _InfoTile(label: 'Version', value: '1.1.0'),
        ]),

        // ── Danger Zone ───────────────────────────────────────────────────────
        _Section(title: 'Danger Zone', children: [
          _SettingTile(
            icon: Icons.delete_forever_outlined,
            iconColor: AppColors.danger,
            label: 'Clear All Data',
            sub: 'Permanently wipes all products, sales & debts',
            onTap: () => _confirmClear(context, store),
          ),
        ]),

        const SizedBox(height: 48),
      ]),
    );
  }

  void _showPinSetup(BuildContext context) async {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          backgroundColor: AppColors.dark2,
          title: const Text('Set Admin PIN',
              style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Enter a 4–6 digit PIN to protect delete operations.',
                style: TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl1,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              maxLength: 6,
              style: const TextStyle(color: AppColors.textColor, fontSize: 22, letterSpacing: 8),
              decoration: const InputDecoration(labelText: 'New PIN', counterText: ''),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl2,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              style: const TextStyle(color: AppColors.textColor, fontSize: 22, letterSpacing: 8),
              decoration: const InputDecoration(labelText: 'Confirm PIN', counterText: ''),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
            TextButton(
              onPressed: () async {
                final p1 = ctrl1.text;
                final p2 = ctrl2.text;
                if (p1.length < 4) {
                  setSt(() => error = 'PIN must be at least 4 digits');
                  return;
                }
                if (p1 != p2) {
                  setSt(() => error = 'PINs do not match');
                  return;
                }
                await DatabaseService.instance.savePin(p1);
                if (context.mounted) Navigator.pop(context);
                setState(() => _pinEnabled = true);
                if (context.mounted) showToast(context, 'PIN set successfully!');
              },
              child: const Text('Save PIN',
                  style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
          ],
        );
      }),
    );
  }

  void _removePin(BuildContext context) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: const Text('Remove PIN?',
            style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter current PIN to confirm:', style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            autofocus: true,
            maxLength: 6,
            style: const TextStyle(color: AppColors.textColor, fontSize: 22, letterSpacing: 8),
            decoration: const InputDecoration(counterText: ''),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () async {
              final ok = await DatabaseService.instance.verifyPin(ctrl.text);
              if (context.mounted) Navigator.pop(context, ok);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await DatabaseService.instance.savePin('');
      setState(() => _pinEnabled = false);
      if (context.mounted) showToast(context, 'PIN removed');
    } else if (confirmed == false) {
      if (context.mounted) showToast(context, 'Incorrect PIN', color: AppColors.danger);
    }
  }

  void _confirmClear(BuildContext context, AppStore store) async {
    final pinSet = await DatabaseService.instance.hasPin();
    if (!context.mounted) return;

    if (pinSet) {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.dark2,
          title: const Text('PIN Required', style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            obscureText: true,
            autofocus: true,
            maxLength: 6,
            style: const TextStyle(color: AppColors.textColor, fontSize: 22, letterSpacing: 8),
            decoration: const InputDecoration(hintText: 'Enter PIN', counterText: ''),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
            TextButton(
              onPressed: () async {
                final verified = await DatabaseService.instance.verifyPin(ctrl.text);
                if (context.mounted) Navigator.pop(context, verified);
              },
              child: const Text('Confirm', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (ok != true) {
        if (context.mounted) showToast(context, 'Incorrect PIN', color: AppColors.danger);
        return;
      }
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.dark2,
        title: const Text('Clear All Data?', style: TextStyle(color: AppColors.textColor, fontWeight: FontWeight.w700)),
        content: const Text('This will permanently delete all products, sales, and debts. Cannot be undone.',
            style: TextStyle(color: AppColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted))),
          TextButton(
            onPressed: () {
              store.clearAll();
              Navigator.pop(context);
              showToast(context, 'All data cleared', color: AppColors.danger);
            },
            child: const Text('Clear All', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SectionHeader(title: title),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(children: children),
        ),
      ]),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String sub;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sub,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textColor)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4)),
          ])),
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: AppColors.muted, size: 18) : const SizedBox()),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted2)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textColor)),
        ],
      ),
    );
  }
}
