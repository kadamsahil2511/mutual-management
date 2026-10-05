/// Parse user-entered rupees without floating-point currency arithmetic.
int? parsePaise(String input) {
  final value = input.trim();
  if (!RegExp(r'^\d{1,9}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final paise =
      int.parse(parts[0]) * 100 +
      (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  return paise > 0 && paise <= 10000000000 ? paise : null;
}

String? amountError(String? value) => parsePaise(value ?? '') == null
    ? 'Enter a positive amount, with at most 2 decimals.'
    : null;

String? emailError(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? null
    : 'Enter a valid email address.';

String safeNextPath(String? path) {
  if (path == null ||
      !path.startsWith('/') ||
      path.startsWith('//') ||
      path.contains('\\')) {
    return '/';
  }
  final uri = Uri.tryParse(path);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return '/';
  const allowed = [
    '/',
    '/funds',
    '/portfolio',
    '/plans',
    '/learn',
    '/deposits',
    '/compare',
    '/risk',
  ];
  return allowed.contains(uri.path) ||
          uri.path.startsWith('/funds/') ||
          uri.path.startsWith('/learn/')
      ? path
      : '/';
}

DateTime? parseDate(String input) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(input)) return null;
  final date = DateTime.tryParse(input);
  if (date == null || date.toIso8601String().substring(0, 10) != input) {
    return null;
  }
  return date;
}

String dateInput(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String newRecordId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
