-- Create ClimbLink database
-- Run this first: psql -U postgres -f create_database.sql

CREATE DATABASE climblink;

-- Connect to the database
\c climblink

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table
-- This table stores both user profiles and their preferences for matching
CREATE TABLE profiles (
    -- Primary Identifier
    id SERIAL PRIMARY KEY,

    -- Basic Profile Information
    name VARCHAR(255) NOT NULL,
    age INTEGER NOT NULL,
    gender VARCHAR(50) NOT NULL,
    bio TEXT,
    skill_level VARCHAR(50) NOT NULL,
    
    -- Location and Coordinates
    location VARCHAR(255),
    latitude NUMERIC(10, 8),
    longitude NUMERIC(11, 8),
    
    -- Display and Availability
    profile_image_name VARCHAR(255),
    availability VARCHAR(255),
    favorite_crag VARCHAR(255), -- NULLable column, as seen in sample data
    
    -- Partner Preferences
    min_age_preference INTEGER,
    max_age_preference INTEGER,
    gender_preference VARCHAR(50),
    max_distance_km INTEGER,
    
    -- Wants (Looking for partners who do these styles)
    wants_trad BOOLEAN NOT NULL DEFAULT FALSE,
    wants_sport BOOLEAN NOT NULL DEFAULT FALSE,
    wants_bouldering BOOLEAN NOT NULL DEFAULT FALSE,
    wants_indoor BOOLEAN NOT NULL DEFAULT FALSE,
    wants_outdoor BOOLEAN NOT NULL DEFAULT FALSE,

    -- Does (User's actual climbing styles)
    does_trad BOOLEAN NOT NULL DEFAULT FALSE,
    does_sport BOOLEAN NOT NULL DEFAULT FALSE,
    does_bouldering BOOLEAN NOT NULL DEFAULT FALSE,
    does_indoor BOOLEAN NOT NULL DEFAULT FALSE,
    does_outdoor BOOLEAN NOT NULL DEFAULT FALSE,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
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


