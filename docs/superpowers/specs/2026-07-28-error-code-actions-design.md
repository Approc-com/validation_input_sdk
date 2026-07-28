# Error Code Actions (SDK) — Design

**Date:** 2026-07-28  
**Status:** Approved  
**Scope:** Parse/expose action IDs from `validation.json`. Host executes actions.

## Goal

Consume dashboard `actions` catalog and ordered per-error-code `actions`. Expose lookup only — no handler registry.

## JSON shape

```json
{
  "actions": ["clear_local_cache", "rerun_bootstrap"],
  "error_codes": {
    "AUTH_014": {
      "en": "Device token missing...",
      "ar": "",
      "actions": ["clear_local_cache", "rerun_bootstrap"]
    },
    "AUTH_001": {
      "en": "Invalid identifier or password",
      "ar": ""
    }
  }
}
```

## Data model

- `ValidationConfig.actions: List<String>` — catalog; default `[]`.
- `ErrorCodeDef` replaces `MessageDef` for error codes: locales + `actions` (omit when empty in `toJson`).

## API

- Keep `errorMessage(code, {locale})`.
- Add `List<String> errorActions(String code)` — ordered; unknown/empty → `[]`.

## Out of scope

- Running actions, metadata, free-form IDs.
