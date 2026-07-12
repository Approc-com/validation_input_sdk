# Mobile Integration

How to wire `validation.json` in the Flutter app (Android + iOS).

> Config file structure → see [README_VALIDATION_CONFIG.md](README_VALIDATION_CONFIG.md)

---

## Quick start

**Option A — SDK (recommended)**

```yaml
dependencies:
  validation_sdk:
    path: ../validation_sdk
```

```dart
final validation = ValidationSdk(
  assetPath: 'assets/validation/validation.json',
  remoteUrl: 'https://cdn.example.com/validation/validation.json',
);
await validation.initialize();
validation.sync(appVersion: '3.0.0');
```

See [validation_sdk/README.md](validation_sdk/README.md).

**Option B — Manual**

1. Copy `validation.json` → `assets/validation/validation.json`
2. Register in `pubspec.yaml`
3. On app start: load local cache (or asset) → fetch remote in background
4. Read field rules at validate time (not at widget build)

---

## Asset setup

```yaml
flutter:
  assets:
    - assets/validation/validation.json
```

**First launch:** copy asset → app support directory (writable cache).

---

## Storage

| File | Location | Purpose |
|------|----------|---------|
| Bundled | `assets/validation/validation.json` | Offline fallback (read-only) |
| Active | `{appSupport}/validation/validation.json` | Config the app uses |
| Pending | `{appSupport}/validation/validation_pending.json` | Applies next launch |

Use `path_provider` → `getApplicationSupportDirectory()`. **Never write to assets.**

---

## Launch flow

```
START
  ├─ active = read cache ?? copy from asset
  ├─ background: fetch remote validation.json
  ├─ remote.version <= active.version → done
  └─ remote.version > active.version
        ├─ app < sync.min_app_version + force_app_update → block, show store
        ├─ apply_policy: "next_launch" → save validation_pending.json
        └─ apply_policy: "immediate"   → atomic write + notify app
```

**Next cold start:** swap `validation_pending.json` → active.  
Do **not** block splash/login on network.

---

## Tenant rules

```
effective = field.validation defaults
          + tenant_overrides[tenantId]   (if exists)
```

Ignore the `tenant_overrides` key when applying rules.

---

## Screen lookup

| Screen | Keys |
|--------|------|
| Normal | `screen: "basic_data"` |
| Multi-form | `screen: "login"` + `form: "egyptian_form"` |

---

## Atomic write

```dart
final dir = await getApplicationSupportDirectory();
final path = '${dir.path}/validation';
final file = File('$path/validation.json');
final tmp = File('$path/validation.json.tmp');

await tmp.writeAsString(jsonEncode(config));
await tmp.rename(file.path);
```

---

## Architecture

```
ValidationConfigRepository
  init()   → load cache or asset into memory
  sync()   → background fetch + apply policy
  active   → in-memory config

ValidationEngine
  rules(screen, field, tenantId)
  validate(value, rules, allValues)
```

Validators read from `repository.active` **at validate time**, not at widget build.

---

## Sync policies

| Change | `apply_policy` | `force_app_update` |
|--------|----------------|-------------------|
| Required/optional toggle | `next_launch` | `false` |
| Message text fix | `next_launch` | `false` |
| Urgent fix | `immediate` | `false` |
| New rule type | — | `true` + bump `min_app_version` |

---

## Offline & errors

| Case | Action |
|------|--------|
| No network | Cached config, else asset |
| Bad JSON | Keep current, log error |
| Fetch fails | Retry next launch |

---

## Checklist

- [ ] Asset in `pubspec.yaml`
- [ ] Cache on first run
- [ ] Background sync on launch
- [ ] Semver compare on `version`
- [ ] `tenant_overrides[tenantId]` merged per field
- [ ] Messages by locale from `messages`
- [ ] Backend still validates on submit

---

## Remote URL

```
GET https://cdn.example.com/validation/validation.json
```

HTTPS only. Compare `version` to skip unnecessary downloads.
