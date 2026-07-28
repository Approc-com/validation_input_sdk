import 'dart:convert';

class ValidationConfig {
  ValidationConfig({
    required this.version,
    required this.updatedAt,
    required this.sync,
    required this.patterns,
    required this.messages,
    this.actions = const [],
    this.errorCodes = const {},
    required this.screens,
  });

  final String version;
  final String updatedAt;
  final SyncConfig sync;
  final Map<String, PatternDef> patterns;
  final Map<String, MessageDef> messages;
  final List<String> actions;
  final Map<String, ErrorCodeDef> errorCodes;
  final List<ScreenDef> screens;

  factory ValidationConfig.fromJson(Map<String, dynamic> json) =>
      ValidationConfig(
        version: json['version']?.toString() ?? '0.0.0',
        updatedAt: json['updated_at']?.toString() ?? '',
        sync: SyncConfig.fromJson(
          json['sync'] is Map
              ? Map<String, dynamic>.from(json['sync'] as Map)
              : const <String, dynamic>{},
        ),
        patterns: _parsePatterns(json['patterns']),
        messages: _parseMessages(json['messages']),
        actions: (json['actions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        errorCodes: _parseErrorCodes(json['error_codes']),
        screens: (json['screens'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ScreenDef.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  static Map<String, PatternDef> _parsePatterns(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, PatternDef>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      out[entry.key.toString()] =
          PatternDef.fromJson(Map<String, dynamic>.from(value));
    }
    return out;
  }

  static Map<String, MessageDef> _parseMessages(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, MessageDef>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      out[entry.key.toString()] =
          MessageDef.fromJson(Map<String, dynamic>.from(value));
    }
    return out;
  }

  static Map<String, ErrorCodeDef> _parseErrorCodes(Object? raw) {
    if (raw is! Map) return const {};
    final out = <String, ErrorCodeDef>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is! Map) continue;
      out[entry.key.toString()] =
          ErrorCodeDef.fromJson(Map<String, dynamic>.from(value));
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'updated_at': updatedAt,
        'sync': sync.toJson(),
        'patterns': patterns.map((k, v) => MapEntry(k, v.toJson())),
        'messages': messages.map((k, v) => MapEntry(k, {
              'en': v.en,
              'ar': v.ar,
              'it': v.it,
            })),
        if (actions.isNotEmpty) 'actions': actions,
        if (errorCodes.isNotEmpty)
          'error_codes':
              errorCodes.map((k, v) => MapEntry(k, v.toJson())),
        'screens': screens.map((e) => _screenToJson(e)).toList(),
      };

  static Map<String, dynamic> _screenToJson(ScreenDef s) => {
        'screen': s.screen,
        if (s.form != null) 'form': s.form,
        'version': s.version,
        'fields': s.fields.map((f) => {
              'id': f.id,
              'type': f.type,
              'validation': _validationToJson(f.validation),
            }).toList(),
      };

  static Map<String, dynamic> _validationToJson(FieldValidation v) => {
        if (v.required != null) 'required': v.required,
        if (v.pattern != null) 'pattern': v.pattern,
        if (v.minLength != null) 'min_length': v.minLength,
        if (v.maxLength != null) 'max_length': v.maxLength,
        if (v.customRules.isNotEmpty) 'custom_rules': v.customRules,
        if (v.confirmedField != null) 'confirmed_field': v.confirmedField,
        if (v.dateConstraint != null) 'date_constraint': v.dateConstraint,
        if (v.errorMessages.isNotEmpty) 'error_messages': v.errorMessages,
        if (v.tenantOverrides.isNotEmpty) 'tenant_overrides': v.tenantOverrides,
      };

  static ValidationConfig parse(String raw) =>
      ValidationConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

class SyncConfig {
  const SyncConfig({
    required this.minValidationFileVersionAllowed,
    required this.forceValidationFileUpdate,
    required this.applyPolicy,
  });

  final String minValidationFileVersionAllowed;
  final bool forceValidationFileUpdate;
  final String applyPolicy;

  factory SyncConfig.fromJson(Map<String, dynamic> json) => SyncConfig(
        minValidationFileVersionAllowed:
            json['min_validation_file_version_allowed']?.toString() ?? '0.0.0',
        forceValidationFileUpdate: json['force_validation_file_update'] == true,
        applyPolicy: json['apply_policy']?.toString() ?? 'immediate',
      );

  Map<String, dynamic> toJson() => {
        'min_validation_file_version_allowed': minValidationFileVersionAllowed,
        'force_validation_file_update': forceValidationFileUpdate,
        'apply_policy': applyPolicy,
      };
}

class PatternDef {
  const PatternDef({required this.regex, this.extra = const []});

  final String regex;
  final List<String> extra;

  factory PatternDef.fromJson(Map<String, dynamic> json) => PatternDef(
        regex: json['regex'] as String,
        extra: (json['extra'] as List?)?.cast<String>() ?? [],
      );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'regex': regex};
    if (extra.isNotEmpty) map['extra'] = extra;
    return map;
  }
}

class MessageDef {
  const MessageDef({this.en = '', this.ar = '', this.it = ''});

