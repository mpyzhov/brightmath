# BrightMath Phase 2+ Backlog

## Ads and Monetization
- Integrate banner ads in quiz screen with production ad SDK.
- Integrate rewarded full-screen ad for `Show Correct Results`.
- Keep review screen locked when rewarded ad is skipped or unavailable.
- Add retry-later messaging for no-fill/offline rewarded requests.

## Post-Run Correct Results Review
- Add review screen available only immediately after run summary.
- Show per-question rows with user answer (green/red) and correct answer for misses.
- Keep access run-scoped only and do not persist unlock flags.

## Localization Rollout
- Add complete translated strings for: `uk`, `es`, `pt`, `ko`, `it`, `fr`, `de`.
- Localize chapter titles and descriptions from database seeds.
- Add locale-aware numeric formatting where needed.

## Quality and Product
- Add integration tests for end-to-end rewarded review flow.
- Add telemetry policy decision if analytics scope changes.
- Revisit accessibility conformance milestone and automated checks.
