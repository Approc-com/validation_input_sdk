import 'engine/validation_engine.dart';
import 'models/validation_models.dart';
import 'repository/validation_config_repository.dart';

/// Drop-in validation SDK for any Flutter app.
class ValidationSdk {
  ValidationSdk({
    required String assetPath,
    String? defaultValidationJsonFileUrl,
    String? remoteUrl,
    String subdirectory = 'validation',
  }) : repository = ValidationConfigRepository(
          assetPath: assetPath,
          defaultValidationJsonFileUrl:
              defaultValidationJsonFileUrl ?? remoteUrl,
          subdirectory: subdirectory,
        ),
        engine = ValidationEngine();

  final ValidationConfigRepository repository;
  final ValidationEngine engine;

  ValidationConfig get config => repository.active;

  /// Call on app start (non-blocking after init).
  Future<void> initialize() => repository.init();

  /// Background sync — pass active validation.json semver and optional URL.
  Future<SyncOutcome> sync({
    required String localValidationFileVersion,
    String? validationJsonFileUrl,
  }) =>
      repository.sync(
        localValidationFileVersion: localValidationFileVersion,
        validationJsonFileUrl: validationJsonFileUrl,
      );

  FieldRules? rules({
    required String screen,
    String? form,
    required String fieldId,
    String? tenantId,
  }) =>
      engine.rules(
        config: config,
        screen: screen,
        form: form,
        fieldId: fieldId,
        tenantId: tenantId,
      );

  ValidationResult validate({
    required String screen,
    String? form,
    required String fieldId,
    required dynamic value,
    required Map<String, dynamic> allValues,
    String? tenantId,
    String locale = 'en',
  }) =>
      engine.validate(
        config: config,
        screen: screen,
        form: form,
        fieldId: fieldId,
        value: value,
        allValues: allValues,
        tenantId: tenantId,
        locale: locale,
      );

  /// Validate every field on a screen; returns fieldId → error message.
  Map<String, String> validateScreen({
    required String screen,
    String? form,
    required Map<String, dynamic> values,
    String? tenantId,
    String locale = 'en',
  }) {
    final screenDef = config.screens.cast<ScreenDef?>().firstWhere(
          (s) =>
              s!.screen == screen &&
              (form == null ? s.form == null : s.form == form),
          orElse: () => null,
        );
    if (screenDef == null) return {};

    final errors = <String, String>{};
    for (final field in screenDef.fields) {
      final result = validate(
        screen: screen,
        form: form,
        fieldId: field.id,
        value: values[field.id],
        allValues: values,
        tenantId: tenantId,
        locale: locale,
      );
      if (!result.isValid && result.message != null) {
        errors[field.id] = result.message!;
      }
    }
    return errors;
  }

  /// Localized API/backend error text; `null` if code unknown or empty.
  String? errorMessage(String code, {String locale = 'en'}) =>
      config.errorCodes[code]?.resolvedForLocale(locale);

  /// Ordered client action IDs for an API error code; empty if none/unknown.
  List<String> errorActions(String code) =>
      config.errorCodes[code]?.actions ?? const [];

  void listen(void Function(ValidationConfig config) listener) {
    repository.onConfigUpdated = listener;
  }
}
