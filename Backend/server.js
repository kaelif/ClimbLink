require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { getStack } = require('./src/repositories/profiles');

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
        console.log(`[${new Date().toISOString()}] GET /getStack - Fetching profiles...`);
        const profiles = await getStack();
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

const PORT = process.env.PORT || 4000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Connected to Supabase: ${process.env.SUPABASE_URL ? 'Yes' : 'No'}`);
});