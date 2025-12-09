require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { getStack, getOrCreateUserProfile, updateUserProfile } = require('./src/repositories/profiles');
const { recordSwipe } = require('./src/repositories/swipes');

const app = express();

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get("/health", (req, res) => {
    res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// Get stack endpoint
app.get("/getStack", async (req, res) => {
    try {
        const deviceId = req.query.deviceId || null; // Get deviceId from query parameter
        console.log(`[${new Date().toISOString()}] GET /getStack - Fetching profiles for device: ${deviceId || 'anonymous'}...`);
        const profiles = await getStack(deviceId);
        console.log(`[${new Date().toISOString()}] GET /getStack - Successfully fetched ${profiles.length} profiles`);
        res.json({
            stack: profiles,
            count: profiles.length,
        });
    } catch (error) {
        console.error(`[${new Date().toISOString()}] GET /getStack - Error:`, error.message);
        console.error('Full error:', error);
        res.status(500).json({
            error: 'Failed to fetch profiles',
            message: error.message,
        });
    }
});

// Record a swipe action (like or pass)
app.post("/swipes", async (req, res) => {
    try {
        const { swiperDeviceId, swipedProfileId, action } = req.body;
        
        if (!swiperDeviceId || !swipedProfileId || !action) {
            return res.status(400).json({
                error: 'Missing required fields',
                message: 'swiperDeviceId, swipedProfileId, and action are required',
            });
        }

        if (!['like', 'pass'].includes(action)) {
            return res.status(400).json({
                error: 'Invalid action',
                message: 'Action must be either "like" or "pass"',
            });
        }

        console.log(`[${new Date().toISOString()}] POST /swipes - Recording ${action} from ${swiperDeviceId} for profile ${swipedProfileId}`);
        const swipe = await recordSwipe(swiperDeviceId, swipedProfileId, action);
        console.log(`[${new Date().toISOString()}] POST /swipes - Success`);
        res.json(swipe);
    } catch (error) {
        console.error(`[${new Date().toISOString()}] POST /swipes - Error:`, error.message);
        res.status(500).json({
            error: 'Failed to record swipe',
            message: error.message,
        });
    }
});

// Get or create user profile by device ID
app.get("/user/profile/:deviceId", async (req, res) => {
    try {
        const { deviceId } = req.params;
        console.log(`[${new Date().toISOString()}] GET /user/profile/${deviceId} - Getting or creating profile...`);
        const profile = await getOrCreateUserProfile(deviceId);
        console.log(`[${new Date().toISOString()}] GET /user/profile/${deviceId} - Success`);
        res.json(profile);
    } catch (error) {
        console.error(`[${new Date().toISOString()}] GET /user/profile/:deviceId - Error:`, error.message);
        res.status(500).json({
            error: 'Failed to get or create profile',
            message: error.message,
        });
    }
});

// Update user profile by device ID
app.put("/user/profile/:deviceId", async (req, res) => {
    try {
        const { deviceId } = req.params;
        const profileData = req.body;
        console.log(`[${new Date().toISOString()}] PUT /user/profile/${deviceId} - Updating profile...`);
        const updatedProfile = await updateUserProfile(deviceId, profileData);
        console.log(`[${new Date().toISOString()}] PUT /user/profile/${deviceId} - Success`);
        res.json(updatedProfile);
    } catch (error) {
        console.error(`[${new Date().toISOString()}] PUT /user/profile/:deviceId - Error:`, error.message);
        res.status(500).json({
            error: 'Failed to update profile',
            message: error.message,
        });
    }
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Connected to Supabase: ${process.env.SUPABASE_URL ? 'Yes' : 'No'}`);
});