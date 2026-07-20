# Error codes catalog (API → localized message)

## Goal
Host apps look up backend error codes (e.g. `AUTH_001`) via the validation SDK and show a localized user message. Catalog lives in `validation.json`, appendable from the dashboard and delivered through existing sync.

## JSON
```json
"error_codes": {
  "AUTH_001": { "en": "Invalid identifier or password", "ar": "" },
  "AUTH_002": { "en": "Access token missing, malformed, or expired", "ar": "" }
}
```
- Optional top-level key; missing → `{}`.
- Same locale fields as `messages` (`en` / `ar` / `it`); missing locale → `""`.

## API
```dart
String? errorMessage(String code, {String locale = 'en'});
```
- Unknown code → `null`
- Requested locale empty → fall back to `en`
- `en` empty → `null`

## Model
Reuse `MessageDef`. Add `resolvedForLocale` for nullable lookup with `en` fallback. Parsing tolerates missing locale keys.

## Out of scope
Field validation still uses `messages` / `error_messages`. No change to validation rules.
