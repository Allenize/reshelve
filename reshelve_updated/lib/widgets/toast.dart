import 'package:flutter/material.dart';
import '../theme.dart';

void showToast(BuildContext context, String message, {Color? color}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      backgroundColor: color ?? AppColors.card2,
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      duration: const Duration(seconds: 2),
    ),
  );
}