  final String en;
  final String ar;
  final String it;

  /// Prefers [locale], then falls back to non-empty `en` / `ar` / `it`.
  String forLocale(String locale) {
    final lang = locale.split(RegExp(r'[-_]')).first.toLowerCase();
    final primary = switch (lang) {
      'ar' => ar,
      'it' => it,
      _ => en,
    };
    if (primary.trim().isNotEmpty) return primary;
    if (en.trim().isNotEmpty) return en;
    if (ar.trim().isNotEmpty) return ar;
    return it;
  }

  factory MessageDef.fromJson(Map<String, dynamic> json) => MessageDef(
        en: _asTrimmedString(json['en']),
        ar: _asTrimmedString(json['ar']),
        it: _asTrimmedString(json['it']),
      );
}

class ErrorCodeDef {
  const ErrorCodeDef({
    this.en = '',
    this.ar = '',
    this.it = '',
    this.actions = const [],
  });

  final String en;
  final String ar;
  final String it;
  final List<String> actions;

  String forLocale(String locale) {
    final lang = locale.split(RegExp(r'[-_]')).first.toLowerCase();
    final primary = switch (lang) {
      'ar' => ar,
      'it' => it,
      _ => en,
    };
    if (primary.trim().isNotEmpty) return primary;
    if (en.trim().isNotEmpty) return en;
    if (ar.trim().isNotEmpty) return ar;
    return it;
  }

  /// Locale text, falling back to `en` when empty; `null` if both empty.
  String? resolvedForLocale(String locale) {
    final primary = forLocale(locale).trim();
    if (primary.isNotEmpty) return primary;
    return en.trim().isNotEmpty ? en.trim() : null;
  }

