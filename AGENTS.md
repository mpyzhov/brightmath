# AGENTS.md

This file describes how AI coding agents should work in this repository.

## Technologies (expected stack)

- **Platform**: Mobile-first
- **UI**: Flutter
- **Persistence**: On-device SQLite
- **State management**: Riverpod
- **Localization**: Use a Flutter localization library (`flutter_localizations` with `intl`).
- **Orientation**: Portrait-only in the current phase.
- **Dependencies**: Add only when needed; prefer well-maintained, popular packages

## Out of scope (current phase)

- Do not add analytics or telemetry in the current phase.
- Do not add daily streak mechanics; progression remains chapter-based in the current phase.
- Do not add ad-free premium mode in the current phase; monetization remains ads-based.
- Do not add percentage word-problem chapters in the current phase (possible future extension).

## Network policy

- Internet access may be used for ads-related functionality; strict offline-only behavior is not required in the current phase.
- Show ads as a banner above the question area during quiz flow.
- Banner ads must not hide, overlap, or distract from question text or answer options.
- If the run contains at least one incorrect answer, show a `Show correct results` button on the run summary.
- `Show correct results` is gated behind a rewarded full-screen ad.
- After rewarded ad completion, show a per-question results list with user answers marked green/red by correctness and include the correct answer for each incorrect response.
- `Show correct results` is available only immediately after that run's summary and is not re-openable later from history.
- If the rewarded ad is skipped, closed, or fails to complete, `Show correct results` remains locked.
- If rewarded ad inventory is unavailable (for example, no fill/offline), keep `Show correct results` locked and show a clear retry/later message.
- Rewarded access to `Show correct results` is run-scoped only; do not persist ad-review unlock flags beyond that summary context.

## Operating principles

- Prefer small, focused changes with tight feedback loops.
- Follow existing patterns, naming, and project structure.
- Don’t introduce new dependencies unless necessary.
- Keep changes secure: never commit secrets, tokens, or credentials.
- Store no personal user data.
- If requirements are ambiguous, make the most reasonable assumption, document it in the summary, and proceed.
- Keep copy friendly and consistent (tone, terminology, math notation).

## Repository discovery (do first)

- Identify entry points and conventions (look for `pubspec.yaml`, `lib/main.dart`, `analysis_options.yaml`).
- Locate the data layer (SQLite access, repositories/DAOs) and confirm Riverpod usage patterns.
- Confirm codegen usage (e.g., `build_runner`) and do not hand-edit generated files.

## App structure

- Use a feature-first structure under `lib/features/`.
- For each feature, prefer `data`, `domain`, and `presentation` folders.
- Keep shared utilities in `lib/core/` and avoid placing feature-specific logic there.
- Place Riverpod providers close to the feature they serve.
- Follow existing naming and file organization when extending an existing feature.

### Useful commands

```bash
flutter pub get
dart format .
dart analyze
flutter test
```

If codegen is used, run the project’s documented generator command (commonly `dart run build_runner build --delete-conflicting-outputs`).

## Making changes

- Keep diffs minimal; avoid drive-by refactors.
- Update or add tests when behavior changes (unit tests for logic; widget tests for critical UI flows).
- For progression, scoring, unlocking, and persistence logic, tests are required.
- Implement random quiz selection so tests can run deterministically (injectable seed or RNG), while production keeps non-deterministic randomness.
- Prefer explicit error handling and actionable error messages.
- When adding screens/flows, ensure navigation and back behavior feels native.
- For chapter/question content, use SQLite seed data as the source of truth.
- Use forward-only SQLite migrations.
- Name migrations with a sortable numeric prefix and short description (example: `001_initial_schema.sql`).
- Do not modify old migration files after they are committed; add a new migration instead.
- Do not ship debug logging in production code.

## Validation checklist (before handing back)

- Run the most relevant formatter/linter/test commands for the touched areas.
- Run tests after every code change before handing back.
- Ensure no debug logging or temporary code remains.
- Confirm new files are correctly placed and referenced.
- Verify the app still runs (at least one: simulator/emulator, or `flutter test` if runtime isn’t available).

## Documentation expectations

- Update README/docs when behavior, setup, or commands change.
- Add short, intent-focused comments only when the code can’t explain the “why”.
- Keep UI architecture and widget composition ready for future accessibility enhancements, but accessibility conformance is not a required milestone for the current scope.
- Keep user-facing strings localization-ready (no hardcoded UI copy in widgets).

## When you need input

Ask for clarification only if you cannot proceed safely. Otherwise, proceed with:

- A brief statement of assumptions
- The change made
- How to validate it locally
- When the user provides new requirements/updates, explicitly ask whether to add those updates to `AGENTS.md`.

