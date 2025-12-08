// ============================================
// DATABASE MODE (commented out - uncomment to use database)
// ============================================
// const pool = require('../db/pool');

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

  // Build query conditions and parameters
  const conditions = [];
  const params = [latitude, longitude];
  let paramIndex = 3;

  // Exclude current user if provided
  if (userId) {
    conditions.push(`p.id != $${paramIndex}`);
    params.push(userId);
    paramIndex++;
  }

  // Age range match: partner's age must be within user's preference range
  conditions.push(`p.age >= $${paramIndex}`);
  params.push(minAgePreference);
  paramIndex++;
  
  conditions.push(`p.age <= $${paramIndex}`);
  params.push(maxAgePreference);
  paramIndex++;

  // Gender preference match (user's preference for partner's gender)
  if (genderPreference === 'men') {
    conditions.push(`p.gender = 'man'`);
  } else if (genderPreference === 'women') {
    conditions.push(`p.gender = 'woman'`);
  }
  // 'all genders' means no filter

  // Partner's preferences must match user's age
  conditions.push(`p.min_age_preference <= $${paramIndex}`);
  params.push(age);
  paramIndex++;
  
  conditions.push(`p.max_age_preference >= $${paramIndex}`);
  params.push(age);
  paramIndex++;

  // Partner's gender preference must include user's gender
  const genderMap = {
    'man': 'men',
    'woman': 'women',
    'non-binary': 'all genders',
    'prefer not to say': 'all genders'
  };
  const userGenderPreference = genderMap[gender] || 'all genders';
  
  if (userGenderPreference === 'all genders') {
    // Partner accepts all genders, no filter needed
  } else {
    conditions.push(`(p.gender_preference = 'all genders' OR p.gender_preference = $${paramIndex})`);
    params.push(userGenderPreference);
    paramIndex++;
  }

  // Distance filter: within user's max distance
  conditions.push(`calculate_distance_km($1, $2, p.latitude, p.longitude) <= $${paramIndex}`);
  params.push(maxDistanceKm);
  paramIndex++;

  // Partner's max distance must include user (calculated inline)
  conditions.push(`(p.max_distance_km IS NULL OR p.max_distance_km >= calculate_distance_km($1, $2, p.latitude, p.longitude))`);

  // Climbing type matching: User wants partners who DO these types
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
  if (climbingTypeConditions.length > 0) {
    conditions.push(`(${climbingTypeConditions.join(' OR ')})`);
  }

  // Partner's preferences: Partner must want at least one type the user does
  const partnerWantsConditions = [];
  if (wantsTrad) partnerWantsConditions.push('p.wants_trad = true');
  if (wantsSport) partnerWantsConditions.push('p.wants_sport = true');
  if (wantsBouldering) partnerWantsConditions.push('p.wants_bouldering = true');
  if (wantsIndoor) partnerWantsConditions.push('p.wants_indoor = true');
  if (wantsOutdoor) partnerWantsConditions.push('p.wants_outdoor = true');
  
  if (partnerWantsConditions.length > 0) {
    conditions.push(`(${partnerWantsConditions.join(' OR ')})`);
  }

  // Both user and partner must have location data
  conditions.push('p.latitude IS NOT NULL');
  conditions.push('p.longitude IS NOT NULL');

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
      p.does_trad,
      p.does_sport,
      p.does_bouldering,
      p.does_indoor,
      p.does_outdoor,
      calculate_distance_km($1, $2, p.latitude, p.longitude) as distance_km
    FROM profiles p
    WHERE ${conditions.join(' AND ')}
    ORDER BY distance_km ASC, p.created_at DESC
    LIMIT 50
  `;

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

