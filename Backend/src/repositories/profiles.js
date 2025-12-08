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
 * Fetch all profiles from the database
 */
async function getStack() {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching profiles from Supabase:', error);
      throw error;
    }

    if (!data || data.length === 0) {
      console.warn('No profiles found in database');
      return [];
    }

    // Transform database profiles to frontend format
    return data.map(transformProfile);
  } catch (error) {
    console.error('Error in getStack:', error);
    throw error;
  }
}

module.exports = {
  getStack,
};