## Product requirements (business logic)

This is a math-learning app named `BrightMath`, designed to help users practice in a relaxed way.

### UI and UX

- **Design direction**: UI should look modern and polished.
- **Design system scope**: Keep design guidance high-level for now; do not enforce a strict tokenized design system yet.
- **Theme policy**: Leave theme behavior unspecified for the current phase.
- **Icons**: Use icons where they improve clarity and navigation.
- **Math rendering**: Use clear math-friendly rendering for expressions where appropriate (for example, readable fractions and powers/superscripts).
- **Safe area compliance**: All screens must respect device safe areas (notches, status bar, and home indicator areas).
- **Tap target size**: Interactive controls should use a minimum tap target of at least 44x44 dp.
- **Color contrast**: UI text and interactive elements must meet required accessibility-oriented color contrast expectations.
- **Dynamic text scaling**: UI should support system text scaling without layout breakage.
- **Color palette**: Follow the mockup palette with deep navy/blue for headings and secondary actions, bright teal for primary actions and highlights, warm gold/yellow for stars and reward accents, white card surfaces, and a soft light gray app background.
- **Color usage**: Use teal as the main call-to-action color, navy for navigation/supporting actions, gold for achievement/reward states, green for correct-answer feedback, and red for incorrect-answer feedback.
- **Typography**: Use a clean rounded sans-serif style that feels friendly and modern. Prefer strong bold headings, medium-weight section labels, and highly legible body text with clear visual hierarchy.
- **Font tone**: Titles and key scores should feel playful but premium, while supporting labels should remain simple and readable.
- **Button style**: Primary buttons should be filled, rounded, and prominent with white text, soft shadows, and generous horizontal padding.
- **Secondary button style**: Secondary actions should use either outlined or lower-emphasis filled styles with the same rounded shape language.
- **Button shape**: Prefer pill-shaped or large-radius rounded rectangles for major interactive controls.
- **Button hierarchy**: Follow a clear action hierarchy like the reference screen: one dominant primary CTA (full-width), supporting secondary actions below it, and tertiary/destructive actions with lower visual weight.
- **Button polish**: Use high-contrast labels, consistent icon alignment, and balanced internal spacing so controls look premium and easy to scan.
- **Surface style**: Use white cards/panels with large rounded corners, soft shadows, and clean spacing to separate content sections.
- **Window/card style**: Result panels, settings groups, and content blocks should appear as elevated cards rather than flat full-bleed sections.
- **Card-first layout**: Build main screens with card-based sections (summary cards, action cards, settings cards) rather than plain text blocks.
- **Reference styling**: Match the shared mockup style for results/summary screens: centered score card, star reward section, and neatly grouped action buttons in rounded containers.
- **Layout tone**: Keep layouts airy, centered, and uncluttered, with clear grouping and enough spacing for touch-friendly interaction.
- **Motion and transitions**: Use subtle UI animations where they improve perceived quality (for example, smooth screen/card transitions, question changes, and gentle button/selection feedback).
- **Icon style**: Use simple, polished icons with rounded geometry and consistent stroke/weight.
- **Icon colors**: Use navy/teal as default icon colors, with gold reserved for stars, rewards, and celebratory accents.
- **Illustration style**: Any decorative math visuals should stay minimal, rounded, and friendly, matching the premium educational look of the mockup.

### Localization

- **Localization languages**: Support English, Ukrainian, Spanish, Portuguese, Korean, Italian, French, and German.
- **Localization scope**: Localize both UI labels and chapter/topic names shown in the chapter trail.
- **Question text policy**: Keep question content wording-free where possible (math expressions/operators only); if wording is present, it must be localized.
- **Percentage content policy**: Keep percentage chapters expression-based only in the current phase.

### App flow and settings

- **Entry flow**: After loading, show a start page with a button to start the game; after tapping it, user selects a chapter.
- **First-launch flow**: Keep first-launch flow minimal; do not require a separate onboarding/tutorial screen.
- **Settings access**: Main screen must provide access to a Settings menu.
- **Start page stats**: Show a compact stats preview on the start page (for example: completed chapters and total stars).
- **Session persistence policy**: Save app navigation state when app is minimized/backgrounded and restore it on next app start.
- **Quiz resume policy**: Restore in-progress quiz state (current question, selected answers, and countdown/lock state) after app restart/background return.
- **Unfinished run handling**: If a run is exited before completion, unanswered questions do not count and no partial progress is applied.
- **In-run back navigation**: Users must be able to go back from an active chapter/quiz screen to the chapter trail.
- **Trail back navigation**: Users must be able to go back from chapter trail selection to the main/start screen.
- **Language selector**: Settings must include an in-app language selector for supported locales.
- **Language switch behavior**: Selected language must apply immediately in the current session without app restart.
- **Feedback settings**: Settings must include toggles to enable/disable sound effects and haptic feedback.
- **Feedback defaults**: On first install, sound effects and haptic feedback are enabled by default.

