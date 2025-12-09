const supabase = require('../config/supabaseClient');

/**
 * Convert UUID string to integer profile ID
 */
async function getProfileIntegerId(uuidString) {
  // Try to extract integer from UUID format first (e.g., "550e8400-e29b-41d4-a716-000000000001" -> 1)
  const match = uuidString.match(/0000000000([0-9a-f]+)$/i);
  if (match) {
    return parseInt(match[1], 16);
  }
  
  // If that doesn't work, query the database to find the profile by its actual ID
  // and get its integer ID
  const { data: profile, error } = await supabase
    .from('profiles')
    .select('id')
    .or(`id.eq.${uuidString},device_id.eq.${uuidString}`)
    .single();
  
  if (error || !profile) {
    throw new Error(`Profile not found for ID: ${uuidString}`);
  }
  
  // Return the integer ID
  return typeof profile.id === 'number' ? profile.id : parseInt(profile.id, 10);
}

/**
 * Record a swipe action (like or pass)
 */
async function recordSwipe(swiperDeviceId, swipedProfileId, action) {
  try {
    // Convert profile ID from UUID string to integer if needed
    let profileId;
    if (typeof swipedProfileId === 'string' && swipedProfileId.includes('-')) {
      // It's a UUID string, convert to integer
      profileId = await getProfileIntegerId(swipedProfileId);
    } else {
      // Already an integer
      profileId = typeof swipedProfileId === 'number' ? swipedProfileId : parseInt(swipedProfileId, 10);
    }

    const { data, error } = await supabase
      .from('swipes')
      .upsert({
        swiper_device_id: swiperDeviceId,
        swiped_profile_id: profileId,
        action: action, // 'like' or 'pass'
      }, {
        onConflict: 'swiper_device_id,swiped_profile_id',
      })
      .select()
      .single();

    if (error) {
      console.error('Error recording swipe:', error);
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Error in recordSwipe:', error);
    throw error;
  }
}

/**
 * Get all passed profile IDs for a user (profiles they swiped left on)
 */
async function getPassedProfileIds(swiperDeviceId) {
  try {
    const { data, error } = await supabase
      .from('swipes')
      .select('swiped_profile_id')
      .eq('swiper_device_id', swiperDeviceId)
      .eq('action', 'pass');

    if (error) {
      console.error('Error fetching passed profiles:', error);
      throw error;
    }

    return data?.map(swipe => swipe.swiped_profile_id) || [];
  } catch (error) {
    console.error('Error in getPassedProfileIds:', error);
    throw error;
  }
}

/**
 * Get all liked profile IDs for a user (profiles they swiped right on)
 */
async function getLikedProfileIds(swiperDeviceId) {
  try {
    const { data, error } = await supabase
      .from('swipes')
      .select('swiped_profile_id')
      .eq('swiper_device_id', swiperDeviceId)
      .eq('action', 'like');

    if (error) {
      console.error('Error fetching liked profiles:', error);
      throw error;
    }

    return data?.map(swipe => swipe.swiped_profile_id) || [];
  } catch (error) {
    console.error('Error in getLikedProfileIds:', error);
    throw error;
  }
}

module.exports = {
  recordSwipe,
  getPassedProfileIds,
  getLikedProfileIds,
};

