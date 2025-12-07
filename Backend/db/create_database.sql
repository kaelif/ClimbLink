-- Create ClimbLink database
-- Run this first: psql -U postgres -f create_database.sql

CREATE DATABASE climblink;

-- Connect to the database
\c climblink

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table
-- This table stores both user profiles and their preferences for matching
CREATE TABLE IF NOT EXISTS profiles (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- User profile information
    name                TEXT NOT NULL,
    age                 INTEGER NOT NULL CHECK (age >= 18 AND age <= 100),
    gender              TEXT NOT NULL CHECK (gender IN ('man', 'woman', 'non-binary', 'prefer not to say')),
    bio                 TEXT,
    skill_level         TEXT CHECK (skill_level IN ('Beginner', 'Intermediate', 'Advanced', 'Expert')),
    location            TEXT, -- e.g., "Boulder, CO"
    latitude            DECIMAL(10, 8), -- For distance calculations
    longitude           DECIMAL(11, 8), -- For distance calculations
    profile_image_name  TEXT DEFAULT 'person.circle.fill',
    availability        TEXT,
    favorite_crag       TEXT,
    
    -- Matching preferences
    min_age_preference  INTEGER CHECK (min_age_preference >= 18),
    max_age_preference  INTEGER CHECK (max_age_preference >= min_age_preference AND max_age_preference <= 100),
    gender_preference   TEXT NOT NULL CHECK (gender_preference IN ('men', 'women', 'all genders')),
    max_distance_km     INTEGER CHECK (max_distance_km >= 0),
    
    -- Climbing type preferences (what they want in a partner)
    wants_trad          BOOLEAN NOT NULL DEFAULT FALSE,
    wants_sport         BOOLEAN NOT NULL DEFAULT FALSE,
    wants_bouldering    BOOLEAN NOT NULL DEFAULT FALSE,
    wants_indoor        BOOLEAN NOT NULL DEFAULT FALSE,
    wants_outdoor       BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- What they offer (climbing types they do)
    does_trad           BOOLEAN NOT NULL DEFAULT FALSE,
    does_sport          BOOLEAN NOT NULL DEFAULT FALSE,
    does_bouldering     BOOLEAN NOT NULL DEFAULT FALSE,
    does_indoor         BOOLEAN NOT NULL DEFAULT FALSE,
    does_outdoor        BOOLEAN NOT NULL DEFAULT FALSE,
    
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add index for location-based queries
CREATE INDEX IF NOT EXISTS idx_profiles_location ON profiles(latitude, longitude);

-- Add index for age range queries
CREATE INDEX IF NOT EXISTS idx_profiles_age ON profiles(age);

-- Function to calculate distance in kilometers using Haversine formula
CREATE OR REPLACE FUNCTION calculate_distance_km(
    lat1 DECIMAL, lon1 DECIMAL,
    lat2 DECIMAL, lon2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    earth_radius_km DECIMAL := 6371;
    dlat DECIMAL;
    dlon DECIMAL;
    a DECIMAL;
    c DECIMAL;
BEGIN
    dlat := radians(lat2 - lat1);
    dlon := radians(lon2 - lon1);
    
    a := sin(dlat/2) * sin(dlat/2) +
         cos(radians(lat1)) * cos(radians(lat2)) *
         sin(dlon/2) * sin(dlon/2);
    
    c := 2 * atan2(sqrt(a), sqrt(1-a));
    
    RETURN earth_radius_km * c;
END;
$$ LANGUAGE plpgsql;

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