### Chapters and content scope

- **Chapters**: Provide at least 20 chapters, covering:
  - Addition (whole numbers)
  - Subtraction (whole numbers)
  - Multiplication (whole numbers)
  - Division
  - Comparison chapters (whole numbers and fractions) using greater than (`>`), less than (`<`), and equals (`=`) operations
  - Addition (fractions)
  - Subtraction (fractions)
  - Multiplication (fractions)
  - Fraction conversion/comparison (improper ↔ mixed, compare/order)
  - Fraction simplification (separate chapter)
  - Comparison chapters for operation-based expressions (for example, comparing sums/products/divisions)
  - Percentage of number
  - \(x^y\) (power)
  - Square root
  - Operations with parenthesis
  - Order of operations with nested parentheses (separate chapter)
  - Comparison chapters for expressions with parentheses
  - Mixed-operation chapters that combine the above
- **Difficulty split per topic**: Split every chapter topic into three chapters: `Easy`, `Medium`, and `Hard`.
- **Difficulty ranges**:
  - Easy: small non-negative numbers and simple outcomes.
  - Medium: non-negative numbers up to 71.
  - Hard: values up to 500 with negatives allowed.
- **Easy subtraction constraint**: In Easy subtraction chapters, correct answers must be strictly positive (no `0` and no negative results).
- **Subtraction second argument constraint**: In subtraction chapters, the second argument (`a - b`) must be non-negative (`b >= 0`) across all difficulties.
- **Difficulty ordering**: For each topic, order chapters as Easy → Medium → Hard.
- **Difficulty naming**: Do not include difficulty in chapter title text; show difficulty only as a chip/badge in chapter UI.
- **Chapter descriptions**: Each chapter must include a brief description explaining the purpose and learning goal of its questions.
- **Description content**: Chapter descriptions should describe learning purpose only and must not include mode/difficulty metadata.
- **Difficulty**: Chapters ordered from easy → hard
- **Chapter ordering policy**: Exact chapter sequence/IDs can be chosen by the agent, as long as ordering remains easy → hard and all required topics are covered.
- **Question bank size**: Each chapter must have at least 500 questions in storage.
- **Question bank evolution**: New app versions may append/extend chapter question banks via migrations/seeds while preserving progress compatibility.
- **Question bank quality**: Avoid exact duplicates and near-duplicates within each chapter, and balance difficulty across easy, medium, and hard items.
- **Zero-zero exclusion**: Do not generate or keep degenerate `0` vs `0` style questions (or equivalent all-zero operand prompts) in the question bank.
- **Number domain**: Chapter question sets should include both non-negative and negative values where mathematically appropriate.
- **Division progression**: In division-focused content, easier difficulty should emphasize integer results, while harder difficulty may include fractional/decimal results.
- **Decimal precision**: When decimal values are used, limit them to a maximum of 1-2 decimal places.
- **Power/root scope**: In the current phase, keep power and square-root content on easier variants (for example, integer powers and perfect-square roots).
- **Fraction simplification rule**: In fraction simplification content, accepted answers must be in lowest terms.

### Quiz formats and interactions

- **Questions per run**: Each playthrough must show a random selection of 20 questions from the chapter bank.
- **Rerun selection**: Each rerun should use a newly randomized set of 20 questions from the chapter bank.
- **Run uniqueness**: A single playthrough must not contain duplicate questions.
- **Question volume**: Each chapter must contain more than 20 total questions (the minimum 500-question bank satisfies this).
- **Question types**: Multiple quiz formats are required.
- **Mandatory quiz modes**: Include both (1) classic 4-choice selection and (2) sign-comparison mode where users choose the correct relation (`>`, `<`, `=`) between two expressions (example: `2+2 ? 1+3`).
- **Option layout**: Show answer options in a 2-row x 2-column grid layout.
- **Option button shape**: Use more squared option buttons (smaller corner radius than primary CTA buttons).
- **Mixed chapter composition**: Mixed-operation chapters should use a progressive mix from topics already introduced/unlocked earlier in the chapter trail.
- **Comparison content**: Split comparison content across multiple chapters, including (1) whole numbers/fractions, (2) operation-based expressions, and (3) expressions with parentheses.
- **Comparison input method**: In sign-comparison mode, users answer by tapping one of three buttons (`>`, `<`, `=`), not by text input.
- **Answer reveal policy**: Do not display correct answers to users during the run or in post-run summary.
- **Question pacing**: Use a `Next` button flow after each answer, with a 3-second countdown.
- **Timer UI**: Show the remaining countdown inside the `Next` button.
- **Next visibility**: Do not show the `Next` button before the user selects an answer.
- **Question progress UI**: Replace the top question progress bar with per-question dots: gray for unanswered future questions, blue for current question, green for correctly answered questions, red for incorrectly answered questions.
- **Question index label UI**: Do not show a `Question X/20` text label in the quiz screen.
- **Question dots sizing**: Keep top progress dots visually compact/small.
- **Next button behavior**: Enable `Next` immediately after answer selection.
- **Countdown circle label**: Show the time-left number centered inside the circular countdown indicator.
- **Countdown animation quality**: Use a smooth animated circular progress countdown (not coarse 1-second step transitions).
- **Auto-advance behavior**: Automatically trigger `Next` when the countdown ends.
- **Answer lock**: Once a user selects an answer, that question is completed and all answer options become locked.
- **Correctness feedback**: After answer selection, provide immediate visual feedback by changing the selected answer button color to green when correct and red when incorrect.
- **Feedback duration**: Correct/incorrect button coloring is temporary during the post-answer delay and resets on the next question; do not persist per-question correctness markers in summary/history UI.
- **Audio and haptics feedback**: Provide both sound and haptic feedback for answer interactions, controlled by Settings toggles.
- **Quiz ad size**: Top quiz ad banner area should use a 320x100 layout.

