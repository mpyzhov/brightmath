-- Initial schema for BrightMath.
-- This script is the source of truth for first-time database setup.

CREATE TABLE IF NOT EXISTS chapters (
  id INTEGER PRIMARY KEY,
  order_index INTEGER NOT NULL,
  topic_code TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  kind TEXT NOT NULL,
  quiz_mode TEXT NOT NULL
)

;

CREATE TABLE IF NOT EXISTS questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chapter_id INTEGER NOT NULL,
  prompt TEXT NOT NULL,
  right_expr TEXT,
  correct_answer TEXT NOT NULL,
  options TEXT NOT NULL
)

;

CREATE TABLE IF NOT EXISTS progress (
  chapter_id INTEGER PRIMARY KEY,
  is_unlocked INTEGER NOT NULL,
  is_completed INTEGER NOT NULL,
  is_skipped INTEGER NOT NULL DEFAULT 0,
  best_score INTEGER NOT NULL,
  best_stars INTEGER NOT NULL
)

;

CREATE TABLE IF NOT EXISTS attempts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chapter_id INTEGER NOT NULL,
  correct_count INTEGER NOT NULL,
  total_count INTEGER NOT NULL,
  stars INTEGER NOT NULL,
  created_at TEXT NOT NULL
)

;

CREATE TABLE IF NOT EXISTS attempt_answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  attempt_id INTEGER NOT NULL,
  question_id INTEGER NOT NULL,
  prompt TEXT NOT NULL,
  user_answer TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  is_correct INTEGER NOT NULL
)
;
