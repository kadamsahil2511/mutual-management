import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mutual_management/features/funds/fund_models.dart';
import 'package:mutual_management/features/funds/fund_repository.dart';
import 'package:mutual_management/features/funds/reference_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final now = DateTime.utc(2026, 10, 5, 12);
  Map<String, Object> payload({String nav = '24.00000'}) => {
    'status': 'SUCCESS',
    'meta': {'scheme_code': 118955},
    'data': [
      {'date': '01-10-2026', 'nav': nav},
      {'date': '30-09-2026', 'nav': '23.00000'},
    ],
  };
  Future<SharedPreferences> preferences({
    DateTime? fetchedAt,
    Object? data,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (fetchedAt != null)
        'nav_v1_118955': jsonEncode({
          'fetchedAt': fetchedAt.toIso8601String(),
          'payload': data ?? payload(),
        }),
    });
    return SharedPreferences.getInstance();
  }

  test('six verified direct-growth scheme identifiers are stable', () {
    expect(fundCatalog.map((fund) => fund.schemeCode), [
      '118955',
      '119718',
      '118987',
      '146215',
      '119062',
      '119609',
    ]);
  });

  test(
    'reference snapshots have dated factual fields and unique ISIN identities',
    () {
      expect(fundCatalog, hasLength(6));
      for (final reference in fundCatalog) {
        expect(reference.asOfDate, DateTime(2026, 8, 31));
        expect(reference.aumCrore, isNotNull);
        expect(reference.minLumpSumPaise, isNotNull);
        expect(reference.minSipPaise, isNotNull);
        expect(reference.expenseRatioPct, isNotNull);
        expect(reference.expenseBasis, isNotEmpty);
        expect(reference.benchmarkName, isNotNull);
        expect(reference.datedBenchmarkReturns.keys, containsAll([1, 3, 5]));
        if (reference.holdings.isNotEmpty) {
          expect(reference.holdingsDate, DateTime(2026, 8, 31));
          expect(reference.holdingsComplete, false);
          expect(
            reference.holdings.every((holding) => holding.weight > 0),
            true,
          );
        }
      }
      for (final code in ['118955', '118987', '119062']) {
        final reference = fundCatalog.firstWhere(
          (fund) => fund.schemeCode == code,
        );
        expect(reference.minimumSourceUrl, isNotNull);
        expect(reference.minimumAsOfDate, DateTime(2026, 10, 5));
      }
      expect(
        fundCatalog
            .firstWhere((fund) => fund.schemeCode == '146215')
            .managerOtherFunds,
        contains('SBI Aggressive Hybrid Fund'),
      );
      expect(
        fundCatalog
            .firstWhere((fund) => fund.schemeCode == '119609')
            .managerOtherFunds,
        contains('SBI Corporate Bond Fund'),
      );
      expect(
        fundCatalog
            .firstWhere((fund) => fund.schemeCode == '119718')
            .managerOtherFunds,
        isEmpty,
      );
      final namesById = <String, String>{};
      String normalize(String value) => value
          .toLowerCase()
          .replaceAll('&', 'and')
          .replaceAll(RegExp(r'\b(ltd|limited)\b'), '')
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      for (final holding in fundCatalog.expand((fund) => fund.holdings)) {
        final previous = namesById[holding.id];
        if (previous != null) {
          expect(
            normalize(holding.name),
            normalize(previous),
            reason: holding.id,
          );
        }
        namesById[holding.id] = holding.name;
      }
      expect(namesById['INE917I01010'], 'Bajaj Auto Ltd.');
      expect(namesById['INE296A01032'], 'Bajaj Finance Ltd.');
    },
  );

  test('valid network history is sorted and cached for six hours', () async {
    final prefs = await preferences();
    var calls = 0;
    final repo = FundRepository(
      prefs,
      now: () => now,
      client: MockClient((request) async {
        calls++;
        expect(request.url.toString(), 'https://api.mfapi.in/mf/118955');
        return http.Response(jsonEncode(payload()), 200);
      }),
    );
    final live = await repo.fetchFund('118955');
    final saved = await repo.fetchFund('118955');
    expect(live.isCached, false);
    expect(live.latest.nav, 24);
    expect(saved.isCached, true);
    expect(saved.fetchedAt, now);
    expect(calls, 1);
  });

  test(
    'exactly six hours expires and force refresh bypasses fresh cache',
    () async {
      final prefs = await preferences(
        fetchedAt: now.subtract(const Duration(hours: 6)),
      );
      var calls = 0;
      final repo = FundRepository(
        prefs,
        now: () => now,
        client: MockClient((_) async {
          calls++;
          return http.Response(jsonEncode(payload(nav: '25')), 200);
        }),
      );
      expect((await repo.fetchFund('118955')).isCached, false);
      expect(
        (await repo.fetchFund('118955', forceRefresh: true)).latest.nav,
        25,
      );
      expect(calls, 2);
    },
  );

  test('one retry can recover from an HTTP failure', () async {
    var calls = 0;
    final repo = FundRepository(
      await preferences(),
      now: () => now,
      retryDelay: Duration.zero,
      client: MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('busy', 503)
            : http.Response(jsonEncode(payload()), 200);
      }),
    );
    expect((await repo.fetchFund('118955')).latest.nav, 24);
    expect(calls, 2);
  });

  test(
    'offline fallback preserves original timestamp and explicit warning',
    () async {
      final savedAt = now.subtract(const Duration(days: 2));
      var calls = 0;
      final repo = FundRepository(
        await preferences(fetchedAt: savedAt),
        now: () => now,
        retryDelay: Duration.zero,
        client: MockClient((_) async {
          calls++;
          throw http.ClientException('offline');
        }),
      );
      final fund = await repo.fetchFund('118955');
      expect(fund.isCached, true);
      expect(fund.fetchedAt, savedAt);
      expect(fund.warning, contains('Showing saved NAV'));
      expect(calls, 2);
    },
  );

  test('timeout retries and reports no cache clearly', () async {
    var calls = 0;
    final repo = FundRepository(
      await preferences(),
      now: () => now,
      requestTimeout: const Duration(milliseconds: 1),
      retryDelay: Duration.zero,
      client: MockClient((_) {
        calls++;
        return Completer<http.Response>().future;
      }),
    );
    await expectLater(
      repo.fetchFund('118955'),
      throwsA(
        isA<FundLoadException>().having(
          (e) => e.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
    expect(calls, 2);
  });

  test(
    'malformed values, impossible dates, and wrong schemes are rejected',
    () async {
      final invalidPayloads = <Object>[
        {},
        payload(nav: 'NaN'),
        payload(nav: '0'),
        {
          ...payload(),
          'meta': {'scheme_code': 119718},
        },
        {
          ...payload(),
          'data': [
            {'date': '31-02-2026', 'nav': '12'},
          ],
        },
        {...payload(), 'data': []},
        {
          ...payload(),
          'data': [
            {'date': '01-10-2026', 'nav': '24'},
            {'date': '01-10-2026', 'nav': '25'},
          ],
        },
      ];
      for (final invalid in invalidPayloads) {
        final repo = FundRepository(
          await preferences(),
          now: () => now,
          retryDelay: Duration.zero,
          client: MockClient(
            (_) async => http.Response(jsonEncode(invalid), 200),
          ),
        );
        await expectLater(
          repo.fetchFund('118955'),
          throwsA(isA<FundLoadException>()),
        );
      }
    },
  );

  test(
    'corrupt and future-dated caches cannot be used as offline data',
    () async {
      for (final cachedAt in [now.add(const Duration(hours: 1)), now]) {
        final prefs = await preferences(
          fetchedAt: cachedAt,
          data: cachedAt == now ? {} : payload(),
        );
        final repo = FundRepository(
          prefs,
          now: () => now,
          retryDelay: Duration.zero,
          client: MockClient(
            (_) async => throw http.ClientException('offline'),
          ),
        );
        await expectLater(
          repo.fetchFund('118955'),
          throwsA(isA<FundLoadException>()),
        );
      }
    },
  );

  test(
    'missing return history is not extrapolated and NAV never looks ahead',
    () {
      final fund = FundData(
        reference: fundCatalog.first,
        isCached: false,
        fetchedAt: now,
        history: [
          NavPoint(date: DateTime(2025, 10, 1), nav: 20),
          NavPoint(date: DateTime(2026, 10, 1), nav: 24),
        ],
      );
      expect(fund.latest.nav, 24);
      expect(fund.returnYears(1), closeTo(20, 0.03));
      expect(fund.returnYears(3), isNull);
      expect(fund.navOnOrBefore(DateTime(2025, 9, 30)), isNull);
      expect(fund.navOnOrBefore(DateTime(2026, 9, 30))!.nav, 20);
    },
  );

  test('one-year NAV return is absolute across a leap-year interval', () {
    final fund = FundData(
      reference: fundCatalog.first,
      isCached: false,
      fetchedAt: now,
      history: [
        NavPoint(date: DateTime(2023, 3, 1), nav: 100),
        NavPoint(date: DateTime(2024, 3, 1), nav: 110),
      ],
    );
    expect(fund.returnYears(1), closeTo(10, 1e-9));
  });

  test('large history gaps cannot masquerade as a one-year return', () {
    final fund = FundData(
      reference: fundCatalog.first,
      isCached: false,
      fetchedAt: now,
      history: [
        NavPoint(date: DateTime(2025, 9, 1), nav: 20),
        NavPoint(date: DateTime(2026, 10, 1), nav: 24),
      ],
    );
    expect(fund.returnYears(1), isNull);
  });
}
