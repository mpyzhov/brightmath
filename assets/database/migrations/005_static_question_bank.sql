-- Upgrade support for the static SQL-backed question bank.
-- SQLite does not support ADD COLUMN IF NOT EXISTS, so nullable/default
-- columns are added defensively by DatabaseInitializer before this script.

CREATE INDEX IF NOT EXISTS questions_chapter_idx
  ON questions(chapter_id);

CREATE UNIQUE INDEX IF NOT EXISTS questions_chapter_key_idx
  ON questions(chapter_id, question_key);
