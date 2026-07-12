import '../models/validation_models.dart';
import 'rule_resolver.dart';

typedef MessageResolver = String Function(String messageKey, {int? min});

class ValidationEngine {
  ValidationEngine({RuleResolver? resolver}) : _resolver = resolver ?? RuleResolver();

  final RuleResolver _resolver;

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

    String fail(String ruleKey) {
      final msgKey = v.errorMessages[ruleKey];
      final message = msgKey != null
          ? _resolveMessage(config, msgKey, locale, min: v.minLength)
          : null;
      return message ?? 'Invalid';
    }

    if (v.required == true && text.trim().isEmpty) {
      return ValidationResult(errorKey: 'required', message: fail('required'));
    }
    if (text.isEmpty) return const ValidationResult();

    if (v.minLength != null && text.length < v.minLength!) {
      return ValidationResult(errorKey: 'min_length', message: fail('min_length'));
    }
    if (v.maxLength != null && text.length > v.maxLength!) {
      return ValidationResult(errorKey: 'max_length', message: fail('max_length'));
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
          message: fail(v.dateConstraint == 'past' ? 'date_past' : 'date_future'),
        );
      }
      final now = DateTime.now();
      if (v.dateConstraint == 'past' && !date.isBefore(now)) {
        return ValidationResult(errorKey: 'date_past', message: fail('date_past'));
      }
      if (v.dateConstraint == 'future' && !date.isAfter(now)) {
        return ValidationResult(errorKey: 'date_future', message: fail('date_future'));
      }
    }

    return const ValidationResult();
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
        'mixed_case' => RegExp(r'[a-z]').hasMatch(text) && RegExp(r'[A-Z]').hasMatch(text),
        'numbers' => RegExp(r'\d').hasMatch(text),
        'symbols' => RegExp(r'[^a-zA-Z0-9]').hasMatch(text),
        'confirmed' =>
          confirmedField != null && text == _asString(allValues[confirmedField]),
        _ => true,
      };

  String _asString(dynamic value) => value?.toString() ?? '';

  String _resolveMessage(
    ValidationConfig config,
    String key,
    String locale, {
    int? min,
  }) {
    final def = config.messages[key];
    if (def == null) return key;
    var msg = def.forLocale(locale);
    if (min != null) msg = msg.replaceAll('{{min}}', '$min');
    return msg;
  }
}
