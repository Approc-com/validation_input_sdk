import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:validation_sdk/validation_sdk.dart';

void main() {
  late ValidationConfig config;
  late ValidationEngine engine;

  setUp(() {
    final raw = File('test/fixtures/validation.json').readAsStringSync();
    config = ValidationConfig.parse(raw);
    engine = ValidationEngine();
  });

  group('Semver', () {
    test('compare versions', () {
      expect(Semver.isGreater('2.0.0', '1.9.9'), true);
      expect(Semver.isGreater('2.0.0', '2.0.0'), false);
      expect(Semver.compare('1.0.0', '1.0.1'), -1);
    });
  });

  group('RuleResolver', () {
    test('resolves basic field', () {
      final rules = engine.rules(
        config: config,
        screen: 'basic_data',
        fieldId: 'phone',
      );
      expect(rules, isNotNull);
      expect(rules!.validation.required, true);
      expect(rules.patternDef?.regex, isNotEmpty);
    });

    test('tenant override makes ssn optional', () {
      final rules = engine.rules(
        config: config,
        screen: 'basic_data',
        fieldId: 'ssn',
        tenantId: 'tenant_042',
      );
      expect(rules!.validation.required, false);
    });

    test('login form lookup', () {
      final rules = engine.rules(
        config: config,
        screen: 'login',
        form: 'egyptian_form',
        fieldId: 'national_id',
      );
      expect(rules, isNotNull);
    });
  });

  group('ValidationEngine', () {
    test('required phone fails when empty', () {
      final result = engine.validate(
        config: config,
        screen: 'basic_data',
        fieldId: 'phone',
        value: '',
        allValues: {},
      );
      expect(result.isValid, false);
      expect(result.message, contains('phone'));
    });

    test('valid phone passes', () {
      final result = engine.validate(
        config: config,
        screen: 'basic_data',
        fieldId: 'phone',
        value: '1234567890',
        allValues: {'phone': '1234567890'},
      );
      expect(result.isValid, true);
    });

    test('password min length for tenant', () {
      final short = engine.validate(
        config: config,
        screen: 'login',
        form: 'egyptian_form',
        fieldId: 'password',
        value: 'Ab1!xy',
        allValues: {'password': 'Ab1!xy'},
        tenantId: 'tenant_117',
      );
      expect(short.isValid, false);

      final ok = engine.validate(
        config: config,
        screen: 'login',
        form: 'egyptian_form',
        fieldId: 'password',
        value: 'Abcdef1!xy',
        allValues: {'password': 'Abcdef1!xy'},
        tenantId: 'tenant_117',
      );
      expect(ok.isValid, true);
    });

    test('password mismatch', () {
      final result = engine.validate(
        config: config,
        screen: 'basic_data',
        fieldId: 'confirm_password',
        value: 'different',
        allValues: {
          'password': r'Abcdef1!@#$12',
          'confirm_password': 'different',
        },
      );
      expect(result.isValid, false);
    });
  });

  group('error_codes', () {
    test('parses catalog', () {
      expect(config.errorCodes['AUTH_001']?.en, 'Invalid identifier or password');
      expect(config.errorCodes['AUTH_002']?.en, contains('Access token'));
    });

    test('falls back to en when locale empty', () {
      expect(
        config.errorCodes['AUTH_001']?.resolvedForLocale('ar'),
        'Invalid identifier or password',
      );
    });

    test('unknown code is null', () {
      expect(config.errorCodes['AUTH_999']?.resolvedForLocale('en'), isNull);
    });
  });
}
