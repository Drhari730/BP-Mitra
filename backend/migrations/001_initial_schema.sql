-- ============================================================
-- BP Mitra – Initial PostgreSQL Schema
-- Migration: 001_initial_schema.sql
-- Run order: 1
-- ============================================================

-- Enable UUID generation extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ────────────────────────────────────────────────────────────
-- USERS TABLE
-- Core identity record; auth tokens stored separately in JWT.
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name       VARCHAR(120)    NOT NULL,
    email           VARCHAR(255)    UNIQUE NOT NULL,
    password_hash   VARCHAR(255)    NOT NULL,
    date_of_birth   DATE,
    gender          VARCHAR(10)     CHECK (gender IN ('male','female','other')),
    weight_kg       NUMERIC(5,2),
    height_cm       NUMERIC(5,2),
    -- Clinician-assigned hypertension stage (1/2/controlled)
    hypertension_stage VARCHAR(20)  DEFAULT 'stage1',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

-- ────────────────────────────────────────────────────────────
-- MODULE 1 – MEDICATION TRACKER
-- medication_schedules: one row per prescribed dose schedule.
-- adherence_logs:       one row per dose event (taken/skipped/missed).
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS medication_schedules (
    id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    med_name         VARCHAR(120)    NOT NULL,
    dosage_mg        NUMERIC(8,2)    NOT NULL,
    -- How often the drug should be taken; drives reminder scheduling.
    frequency_hours  INTEGER         NOT NULL CHECK (frequency_hours IN (4,6,8,12,24)),
    -- Wall-clock time of the FIRST daily dose (HH:MM in user's local tz).
    scheduled_time   TIME            NOT NULL,
    -- WHO ATC therapeutic class; used for escalation-priority logic.
    drug_class       VARCHAR(80)     DEFAULT 'antihypertensive',
    -- Marks a dose as 'critical' so Rule B escalation fires (45-min window).
    is_critical      BOOLEAN         NOT NULL DEFAULT TRUE,
    is_active        BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at       TIMESTAMPTZ     NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS adherence_logs (
    id                UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id       UUID        NOT NULL REFERENCES medication_schedules(id) ON DELETE CASCADE,
    user_id           UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- The wall-clock moment the dose was originally scheduled.
    scheduled_at      TIMESTAMPTZ NOT NULL,
    -- Actual moment the user interacted (NULL if system marks as Missed).
    logged_at         TIMESTAMPTZ,
    -- Canonical status enum; application layer also uses these string values.
    status            VARCHAR(10) NOT NULL CHECK (status IN ('Taken','Skipped','Missed')),
    -- Minutes late (positive) or early (negative) relative to scheduled_at.
    delta_minutes     INTEGER,
    -- Rule B escalation was sent for this log entry.
    escalation_sent   BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for high-frequency adherence queries
CREATE INDEX IF NOT EXISTS idx_adherence_user_date
    ON adherence_logs(user_id, scheduled_at DESC);
CREATE INDEX IF NOT EXISTS idx_adherence_schedule
    ON adherence_logs(schedule_id, scheduled_at DESC);

-- ────────────────────────────────────────────────────────────
-- MODULE 2 – DASH DIET FOOD LOGS
-- daily_food_logs:  one row per food item consumed per day.
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS daily_food_logs (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date        DATE        NOT NULL DEFAULT CURRENT_DATE,
    -- Meal slot; constrains UI display grouping.
    meal_slot       VARCHAR(15) NOT NULL CHECK (meal_slot IN ('breakfast','lunch','dinner','snack')),
    food_item_key   VARCHAR(80) NOT NULL,  -- FK to local asset JSON
    food_name       VARCHAR(120) NOT NULL,
    serving_size_g  NUMERIC(6,1) NOT NULL,
    -- Macronutrient snapshot captured at log time (from JSON asset)
    sodium_mg       NUMERIC(7,2) NOT NULL DEFAULT 0,
    potassium_mg    NUMERIC(7,2) NOT NULL DEFAULT 0,
    magnesium_mg    NUMERIC(7,2) NOT NULL DEFAULT 0,
    calories_kcal   NUMERIC(7,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_food_logs_user_date
    ON daily_food_logs(user_id, log_date DESC);

-- ────────────────────────────────────────────────────────────
-- MODULE 3 – VITALS & BP READINGS
-- bp_readings: stores both rPPG-derived and manual-cuff values.
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS bp_readings (
    id               UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id          UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    systolic_mmhg    INTEGER     NOT NULL CHECK (systolic_mmhg BETWEEN 50 AND 300),
    diastolic_mmhg   INTEGER     NOT NULL CHECK (diastolic_mmhg BETWEEN 30 AND 200),
    pulse_bpm        INTEGER     CHECK (pulse_bpm BETWEEN 30 AND 250),
    -- Source distinguishes rPPG camera reads from manual cuff inputs.
    source           VARCHAR(10) NOT NULL CHECK (source IN ('rppg','manual')),
    -- Confidence score output by the rPPG mock pipeline (0.0–1.0).
    rppg_confidence  NUMERIC(4,3),
    notes            TEXT,
    measured_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bp_readings_user_date
    ON bp_readings(user_id, measured_at DESC);

-- ────────────────────────────────────────────────────────────
-- MODULE 4 – ACTIVITY / STEP LOGS
-- activity_logs: daily aggregated step and calorie totals.
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS activity_logs (
    id              UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    log_date        DATE        NOT NULL DEFAULT CURRENT_DATE,
    total_steps     INTEGER     NOT NULL DEFAULT 0,
    active_kcal     NUMERIC(7,2) NOT NULL DEFAULT 0,
    -- Raw accelerometer epoch snapshots stored as JSONB array for offline replay.
    epoch_data      JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, log_date)
);

-- ────────────────────────────────────────────────────────────
-- MODULE 5 – AI ASSISTANT INTERACTION LOGS
-- ai_sessions: audit trail of rule-engine evaluations.
-- ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS ai_sessions (
    id                  UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    input_payload       JSONB       NOT NULL,  -- snapshot of user stats at evaluation
    triggered_profile   VARCHAR(5),            -- 'A', 'B', 'C', or NULL (no rule match)
    response_text       TEXT        NOT NULL,
    evaluated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ────────────────────────────────────────────────────────────
-- Automated updated_at trigger (shared across tables that need it)
-- ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
