const supabase = require('../config/supabaseClient');

/**
 * Convert integer ID to UUID format for frontend compatibility
 * Creates a deterministic UUID from an integer ID
 */
function integerToUUID(id) {
  // If it's already a valid UUID string, return it
  if (typeof id === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id)) {
    return id;
  }
  
  // Convert integer to UUID format (deterministic)
  // Format: 550e8400-e29b-41d4-a716-{12 hex digits from ID}
  const idNum = typeof id === 'number' ? id : parseInt(id, 10);
  const hexId = idNum.toString(16).padStart(12, '0');
  return `550e8400-e29b-41d4-a716-${hexId}`;
}

/**
 * Transform database profile to frontend format
 */
function transformProfile(profile) {
  // Build preferredTypes array from does_* boolean fields
  const preferredTypes = [];
  if (profile.does_bouldering) preferredTypes.push('Bouldering');
  if (profile.does_sport) preferredTypes.push('Sport Climbing');
  if (profile.does_trad) preferredTypes.push('Traditional');
  if (profile.does_indoor) preferredTypes.push('Indoor');
  if (profile.does_outdoor) preferredTypes.push('Outdoor');

  // Convert ID to UUID format (handles both UUID and integer IDs)
  const idString = integerToUUID(profile.id);

  return {
    id: idString,
    name: profile.name,
    age: profile.age,
    bio: profile.bio || '',
    skillLevel: profile.skill_level || 'Intermediate',
    preferredTypes: preferredTypes.length > 0 ? preferredTypes : ['Indoor'], // Default if none
    location: profile.location || 'Unknown',
    profileImageName: profile.profile_image_name || 'person.circle.fill',
    availability: profile.availability || 'Flexible',
    favoriteCrag: profile.favorite_crag || null,
  };
}

/**
 * Transform frontend profile to database format
 */
function transformProfileToDb(profile) {
  return {
    name: profile.name,
    age: profile.age,
    bio: profile.bio || '',
    skill_level: profile.skillLevel || 'Intermediate',
    location: profile.location || 'Unknown',
    profile_image_name: profile.profileImageName || 'person.circle.fill',
    availability: profile.availability || 'Flexible',
    favorite_crag: profile.favoriteCrag || null,
    does_bouldering: profile.preferredTypes?.includes('Bouldering') || false,
    does_sport: profile.preferredTypes?.includes('Sport Climbing') || false,
    does_trad: profile.preferredTypes?.includes('Traditional') || false,
    does_indoor: profile.preferredTypes?.includes('Indoor') || false,
    does_outdoor: profile.preferredTypes?.includes('Outdoor') || false,
  };
}

/**
 * Fetch profiles from the database, excluding user's own profile and passed profiles
 * @param {string} deviceId - Device ID of the current user
 */
