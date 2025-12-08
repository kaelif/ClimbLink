const express = require('express');
// ============================================
// DATABASE MODE
// ============================================
const { getStack } = require('../repositories/profiles');

// ============================================
// DUMMY DATA MODE (commented out - using database)
// ============================================
// const partnersStack = require('../data/partners');

const router = express.Router();

/**
 * GET /getStack
 * Returns a stack of profiles matching the user's criteria
 * 
 * Query parameters (optional, for demo purposes):
 * - userId: ID of current user to exclude from results
 * - age: User's age
 * - gender: User's gender
 * - latitude: User's latitude
 * - longitude: User's longitude
 * - maxDistanceKm: Maximum distance in km
 * - minAgePreference: Minimum age preference
 * - maxAgePreference: Maximum age preference
 * - genderPreference: Gender preference ('men', 'women', 'all genders')
 * - wantsTrad: Want trad climbing partners (true/false)
 * - wantsSport: Want sport climbing partners (true/false)
 * - wantsBouldering: Want bouldering partners (true/false)
 * - wantsIndoor: Want indoor climbing partners (true/false)
 * - wantsOutdoor: Want outdoor climbing partners (true/false)
 */
router.get('/getStack', async (req, res, next) => {
  try {
    // ============================================
    // DUMMY DATA MODE (commented out - using database)
    // ============================================
    /*
    res.json({
      stack: partnersStack,
      count: partnersStack.length,
    });
    */

    // ============================================
    // DATABASE MODE
    // ============================================
    // Extract user profile from query parameters or use defaults
    const userProfile = {
      userId: req.query.userId || null,
      age: parseInt(req.query.age) || 28,
      gender: req.query.gender || 'man',
      latitude: parseFloat(req.query.latitude) || 40.014986, // Default: Boulder, CO
      longitude: parseFloat(req.query.longitude) || -105.270546,
      maxDistanceKm: parseInt(req.query.maxDistanceKm) || 50,
      minAgePreference: parseInt(req.query.minAgePreference) || 24,
      maxAgePreference: parseInt(req.query.maxAgePreference) || 40,
      genderPreference: req.query.genderPreference || 'all genders',
      wantsTrad: req.query.wantsTrad === 'true',
      wantsSport: req.query.wantsSport !== 'false', // Default to true
      wantsBouldering: req.query.wantsBouldering !== 'false', // Default to true
      wantsIndoor: req.query.wantsIndoor === 'true',
      wantsOutdoor: req.query.wantsOutdoor !== 'false', // Default to true
    };

    const stack = await getStack(userProfile);

    res.json({
      stack,
      count: stack.length,
    });
  } catch (error) {
    console.error('Error in getStack endpoint:', error);
    next(error);
  }
});

module.exports = router;


