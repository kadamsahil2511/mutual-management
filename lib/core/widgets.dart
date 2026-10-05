import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';

String money(num value, {int decimals = 2}) => value.isFinite
    ? NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: decimals,
      ).format(value)
    : '—';

String dateLabel(DateTime date) => DateFormat('d MMM yyyy').format(date);

String percentLabel(num? value) => value == null || !value.isFinite
    ? 'Unavailable'
    : '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';

double pagePadding(double width) => width < 640 ? 16 : 24;

bool isMobileLayout(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  return size.width < 768 || (size.width < 1024 && size.height < 600);
}

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final small = isMobileLayout(context);
      return SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                pagePadding(constraints.maxWidth),
                small
                    ? 16
                    : constraints.maxWidth < 1024
                    ? 64
                    : 80,
                pagePadding(constraints.maxWidth),
                small ? 24 : 96,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: small
                          ? 26
                          : constraints.maxWidth < 1024
                          ? 64
                          : 80,
                      fontWeight: FontWeight.w400,
                      height: 1.08,
                      letterSpacing: small ? -.5 : -1.2,
                      color: AppColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: small ? 8 : 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: small ? 14 : 17,
                          height: small ? 1.45 : 1.6,
                          color: AppColors.body,
                        ),
                      ),
                    ),
                  ],
                  if (action != null) ...[
                    SizedBox(height: small ? 16 : 24),
                    Align(alignment: Alignment.centerLeft, child: action!),
                  ],
                  SizedBox(height: small ? 20 : 40),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.color, this.padding});
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Material(
    color: color ?? AppColors.canvas,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: color == null
          ? const BorderSide(color: AppColors.hairline)
          : BorderSide.none,
    ),
    child: Padding(
      padding:
          padding ??
          (isMobileLayout(context) ||
                  MediaQuery.textScalerOf(context).scale(16) > 20
              ? const EdgeInsets.all(16)
              : const EdgeInsets.all(32)),
      child: child,
    ),
  );
}

class MoneyText extends StatelessWidget {
  const MoneyText(this.value, {super.key, this.size = 18, this.color});
  final num value;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        money(value),
        style: numberStyle(size: size, color: color),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.soft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.strong,
          child: Icon(Icons.auto_awesome_outlined, color: AppColors.ink),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(color: AppColors.body, height: 1.6),
        ),
        if (action != null) ...[const SizedBox(height: 24), action!],
      ],
    ),
  );
}

class SourceLink extends StatelessWidget {
  const SourceLink({super.key, required this.label, required this.url});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () async {
      final uri = Uri.tryParse(url);
      final opened =
          uri != null &&
          (uri.scheme == 'https' || uri.scheme == 'http') &&
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This source could not be opened. Please try again.'),
          ),
        );
      }
    },
    style: TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [Text(label), const Icon(Icons.open_in_new_rounded, size: 16)],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: isMobileLayout(context) ? 16 : 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobileLayout(context) ? 21 : 30,
            fontWeight: FontWeight.w400,
            height: 1.2,
            letterSpacing: -.5,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 10),
          Text(
            subtitle!,
            style: const TextStyle(color: AppColors.body, height: 1.5),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 12), action!],
      ],
    ),
  );
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.maxColumns = 3,
    this.minWidth = 280,
    this.spacing = 24,
  });
  final List<Widget> children;
  final int maxColumns;
  final double minWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final columns = math.max(
        1,
        math.min(
          maxColumns,
          ((constraints.maxWidth + spacing) /
                  (minWidth * math.min(scale, 1.5) + spacing))
              .floor(),
        ),
      );
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class Metric extends StatelessWidget {
  const Metric({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.color,
    this.large = false,
  });
  final String label;
  final String value;
  final String? note;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.body,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        value,
        style: numberStyle(
          size: large ? 28 : 20,
          color: color ?? AppColors.ink,
        ),
      ),
      if (note != null) ...[
        const SizedBox(height: 6),
        Text(
          note!,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.body,
            height: 1.5,
          ),
        ),
      ],
    ],
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Loading your data…'});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.body),
        ),
      ],
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.soft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 28, color: AppColors.body),
        const SizedBox(height: 16),
        const Text(
          'A little interruption',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(color: AppColors.body, height: 1.5),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class SmallLabel extends StatelessWidget {
  const SmallLabel(this.text, {super.key, this.dark = false});
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      letterSpacing: 1.7,
      fontWeight: FontWeight.w600,
      color: dark ? AppColors.onDarkSoft : AppColors.body,
      height: 1.5,
    ),
  );
}