async function getStack(deviceId = null) {
  try {
    console.log(`[${new Date().toISOString()}] getStack: Fetching profiles (deviceId: ${deviceId || 'none'})...`);
    
    let query = supabase
      .from('profiles')
      .select('*');

    // Exclude user's own profile if deviceId is provided
    // Only filter if device_id column exists and has values
    // Note: We'll filter in memory after fetching to handle null device_id values gracefully
    if (deviceId) {
      console.log(`[${new Date().toISOString()}] getStack: Will exclude profiles with device_id = ${deviceId} (filtering after fetch)`);
    }

    // Get passed profile IDs to exclude them
    let passedProfileIds = [];
    if (deviceId) {
      try {
        const { getPassedProfileIds } = require('./swipes');
        passedProfileIds = await getPassedProfileIds(deviceId);
        console.log(`[${new Date().toISOString()}] getStack: Found ${passedProfileIds.length} passed profile IDs to exclude`);
      } catch (error) {
        // If swipes table doesn't exist yet, just log and continue
        console.warn(`[${new Date().toISOString()}] Could not fetch passed profiles (swipes table may not exist):`, error.message);
      }
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) {
      console.error(`[${new Date().toISOString()}] Error fetching profiles from Supabase:`, error);
      // If the error is about device_id column not existing, try without filtering
      if (error.message && (error.message.includes('device_id') || error.message.includes('column') || error.code === 'PGRST116')) {
        console.log(`[${new Date().toISOString()}] device_id column may not exist, fetching all profiles without device_id filter...`);
        const { data: allData, error: allError } = await supabase
          .from('profiles')
          .select('*')
          .order('created_at', { ascending: false });
        
        if (allError) {
          console.error(`[${new Date().toISOString()}] Error fetching all profiles:`, allError);
          throw allError;
        }
        
        console.log(`[${new Date().toISOString()}] getStack: Fetched ${allData?.length || 0} profiles (without device_id filter)`);
        if (!allData || allData.length === 0) {
          return [];
        }
        // Still filter passed profiles if we have them
        let filteredData = allData;
        if (passedProfileIds.length > 0) {
          const beforeCount = filteredData.length;
          filteredData = allData.filter(profile => {
            const profileId = typeof profile.id === 'number' ? profile.id : parseInt(String(profile.id), 10);
            return !passedProfileIds.includes(profileId);
          });
          console.log(`[${new Date().toISOString()}] getStack: Filtered out ${beforeCount - filteredData.length} passed profiles. Remaining: ${filteredData.length}`);
        }
        return filteredData.map(transformProfile);
      }
      throw error;
    }

    console.log(`[${new Date().toISOString()}] getStack: Fetched ${data?.length || 0} profiles from database`);

    if (!data || data.length === 0) {
      console.warn(`[${new Date().toISOString()}] No profiles found in database`);
      return [];
    }

    // Filter out user's own profile (if deviceId provided and profile has device_id set)
    let filteredData = data;
    if (deviceId) {
      const beforeCount = filteredData.length;
      filteredData = data.filter(profile => {
        // Only exclude if profile has a device_id set AND it matches the user's deviceId
        // This allows profiles with null/missing device_id to show up
        const profileDeviceId = profile.device_id;
        if (profileDeviceId === null || profileDeviceId === undefined || profileDeviceId === '') {
          return true; // Include profiles without device_id
        }
        return profileDeviceId !== deviceId; // Exclude only if device_id matches
      });
      console.log(`[${new Date().toISOString()}] getStack: Filtered out ${beforeCount - filteredData.length} profiles with matching device_id. Remaining: ${filteredData.length}`);
    }

    // Filter out passed profiles
    if (passedProfileIds.length > 0) {
      const beforeCount = filteredData.length;
      filteredData = filteredData.filter(profile => {
        // Get the integer ID of the profile
        const profileId = typeof profile.id === 'number' ? profile.id : parseInt(String(profile.id), 10);
        // Check if this profile ID is in the passed list
        return !passedProfileIds.includes(profileId);
      });
      console.log(`[${new Date().toISOString()}] getStack: Filtered out ${beforeCount - filteredData.length} passed profiles. Remaining: ${filteredData.length}`);
    }

    console.log(`[${new Date().toISOString()}] getStack: Returning ${filteredData.length} profiles after filtering`);

    // Transform database profiles to frontend format
    return filteredData.map(transformProfile);
  } catch (error) {
    console.error('Error in getStack:', error);
    throw error;
  }
}

/**
 * Get or create user profile by device ID
 */
async function getOrCreateUserProfile(deviceId) {
  try {
    // First, try to find existing profile by device_id
    const { data: existing, error: findError } = await supabase
      .from('profiles')
      .select('*')
      .eq('device_id', deviceId)
      .single();

    if (existing && !findError) {
      return transformProfile(existing);
    }

    // If not found, create a new profile with generic data
    const defaultProfile = {
      device_id: deviceId,
      name: 'New Climber',
      age: 25,
      gender: 'non-binary', // Required field - default to non-binary
      bio: 'Just getting started with climbing!',
      skill_level: 'Beginner',
      location: 'Unknown',
      profile_image_name: 'person.circle.fill',
      availability: 'Flexible',
      favorite_crag: null,
      does_bouldering: true,
      does_sport: true,
      does_trad: false,
      does_indoor: true,
      does_outdoor: false,
      // Default preferences
      min_age_preference: 20,
      max_age_preference: 40,
      gender_preference: 'all genders',
      max_distance_km: 50,
    };

    const { data: newProfile, error: createError } = await supabase
      .from('profiles')
      .insert([defaultProfile])
      .select()
      .single();

    if (createError) {
      console.error('Error creating profile:', createError);
      throw createError;
    }

    return transformProfile(newProfile);
  } catch (error) {
    console.error('Error in getOrCreateUserProfile:', error);
    throw error;
  }
}

/**
 * Update user profile by device ID
 */
async function updateUserProfile(deviceId, profileData) {
  try {
    const dbData = transformProfileToDb(profileData);

    const { data, error } = await supabase
      .from('profiles')
      .update(dbData)
      .eq('device_id', deviceId)
      .select()
      .single();

    if (error) {
      console.error('Error updating profile:', error);
      throw error;
    }

    return transformProfile(data);
  } catch (error) {
    console.error('Error in updateUserProfile:', error);
    throw error;
  }
}

module.exports = {
  getStack,
  getOrCreateUserProfile,
  updateUserProfile,
};
