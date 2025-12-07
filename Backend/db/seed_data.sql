-- Seed sample data for testing
-- Run this after creating the database: psql -U postgres -d climblink -f seed_data.sql

-- Sample profiles with realistic data
INSERT INTO profiles (
    name, age, gender, bio, skill_level, location, latitude, longitude,
    profile_image_name, availability, favorite_crag,
    min_age_preference, max_age_preference, gender_preference, max_distance_km,
    wants_trad, wants_sport, wants_bouldering, wants_indoor, wants_outdoor,
    does_trad, does_sport, does_bouldering, does_indoor, does_outdoor
) VALUES
(
    'Alex', 28, 'man',
    'Love outdoor bouldering and sport climbing. Always up for a weekend adventure!',
    'Advanced', 'Boulder, CO', 40.014986, -105.270546,
    'person.circle.fill', 'Weekends', 'Eldorado Canyon',
    24, 40, 'all genders', 50,
    false, true, true, false, true,
    false, true, true, false, true
),
(
    'Jordan', 32, 'non-binary',
    'Indoor climber looking to transition to outdoor. Patient and supportive partner!',
    'Intermediate', 'Denver, CO', 39.7392, -104.9903,
    'person.circle.fill', 'Evenings & Weekends', NULL,
    25, 38, 'all genders', 40,
    false, true, false, true, true,
    false, true, false, true, false
),
(
    'Sam', 25, 'woman',
    'Trad climber with 5 years experience. Safety first, fun always!',
    'Expert', 'Golden, CO', 39.7555, -105.2211,
    'person.circle.fill', 'Flexible', 'The Garden of the Gods',
    22, 36, 'all genders', 60,
    true, true, false, false, true,
    true, true, false, false, true
),
(
    'Casey', 29, 'man',
    'Bouldering enthusiast! Love challenging problems and good vibes.',
    'Intermediate', 'Fort Collins, CO', 40.5853, -105.0844,
    'person.circle.fill', 'Weekends', 'Horsetooth Reservoir',
    24, 35, 'all genders', 45,
    false, false, true, true, true,
    false, false, true, true, true
),
(
    'Morgan', 35, 'woman',
    'Multi-pitch enthusiast. Looking for reliable partners for big wall adventures.',
    'Expert', 'Estes Park, CO', 40.3772, -105.5217,
    'person.circle.fill', 'Weekends', 'Lumpy Ridge',
    28, 45, 'all genders', 80,
    true, true, false, false, true,
    true, true, false, false, true
),
(
    'Riley', 26, 'non-binary',
    'New to climbing but super enthusiastic! Looking for patient mentors.',
    'Beginner', 'Boulder, CO', 40.014986, -105.270546,
    'person.circle.fill', 'Weekends', NULL,
    22, 32, 'all genders', 30,
    false, true, true, true, false,
    false, true, true, true, false
),
(
    'Taylor', 31, 'man',
    'Sport climbing is my jam. Always down for a day at the crag.',
    'Advanced', 'Denver, CO', 39.7392, -104.9903,
    'person.circle.fill', 'Weekends', 'Clear Creek Canyon',
    26, 40, 'all genders', 50,
    false, true, false, false, true,
    false, true, false, false, true
),
(
    'Quinn', 27, 'woman',
    'Bouldering and indoor training. Looking to push my limits!',
    'Intermediate', 'Boulder, CO', 40.014986, -105.270546,
    'person.circle.fill', 'Evenings & Weekends', NULL,
    23, 33, 'women', 35,
    false, false, true, true, true,
    false, false, true, true, false
);