### Progression and persistence

- **Star rating**: Award stars based on correct answers out of 20 questions: 3 stars for 20, 2 stars for 18-19, and 1 star for 15-17.
- **Completion rule**: A chapter is completed only when the user earns at least 1 star (15+ correct answers).
- **Threshold consistency**: Star and completion thresholds are the same for all chapters in the current phase.
- **Progression**: Chapter selection resembles a trail. Easy unlocks Medium; Medium unlocks Hard. Next topic Easy unlocks only after Hard completion or explicit skip action.
- **Hard skip control**: Do not auto-skip Hard chapters. If a Hard chapter ends with zero stars, show a dedicated `Skip Hard Chapter` action on results so user can proceed.
- **Skipped chapter state**: Persist a dedicated skipped state for skipped hard chapters; skipped is distinct from completed.
- **Chapter states UI**: Completed chapters must have a clearly different appearance from current and locked chapters.
- **Skipped chapter UI**: Skipped chapters must use a different icon from normal playable/completed chapters.
- **Skipped chapter card style**: Skipped chapters should use muted card/surface colors to clearly differentiate them from active and completed chapters.
- **Trail chapter indicators**: Show best-earned stars on completed chapter nodes (1-3 stars), and show a lock icon on locked chapter nodes.
- **Skipped state transition**: If a skipped chapter is later completed with at least 1 star, clear skipped state and show normal completed styling/stars.
- **Trail layout**: Chapter selection/trail may use vertical scrolling.
- **Scrolling policy**: Screens other than chapter selection should be designed without scrolling.
- **Replay support**: Any unlocked chapter can be replayed any number of times.
- **Progress tracking**: Track per-chapter completion, current progress state, stars earned, and best score per chapter in SQLite.
- **Unlock persistence**: Persist chapter lock/unlock state directly in SQLite.
- **Attempt history**: Store per-attempt history in SQLite (including timestamp and result), but do not display attempt history in the UI.
- **Settings persistence**: Persist user settings (language, sound, haptics) in platform preferences storage rather than SQLite.
- **Best-ever policy**: Replays can improve stored stars/best score, but must not downgrade previously achieved best results or completed status.
- **Reset progress**: Settings must include a reset progress action, designed to avoid accidental taps (for example, a clearly separated/destructive-styled control).
- **Reset confirmation**: Before resetting, show a confirmation prompt that explicitly states all progress will be lost.
- **Reset scope**: Reset clears only user progress data (completion state, stars, best scores, and attempt history) and must not modify the chapter/question bank.
- **Reset exclusions**: `Reset progress` must not change user preferences (language, sound, haptics).
- **Run summary**: At end of run, show `correct answers / total questions` and display earned stars with animation.
- **Run summary navigation**: After finishing a chapter, the results screen must allow navigation to `Chapter Trail` and `Home`.
- **Next chapter action**: The results screen must include a `Next Chapter` action when the user earned at least 1 star in the finished chapter.
- **Run summary actions**: Include direct actions on the run summary screen for `Rerun chapter`, `Chapter Trail`, and `Home`.

## Handoff format (what to report back)

When you finish a task, include:

- **Summary**: What changed and why (1–3 bullets)
- **Assumptions**: Any assumptions you made
- **Validation**: Commands run and results (or what to run)
- **Notes**: Any follow-ups, risks, or edge cases
