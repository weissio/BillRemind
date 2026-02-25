# Data Safety Release Checklist

This checklist is mandatory before every production update.

## 1. Model & migration safety
- Only use additive model changes by default (new optional fields, sensible defaults).
- Do not rename/remove persisted fields without explicit migration planning.
- Test opening existing user data from the previous release on the new build.
- Verify no fallback to in-memory storage exists in production startup paths.

## 2. Pre-release backup safety
- Ensure backup export works on the release candidate build.
- Create and validate a restore using a backup from the previous app version.
- Verify restored values for invoices, income, fixed costs, loans, special repayments, and OCR learning profiles.

## 3. Upgrade validation matrix
- Test update path: `N-1 -> N` (latest public to candidate).
- Test update path: `N-2 -> N` when possible.
- Validate at least:
  - App launch after update
  - Invoice list and details
  - Stats/analytics values
  - Export creation
  - Settings persistence
  - OCR review confidence + learned category/payment-recipient suggestions still work

## 4. Release gates
- No unresolved data-loss risks.
- No startup datastore initialization failure in release validation.
- Rollout starts in TestFlight/beta before full rollout.

## 5. Incident playbook
- If datastore initialization fails in production:
  - Do **not** ship hotfix with in-memory fallback.
  - Keep data protection behavior (block startup to avoid accidental empty state).
  - Ship targeted fix for schema/store issue.
