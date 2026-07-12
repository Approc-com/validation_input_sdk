import 'dart:convert';

class ValidationConfig {
  ValidationConfig({
    required this.version,
    required this.updatedAt,
    required this.sync,
    required this.patterns,
    required this.messages,
    required this.screens,
  });

  final String version;
  final String updatedAt;
  final SyncConfig sync;
  final Map<String, PatternDef> patterns;
  final Map<String, MessageDef> messages;
  final List<ScreenDef> screens;

  factory ValidationConfig.fromJson(Map<String, dynamic> json) =>
      ValidationConfig(
        version: json['version'] as String,
        updatedAt: json['updated_at'] as String,
        sync: SyncConfig.fromJson(json['sync'] as Map<String, dynamic>),
        patterns: (json['patterns'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, PatternDef.fromJson(v as Map<String, dynamic>)),
        ),
        messages: (json['messages'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, MessageDef.fromJson(v as Map<String, dynamic>)),
        ),
        screens: (json['screens'] as List)
            .map((e) => ScreenDef.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

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
    required this.minAppVersion,
    required this.forceAppUpdate,
    required this.applyPolicy,
  });

  final String minAppVersion;
  final bool forceAppUpdate;
  final String applyPolicy;

  factory SyncConfig.fromJson(Map<String, dynamic> json) => SyncConfig(
        minAppVersion: json['min_app_version'] as String,
        forceAppUpdate: json['force_app_update'] as bool,
        applyPolicy: json['apply_policy'] as String,
      );

  Map<String, dynamic> toJson() => {
        'min_app_version': minAppVersion,
        'force_app_update': forceAppUpdate,
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
  const MessageDef({required this.en, required this.ar, required this.it});

  final String en;
  final String ar;
  final String it;

  String forLocale(String locale) => switch (locale) {
        'ar' => ar,
        'it' => it,
        _ => en,
      };

  factory MessageDef.fromJson(Map<String, dynamic> json) => MessageDef(
        en: json['en'] as String,
        ar: json['ar'] as String,
        it: json['it'] as String,
      );
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
        id: json['id'] as String,
        type: json['type'] as String,
        validation: FieldValidation.fromJson(
          json['validation'] as Map<String, dynamic>,
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
        minLength: json['min_length'] as int?,
        maxLength: json['max_length'] as int?,
        customRules: (json['custom_rules'] as List?)?.cast<String>() ?? [],
        confirmedField: json['confirmed_field'] as String?,
        dateConstraint: json['date_constraint'] as String?,
        errorMessages: (json['error_messages'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        tenantOverrides:
            (json['tenant_overrides'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
                ) ??
                {},
      );

  factory FieldValidation.fromMap(Map<String, dynamic> json) => FieldValidation(
        required: json['required'] as bool?,
        pattern: json['pattern'] as String?,
        minLength: json['min_length'] as int?,
        maxLength: json['max_length'] as int?,
        customRules: (json['custom_rules'] as List?)?.cast<String>() ?? [],
        confirmedField: json['confirmed_field'] as String?,
        dateConstraint: json['date_constraint'] as String?,
        errorMessages: (json['error_messages'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
      );

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

  bool get requiresStoreUpdate => status == SyncStatus.forceUpdateRequired;
}

enum SyncStatus {
  upToDate,
  updated,
  pendingNextLaunch,
  forceUpdateRequired,
  fetchFailed,
  invalidRemote,
}
