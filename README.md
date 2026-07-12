# validation_sdk

Flutter SDK to consume `validation.json` from any app — sync, tenant rules, field validation.

## Install

```yaml
dependencies:
  validation_sdk:
    path: ../validation_sdk   # or git / pub.dev when published
```

## Setup

1. Copy `validation.json` → `assets/validation/validation.json`
2. Register the asset in your app `pubspec.yaml`
3. Initialize on startup

```dart
import 'package:validation_sdk/validation_sdk.dart';

final validation = ValidationSdk(
  assetPath: 'assets/validation/validation.json',
  remoteUrl: 'https://cdn.example.com/validation/validation.json',
);

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await validation.initialize();
  validation.sync(appVersion: '3.0.0'); // non-blocking
  validation.listen((config) {
    // immediate apply_policy — refresh UI if needed
  });
}
```

## Validate a field

```dart
final result = validation.validate(
  screen: 'basic_data',
  fieldId: 'phone',
  value: phoneController.text,
  allValues: {'phone': phoneController.text, 'email': emailController.text},
  tenantId: currentTenantId,
  locale: 'ar',
);

if (!result.isValid) {
  showError(result.message);
}
```

## Validate a whole screen

```dart
final errors = validation.validateScreen(
  screen: 'login',
  form: 'egyptian_form',
  values: {
    'national_id': idController.text,
    'password': passwordController.text,
  },
  tenantId: tenantId,
);
```

## Multi-form screens

Use both `screen` and `form`:

```dart
validation.rules(
  screen: 'login',
  form: 'non_egyptian_form',
  fieldId: 'residence',
  tenantId: tenantId,
);
```

## Sync outcomes

```dart
final outcome = await validation.sync(appVersion: '3.0.0');

if (outcome.requiresStoreUpdate) {
  // show force-update dialog → store
}
```

| Status | Meaning |
|--------|---------|
| `upToDate` | Remote same or older version |
| `updated` | Applied immediately |
| `pendingNextLaunch` | Saved to pending file |
| `forceUpdateRequired` | Block user until app update |
| `fetchFailed` | Network error — keep cached config |

## Architecture

```
ValidationSdk
├── ValidationConfigRepository   init(), sync(), active config
└── ValidationEngine             rules(), validate(), validateScreen()
```

Read rules **at validate time**, not at widget build — so remote updates apply without rebuild logic.

## Related

- [README_VALIDATION_CONFIG.md](../README_VALIDATION_CONFIG.md) — JSON structure
- [README_MOBILE_INTEGRATION.md](../README_MOBILE_INTEGRATION.md) — full integration guide
- [dashboard](../dashboard/) — web admin to edit rules
