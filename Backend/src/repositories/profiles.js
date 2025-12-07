const pool = require('../db/pool');

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

  // Build the WHERE clause for gender preference matching
  let genderFilter = '';
  if (genderPreference === 'men') {
    genderFilter = "AND p.gender = 'man'";
  } else if (genderPreference === 'women') {
    genderFilter = "AND p.gender = 'woman'";
  }
  // 'all genders' means no filter

  // Build the WHERE clause for climbing type matching
  // User wants partners who DO these types (does_* columns)
  const climbingTypeConditions = [];
  if (wantsTrad) {
    climbingTypeConditions.push('p.does_trad = true');
  }
  if (wantsSport) {
    climbingTypeConditions.push('p.does_sport = true');
  }
  if (wantsBouldering) {
    climbingTypeConditions.push('p.does_bouldering = true');
  }
  if (wantsIndoor) {
    climbingTypeConditions.push('p.does_indoor = true');
  }
  if (wantsOutdoor) {
    climbingTypeConditions.push('p.does_outdoor = true');
  }

  // If user wants specific types, at least one must match
  const climbingTypeFilter = climbingTypeConditions.length > 0
    ? `AND (${climbingTypeConditions.join(' OR ')})`
    : '';

  // Build the WHERE clause for partner's preferences matching the user
  // Partner must want the user's climbing types (wants_* columns)
  const partnerPreferenceConditions = [];
  if (wantsTrad || wantsSport || wantsBouldering || wantsIndoor || wantsOutdoor) {
    // Check if partner wants any of the types the user does
    const userDoesTypes = [];
    if (wantsTrad) userDoesTypes.push('p.wants_trad = true');
    if (wantsSport) userDoesTypes.push('p.wants_sport = true');
    if (wantsBouldering) userDoesTypes.push('p.wants_bouldering = true');
    if (wantsIndoor) userDoesTypes.push('p.wants_indoor = true');
    if (wantsOutdoor) userDoesTypes.push('p.wants_outdoor = true');
    
    if (userDoesTypes.length > 0) {
      partnerPreferenceConditions.push(`(${userDoesTypes.join(' OR ')})`);
    }
  }

  const partnerPreferenceFilter = partnerPreferenceConditions.length > 0
    ? `AND ${partnerPreferenceConditions.join(' AND ')}`
    : '';

  const query = `
    SELECT 
      p.id,
      p.name,
      p.age,
      p.bio,
      p.skill_level as "skillLevel",
      p.location,
      p.latitude,
      p.longitude,
      p.profile_image_name as "profileImageName",
      p.availability,
      p.favorite_crag as "favoriteCrag",
      calculate_distance_km($1, $2, p.latitude, p.longitude) as distance_km
    FROM profiles p
    WHERE 
      -- Exclude the current user if userId is provided
      ${userId ? `p.id != $${userId ? '3' : '1'} AND` : ''}
      -- Age range match: partner's age must be within user's preference range
      p.age >= $${userId ? '4' : '3'} AND p.age <= $${userId ? '5' : '4'}
      -- Gender preference match
      ${genderFilter}
      -- Partner's preferences must match user's age
      AND p.min_age_preference <= $${userId ? '6' : '5'} 
      AND p.max_age_preference >= $${userId ? '6' : '5'}
      -- Partner's gender preference must include user's gender
      AND (
        p.gender_preference = 'all genders' OR
        (p.gender_preference = 'men' AND $${userId ? '7' : '6'} IN ('man')) OR
        (p.gender_preference = 'women' AND $${userId ? '7' : '6'} IN ('woman'))
      )
      -- Distance filter: within user's max distance
      AND calculate_distance_km($1, $2, p.latitude, p.longitude) <= $${userId ? '8' : '7'}
      -- Partner's max distance must include user
      AND (p.max_distance_km IS NULL OR p.max_distance_km >= calculate_distance_km($1, $2, p.latitude, p.longitude))
      -- Climbing type matching
      ${climbingTypeFilter}
      ${partnerPreferenceFilter}
      -- Both user and partner must have location data
      AND p.latitude IS NOT NULL 
      AND p.longitude IS NOT NULL
    ORDER BY distance_km ASC, p.created_at DESC
    LIMIT 50
  `;

  const params = userId
    ? [latitude, longitude, userId, minAgePreference, maxAgePreference, age, gender, maxDistanceKm]
    : [latitude, longitude, minAgePreference, maxAgePreference, age, gender, maxDistanceKm];

  try {
    const { rows } = await pool.query(query, params);
    
    // Transform the data to match the frontend format
    return rows.map(row => ({
      id: row.id,
      name: row.name,
      age: row.age,
      bio: row.bio || '',
      skillLevel: row.skillLevel || 'Intermediate',
      preferredTypes: buildPreferredTypes(row),
      location: row.location || 'Unknown',
      profileImageName: row.profileImageName || 'person.circle.fill',
      availability: row.availability || 'Flexible',
      favoriteCrag: row.favorite_crag || null,
    }));
  } catch (error) {
    console.error('Error fetching stack:', error);
    throw error;
  }
}

/**
 * Build preferredTypes array from database boolean columns
 */
function buildPreferredTypes(row) {
  const types = [];
  if (row.does_trad) types.push('Traditional');
  if (row.does_sport) types.push('Sport Climbing');
  if (row.does_bouldering) types.push('Bouldering');
  if (row.does_indoor) types.push('Indoor');
  if (row.does_outdoor) types.push('Outdoor');
  return types;
}

module.exports = {
  getStack,
};

