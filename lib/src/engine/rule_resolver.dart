import '../models/validation_models.dart';

class RuleResolver {
  FieldRules? resolve({
    required ValidationConfig config,
    required String screen,
    String? form,
    required String fieldId,
    String? tenantId,
  }) {
    final screenDef = config.screens.cast<ScreenDef?>().firstWhere(
          (s) =>
              s!.screen == screen &&
              (form == null ? s.form == null : s.form == form),
          orElse: () => null,
        );
    if (screenDef == null) return null;

    final field = screenDef.fields.cast<FieldDef?>().firstWhere(
          (f) => f!.id == fieldId,
          orElse: () => null,
        );
    if (field == null) return null;

    final validation = field.validation.effectiveForTenant(tenantId);
    PatternDef? patternDef;
    final patternKey = validation.pattern;
    if (patternKey != null) {
      patternDef = config.patterns[patternKey];
    }

    return FieldRules(
      fieldId: fieldId,
      fieldType: field.type,
      validation: validation,
      patternDef: patternDef,
    );
  }
}
