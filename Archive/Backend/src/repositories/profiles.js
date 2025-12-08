// Try to use Supabase JS client, fall back to PostgreSQL pool if not available
const supabase = require('../db/supabase');
const pool = require('../db/pool');

// Use Supabase JS client if available, otherwise use PostgreSQL pool
const useSupabaseClient = supabase !== null;

/**
 * Calculate distance between two coordinates using Haversine formula
 * @param {number} lat1 - Latitude of first point
 * @param {number} lon1 - Longitude of first point
 * @param {number} lat2 - Latitude of second point
 * @param {number} lon2 - Longitude of second point
 * @returns {number} Distance in kilometers
 */
function calculateDistanceKm(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRadians(lat2 - lat1);
  const dLon = toRadians(lon2 - lon1);
  
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRadians(lat1)) * Math.cos(toRadians(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRadians(degrees) {
  return degrees * (Math.PI / 180);
}

/**
 * Get a stack of profiles that match the user's criteria
 * @param {Object} userProfile - The current user's profile with preferences
 * @param {string} userProfile.userId - Optional: ID of the current user to exclude from results
 * @param {number} userProfile.age - User's age
 * @param {string} userProfile.gender - User's gender ('man', 'woman', 'non-binary', 'prefer not to say')
 * @param {number} userProfile.latitude - User's latitude
 * @param {number} userProfile.longitude - User's longitude
 * @param {number} userProfile.maxDistanceKm - User's max distance preference
 * @param {number} userProfile.minAgePreference - User's min age preference
 * @param {number} userProfile.maxAgePreference - User's max age preference
 * @param {string} userProfile.genderPreference - User's gender preference ('men', 'women', 'all genders')
 * @param {boolean} userProfile.wantsTrad - User wants trad climbing partners
 * @param {boolean} userProfile.wantsSport - User wants sport climbing partners
 * @param {boolean} userProfile.wantsBouldering - User wants bouldering partners
 * @param {boolean} userProfile.wantsIndoor - User wants indoor climbing partners
 * @param {boolean} userProfile.wantsOutdoor - User wants outdoor climbing partners
 * @returns {Promise<Array>} Array of matching profiles
 */
async function getStack(userProfile = {}) {
  // Default values for demo/testing (if no user profile provided)
  const {
    userId = null,
    age = 28,
    gender = 'man',
    latitude = 40.014986, // Default to Boulder, CO
    longitude = -105.270546,
    maxDistanceKm = 50,
    minAgePreference = 24,
    maxAgePreference = 40,
    genderPreference = 'all genders',
    wantsTrad = false,
    wantsSport = true,
    wantsBouldering = true,
    wantsIndoor = false,
    wantsOutdoor = true,
  } = userProfile;

  // Track which climbing types user wants (for filtering)
  const userWantsTypes = [];
  if (wantsTrad) userWantsTypes.push('trad');
  if (wantsSport) userWantsTypes.push('sport');
  if (wantsBouldering) userWantsTypes.push('bouldering');
  if (wantsIndoor) userWantsTypes.push('indoor');
  if (wantsOutdoor) userWantsTypes.push('outdoor');

  try {
    if (!useSupabaseClient) {
      throw new Error('Supabase JS client not available. Please add SUPABASE_URL and ANON_KEY to .env file, or use PostgreSQL pool connection.');
    }

    // Build Supabase query
    let query = supabase
      .from('profiles')
      .select('*')
      .gte('age', minAgePreference)
      .lte('age', maxAgePreference)
      .gte('min_age_preference', age)
      .lte('max_age_preference', age)
      .not('latitude', 'is', null)
      .not('longitude', 'is', null);

    // Exclude current user if provided
    if (userId) {
      query = query.neq('id', userId);
    }

    // Gender preference filter
    if (genderPreference === 'men') {
      query = query.eq('gender', 'man');
    } else if (genderPreference === 'women') {
      query = query.eq('gender', 'woman');
    }


    // Execute query
    const { data, error } = await query.order('created_at', { ascending: false }).limit(100);

    if (error) {
      console.error('Supabase query error:', error);
      throw error;
    }

    if (!data) {
      return [];
    }

    // Filter and calculate distances in JavaScript
    const filtered = data
      .filter(profile => {
        // Gender preference matching
        if (profile.gender_preference === 'all genders') {
          // Always matches
        } else if (profile.gender_preference === 'men' && gender !== 'man') {
          return false;
        } else if (profile.gender_preference === 'women' && gender !== 'woman') {
          return false;
        }

        // Climbing type matching - partner must DO at least one type user wants
        if (userWantsTypes.length > 0) {
          const partnerDoesTypes = [];
          if (profile.does_trad) partnerDoesTypes.push('trad');
          if (profile.does_sport) partnerDoesTypes.push('sport');
          if (profile.does_bouldering) partnerDoesTypes.push('bouldering');
          if (profile.does_indoor) partnerDoesTypes.push('indoor');
          if (profile.does_outdoor) partnerDoesTypes.push('outdoor');

          const hasMatchingType = userWantsTypes.some(type => partnerDoesTypes.includes(type));
          if (!hasMatchingType) return false;
        }

        // Partner preference matching - partner must WANT at least one type user does
        const partnerWantsTypes = [];
        if (profile.wants_trad) partnerWantsTypes.push('trad');
        if (profile.wants_sport) partnerWantsTypes.push('sport');
        if (profile.wants_bouldering) partnerWantsTypes.push('bouldering');
        if (profile.wants_indoor) partnerWantsTypes.push('indoor');
        if (profile.wants_outdoor) partnerWantsTypes.push('outdoor');

        const hasMatchingPreference = userWantsTypes.some(type => partnerWantsTypes.includes(type));
        if (userWantsTypes.length > 0 && !hasMatchingPreference) return false;

        // Distance filtering
        const distance = calculateDistanceKm(
          latitude,
          longitude,
          profile.latitude,
          profile.longitude
        );

        // User's max distance
        if (distance > maxDistanceKm) return false;

        // Partner's max distance
        if (profile.max_distance_km && distance > profile.max_distance_km) return false;

        // Store distance for sorting
        profile.distance_km = distance;
        return true;
      })
      .sort((a, b) => {
        // Sort by distance first, then by created_at
        if (a.distance_km !== b.distance_km) {
          return a.distance_km - b.distance_km;
        }
        return new Date(b.created_at) - new Date(a.created_at);
      })
      .slice(0, 50); // Limit to 50 results

    // Transform the data to match the frontend format
    return filtered.map(profile => ({
      id: profile.id,
      name: profile.name,
      age: profile.age,
      bio: profile.bio || '',
      skillLevel: profile.skill_level || 'Intermediate',
      preferredTypes: buildPreferredTypes(profile),
      location: profile.location || 'Unknown',
      profileImageName: profile.profile_image_name || 'person.circle.fill',
      availability: profile.availability || 'Flexible',
      favoriteCrag: profile.favorite_crag || null,
    }));
  } catch (error) {
    console.error('Error fetching stack:', error);
    throw error;
  }
}

/**
 * Build preferredTypes array from database boolean columns
 */
function buildPreferredTypes(profile) {
  const types = [];
  if (profile.does_trad) types.push('Traditional');
  if (profile.does_sport) types.push('Sport Climbing');
  if (profile.does_bouldering) types.push('Bouldering');
  if (profile.does_indoor) types.push('Indoor');
  if (profile.does_outdoor) types.push('Outdoor');
  return types;
}

module.exports = {
  getStack,
};

