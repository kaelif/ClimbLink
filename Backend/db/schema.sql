-- ClimbLink PostgreSQL schema
-- Table: profiles

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS profiles (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name                TEXT NOT NULL,
    min_age_preference  INTEGER CHECK (min_age_preference >= 0),
    max_age_preference  INTEGER CHECK (max_age_preference >= min_age_preference),
    gender_preference   TEXT NOT NULL CHECK (gender_preference IN ('men', 'women', 'all genders')),
    max_distance_km     INTEGER CHECK (max_distance_km >= 0),
    latest_location     JSONB, -- e.g. {"lat": 40.014986, "lng": -105.270546}
    wants_trad          BOOLEAN NOT NULL DEFAULT FALSE,
    wants_sport         BOOLEAN NOT NULL DEFAULT FALSE,
    wants_bouldering    BOOLEAN NOT NULL DEFAULT FALSE,
    wants_indoor        BOOLEAN NOT NULL DEFAULT FALSE,
    wants_outdoor       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Keep age bounds sane (optional guardrails)
ALTER TABLE profiles
    ADD CONSTRAINT profiles_age_range CHECK (max_age_preference <= 100);

-- Update updated_at automatically
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_profiles_updated_at ON profiles;
CREATE TRIGGER trg_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION set_updated_at();