  factory ErrorCodeDef.fromJson(Map<String, dynamic> json) => ErrorCodeDef(
        en: _asTrimmedString(json['en']),
        ar: _asTrimmedString(json['ar']),
        it: _asTrimmedString(json['it']),
        actions: (json['actions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'en': en,
        'ar': ar,
        'it': it,
        if (actions.isNotEmpty) 'actions': actions,
      };
}

String _asTrimmedString(Object? value) {
  if (value == null) return '';
  return value.toString().trim();
}

Map<String, String> _stringKeyedMap(Object? raw) {
  if (raw is! Map) return const {};
  final out = <String, String>{};
  for (final entry in raw.entries) {
    final value = _asTrimmedString(entry.value);
    if (value.isEmpty) continue;
    out[entry.key.toString()] = value;
  }
  return out;
}

class ScreenDef {
  const ScreenDef({
    required this.screen,
    this.form,
    required this.version,
    required this.fields,
  });

  final String screen;
  final String? form;
  final int version;
  final List<FieldDef> fields;

  factory ScreenDef.fromJson(Map<String, dynamic> json) => ScreenDef(
        screen: json['screen'] as String,
        form: json['form'] as String?,
        version: json['version'] as int,
        fields: (json['fields'] as List)
            .map((e) => FieldDef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class FieldDef {
  const FieldDef({
    required this.id,
    required this.type,
    required this.validation,
  });

  final String id;
  final String type;
  final FieldValidation validation;

  factory FieldDef.fromJson(Map<String, dynamic> json) => FieldDef(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'text',
        validation: FieldValidation.fromJson(
          json['validation'] is Map
              ? Map<String, dynamic>.from(json['validation'] as Map)
              : const <String, dynamic>{},
        ),
      );
}

class FieldValidation {
  const FieldValidation({
    this.required,
    this.pattern,
    this.minLength,
    this.maxLength,
    this.customRules = const [],
    this.confirmedField,
    this.dateConstraint,
    this.errorMessages = const {},
    this.tenantOverrides = const {},
  });

  final bool? required;
  final String? pattern;
  final int? minLength;
  final int? maxLength;
  final List<String> customRules;
  final String? confirmedField;
  final String? dateConstraint;
  final Map<String, String> errorMessages;
  final Map<String, Map<String, dynamic>> tenantOverrides;

  factory FieldValidation.fromJson(Map<String, dynamic> json) => FieldValidation(
        required: json['required'] as bool?,
        pattern: json['pattern'] as String?,
        minLength: _asInt(json['min_length']),
        maxLength: _asInt(json['max_length']),
        customRules: (json['custom_rules'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        confirmedField: json['confirmed_field'] as String?,
        dateConstraint: json['date_constraint'] as String?,
        errorMessages: _stringKeyedMap(json['error_messages']),
        tenantOverrides:
            (json['tenant_overrides'] as Map?)?.map(
                  (k, v) => MapEntry(
                    k.toString(),
                    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{},
                  ),
                ) ??
                const {},
      );

  factory FieldValidation.fromMap(Map<String, dynamic> json) =>
      FieldValidation.fromJson(json);

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  FieldValidation merge(Map<String, dynamic> overrides) {
    final merged = <String, dynamic>{
      if (required != null) 'required': required,
      if (pattern != null) 'pattern': pattern,
      if (minLength != null) 'min_length': minLength,
      if (maxLength != null) 'max_length': maxLength,
      if (customRules.isNotEmpty) 'custom_rules': customRules,
      if (confirmedField != null) 'confirmed_field': confirmedField,
      if (dateConstraint != null) 'date_constraint': dateConstraint,
      if (errorMessages.isNotEmpty) 'error_messages': errorMessages,
      ...overrides,
    };
    return FieldValidation.fromMap(merged);
  }

  FieldValidation effectiveForTenant(String? tenantId) {
    if (tenantId == null || !tenantOverrides.containsKey(tenantId)) {
      return this;
    }
    return merge(tenantOverrides[tenantId]!);
  }
}

enum ValidationRuleKey {
  required,
  regex,
  minLength,
  maxLength,
  mixedCase,
  numbers,
  symbols,
  confirmed,
  datePast,
  dateFuture,
}

class FieldRules {
  const FieldRules({
    required this.fieldId,
    required this.fieldType,
    required this.validation,
    required this.patternDef,
  });

  final String fieldId;
  final String fieldType;
  final FieldValidation validation;
  final PatternDef? patternDef;
}

class ValidationResult {
  const ValidationResult({this.errorKey, this.message});

  final String? errorKey;
  final String? message;

  bool get isValid => errorKey == null;
}

class SyncOutcome {
  const SyncOutcome({
    required this.status,
    this.remoteVersion,
    this.message,
  });

  final SyncStatus status;
  final String? remoteVersion;
  final String? message;

  bool get isLocalValidationFileBelowMinAllowed =>
      status == SyncStatus.localValidationFileBelowMinAllowed;
}

enum SyncStatus {
  upToDate,
  updated,
  pendingNextLaunch,
  localValidationFileBelowMinAllowed,
  fetchFailed,
  invalidRemote,
}
