# BrightMath

BrightMath is a mobile-first Flutter app for relaxed math practice.

## Database Content

SQLite schema and seed content are shipped as SQL assets under
`assets/database/`.

- `assets/database/manifest.json` defines the database version and exact script
  execution order.
- `assets/database/migrations/` contains schema and forward migration scripts.
- `assets/database/init/chapters.sql` seeds chapter metadata.
- `assets/database/init/questions/` contains one generated SQL seed file per
  chapter.

Questions are generated at development time, then committed as SQL so all
devices initialize from the same content.

```bash
dart run tool/generate_database_sql.dart
dart run tool/validate_database_sql.dart
dart format .
dart analyze
flutter test
```
