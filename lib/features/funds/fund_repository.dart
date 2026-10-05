import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'fund_models.dart';
import 'reference_data.dart';

class FundLoadException implements Exception {
  const FundLoadException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Public NAV cache only. No user positions or financial records are cached.
class FundRepository {
  FundRepository(
    this.preferences, {
    http.Client? client,
    DateTime Function()? now,
    this.requestTimeout = const Duration(seconds: 10),
    this.retryDelay = const Duration(milliseconds: 300),
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  static const cacheLifetime = Duration(hours: 6);
  final SharedPreferences preferences;
  final http.Client _client;
  final DateTime Function() _now;
  final Duration requestTimeout;
  final Duration retryDelay;

  Future<FundData> fetchFund(
    String schemeCode, {
    bool forceRefresh = false,
  }) async {
    final matches = fundCatalog.where((fund) => fund.schemeCode == schemeCode);
    if (matches.isEmpty) {
      throw const FundLoadException(
        'This scheme is not in the selected catalog.',
      );
    }
    final reference = matches.first;
    final key = 'nav_v1_$schemeCode';
    final cached = _readCache(key, reference);
    final now = _now().toUtc();
    if (!forceRefresh && cached != null) {
      final age = now.difference(cached.fetchedAt.toUtc());
      if (!age.isNegative && age < cacheLifetime) return cached;
    }

    String error = 'The NAV service is unavailable.';
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .get(Uri.https('api.mfapi.in', '/mf/$schemeCode'))
            .timeout(requestTimeout);
        if (response.statusCode != 200) {
          throw FundLoadException(
            'NAV service returned HTTP ${response.statusCode}.',
          );
        }
        final decoded = jsonDecode(response.body);
        final history = _parseHistory(decoded, schemeCode);
        final fetchedAt = _now().toUtc();
        String? warning;
        try {
          final saved = await preferences.setString(
            key,
            jsonEncode({
              'fetchedAt': fetchedAt.toIso8601String(),
              'payload': decoded,
            }),
          );
          if (!saved) {
            warning = 'Live NAV loaded; the local cache could not be saved.';
          }
        } catch (_) {
          warning = 'Live NAV loaded; the local cache could not be saved.';
        }
        return FundData(
          reference: reference,
          history: history,
          isCached: false,
          fetchedAt: fetchedAt,
          warning: warning,
        );
      } on TimeoutException {
        error = 'The NAV request timed out.';
      } on FormatException {
        error = 'The NAV service returned incomplete or invalid data.';
      } on FundLoadException catch (failure) {
        error = failure.message;
      } on Exception {
        error = 'Could not connect to the NAV service. Check your connection.';
      }
      if (attempt == 0 && retryDelay > Duration.zero) {
        await Future<void>.delayed(retryDelay);
      }
    }

    if (cached != null) {
      return FundData(
        reference: reference,
        history: cached.history,
        isCached: true,
        fetchedAt: cached.fetchedAt,
        warning: '$error Showing saved NAV data; refresh when online.',
      );
    }
    throw FundLoadException(
      '$error No saved NAV data is available. Please retry.',
    );
  }

  FundData? _readCache(String key, FundReference reference) {
    try {
      final raw = preferences.getString(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['fetchedAt'] is! String) {
        return null;
      }
      final fetchedAt = DateTime.parse(decoded['fetchedAt'] as String).toUtc();
      // A future timestamp cannot establish the age of cached market data.
      if (fetchedAt.isAfter(_now().toUtc())) return null;
      return FundData(
        reference: reference,
        history: _parseHistory(decoded['payload'], reference.schemeCode),
        isCached: true,
        fetchedAt: fetchedAt,
      );
    } on Exception {
      return null;
    }
  }

  List<NavPoint> _parseHistory(dynamic payload, String schemeCode) {
    if (payload is! Map<String, dynamic> ||
        payload['status'] != 'SUCCESS' ||
        payload['meta'] is! Map ||
        (payload['meta'] as Map)['scheme_code'].toString() != schemeCode ||
        payload['data'] is! List ||
        (payload['data'] as List).isEmpty) {
      throw const FormatException('Missing scheme identity or NAV history');
    }
    final points = <DateTime, double>{};
    final datePattern = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
    for (final row in payload['data'] as List) {
      if (row is! Map || row['date'] is! String) {
        throw const FormatException('Invalid NAV observation');
      }
      final match = datePattern.firstMatch(row['date'] as String);
      final nav = double.tryParse(row['nav'].toString());
      if (match == null || nav == null || !nav.isFinite || nav <= 0) {
        throw const FormatException('Invalid NAV or date');
      }
      final day = int.parse(match[1]!);
      final month = int.parse(match[2]!);
      final year = int.parse(match[3]!);
      final date = DateTime(year, month, day);
      if (date.day != day || date.month != month || date.year != year) {
        throw const FormatException('Invalid calendar date');
      }
      if (points.containsKey(date) && points[date] != nav) {
        throw const FormatException('Conflicting NAV observations');
      }
      points[date] = nav;
    }
    return points.entries
        .map((entry) => NavPoint(date: entry.key, nav: entry.value))
        .toList();
  }
}
