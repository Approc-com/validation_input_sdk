import '../models/validation_models.dart';
import 'rule_resolver.dart';

typedef MessageResolver = String Function(String messageKey, {int? min});

class ValidationEngine {
  ValidationEngine({RuleResolver? resolver})
      : _resolver = resolver ?? RuleResolver();

  final RuleResolver _resolver;

  /// Fallback message keys when field `error_messages` omit a rule.
  static const _ruleDefaultMessageKeys = <String, String>{
    'required': 'required',
    'min_length': 'minLength',
    'max_length': 'maxLength',
    'regex': 'regex',
    'date_past': 'birth_date_invalid',
    'date_future': 'expire_date_invalid',
    'mixed_case': 'password_mixed_case',
    'numbers': 'password_needs_number',
    'symbols': 'password_needs_symbol',
    'confirmed': 'password_mismatch',
    'letters': 'name_letters_only',
  };

  FieldRules? rules({
    required ValidationConfig config,
    required String screen,
    String? form,
    required String fieldId,
    String? tenantId,
  }) =>
      _resolver.resolve(
        config: config,
        screen: screen,
        form: form,
        fieldId: fieldId,
        tenantId: tenantId,
      );

  ValidationResult validate({
    required ValidationConfig config,
    required String screen,
    String? form,
    required String fieldId,
    required dynamic value,
    required Map<String, dynamic> allValues,
    String? tenantId,
    String locale = 'en',
  }) {
    final fieldRules = rules(
      config: config,
      screen: screen,
      form: form,
      fieldId: fieldId,
      tenantId: tenantId,
    );
    if (fieldRules == null) return const ValidationResult();

    return _validateField(
      config: config,
      rules: fieldRules,
      value: value,
      allValues: allValues,
      locale: locale,
    );
  }

  ValidationResult _validateField({
    required ValidationConfig config,
    required FieldRules rules,
    required dynamic value,
    required Map<String, dynamic> allValues,
    required String locale,
  }) {
    final v = rules.validation;
    final text = _asString(value);

    String fail(String ruleKey) => _messageForRule(
          config: config,
          errorMessages: v.errorMessages,
          ruleKey: ruleKey,
          locale: locale,
          min: v.minLength,
          max: v.maxLength,
        );

    if (v.required == true && text.trim().isEmpty) {
      return ValidationResult(errorKey: 'required', message: fail('required'));
    }
    if (text.isEmpty) return const ValidationResult();

    if (v.minLength != null && text.length < v.minLength!) {
      return ValidationResult(
        errorKey: 'min_length',
        message: fail('min_length'),
      );
    }
    if (v.maxLength != null && text.length > v.maxLength!) {
      return ValidationResult(
        errorKey: 'max_length',
        message: fail('max_length'),
      );
    }

    if (rules.patternDef != null) {
      try {
        if (!RegExp(rules.patternDef!.regex).hasMatch(text)) {
          return ValidationResult(errorKey: 'regex', message: fail('regex'));
        }
      } catch (_) {
        return ValidationResult(errorKey: 'regex', message: fail('regex'));
      }
      for (final extra in rules.patternDef!.extra) {
        if (!_passesExtra(extra, text)) {
          return ValidationResult(errorKey: 'regex', message: fail('regex'));
        }
      }
    }

    for (final rule in v.customRules) {
      if (!_passesCustom(rule, text, v.confirmedField, allValues)) {
        return ValidationResult(errorKey: rule, message: fail(rule));
      }
    }

    if (rules.fieldType == 'date' && v.dateConstraint != null) {
      final date = DateTime.tryParse(text);
      if (date == null) {
        return ValidationResult(
          errorKey: v.dateConstraint,
          message: fail(
            v.dateConstraint == 'past' ? 'date_past' : 'date_future',
          ),
        );
      }
      final now = DateTime.now();
      if (v.dateConstraint == 'past' && !date.isBefore(now)) {
        return ValidationResult(
          errorKey: 'date_past',
          message: fail('date_past'),
        );
      }
      if (v.dateConstraint == 'future' && !date.isAfter(now)) {
        return ValidationResult(
          errorKey: 'date_future',
          message: fail('date_future'),
        );
      }
    }

    return const ValidationResult();
  }

  /// Resolves a user-facing message for [ruleKey] without throwing:
  /// 1) field `error_messages[rule]` → catalog
  /// 2) catalog key == rule / camelCase alias / default map
  /// 3) catalog `invalid`
  /// 4) locale default string
  String _messageForRule({
    required ValidationConfig config,
    required Map<String, String> errorMessages,
    required String ruleKey,
    required String locale,
    int? min,
    int? max,
  }) {
    final candidates = <String>[
      if ((errorMessages[ruleKey] ?? '').trim().isNotEmpty)
        errorMessages[ruleKey]!.trim(),
      ruleKey,
      _snakeToCamel(ruleKey),
      if (_ruleDefaultMessageKeys[ruleKey] != null)
        _ruleDefaultMessageKeys[ruleKey]!,
      'invalid',
    ];

    for (final key in candidates) {
      final resolved = _resolveMessage(
        config,
        key,
        locale,
        min: min,
        max: max,
      );
      if (resolved != null) return resolved;
    }

    return _localeFallback(locale);
  }

  bool _passesExtra(String rule, String text) => switch (rule) {
        'not_prefix_00' => !text.startsWith('00'),
        'not_all_zeros' => !RegExp(r'^0+$').hasMatch(text),
        _ => true,
      };

  bool _passesCustom(
    String rule,
    String text,
    String? confirmedField,
    Map<String, dynamic> allValues,
  ) =>
      switch (rule) {
        'mixed_case' =>
          RegExp(r'[a-z]').hasMatch(text) && RegExp(r'[A-Z]').hasMatch(text),
        'numbers' => RegExp(r'\d').hasMatch(text),
        'symbols' => RegExp(r'[^a-zA-Z0-9]').hasMatch(text),
        'confirmed' =>
          confirmedField != null &&
              text == _asString(allValues[confirmedField]),
        'letters' => RegExp(r'^[\u0600-\u06FFa-zA-Z\s]+$').hasMatch(text),
        _ => true,
      };

  String _asString(dynamic value) => value?.toString() ?? '';

  /// Returns null when [key] is missing from the catalog (so callers can fall back).
  String? _resolveMessage(
    ValidationConfig config,
    String key,
    String locale, {
    int? min,
    int? max,
  }) {
    final def = config.messages[key];
    if (def == null) return null;
    var msg = def.forLocale(locale).trim();
    if (msg.isEmpty) return null;
    if (min != null) msg = msg.replaceAll('{{min}}', '$min');
    if (max != null) msg = msg.replaceAll('{{max}}', '$max');
    return msg;
  }

  static String _snakeToCamel(String key) {
    final parts = key.split('_');
    if (parts.length < 2) return key;
    final buffer = StringBuffer(parts.first);
    for (var i = 1; i < parts.length; i++) {
      final p = parts[i];
      if (p.isEmpty) continue;
      buffer.write(p[0].toUpperCase());
      if (p.length > 1) buffer.write(p.substring(1));
    }
    return buffer.toString();
  }

  static String _localeFallback(String locale) {
    final lang = locale.split(RegExp(r'[-_]')).first.toLowerCase();
    return switch (lang) {
      'ar' => 'غير صحيح',
      'it' => 'Non valido',
      _ => 'Invalid',
    };
  }
}
