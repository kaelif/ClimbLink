# Swipe Filtering Setup Guide

## Overview
This system filters out:
1. **Your own profile** - Excluded by `device_id`
2. **Profiles you've swiped left on** - Tracked in the `swipes` table

## Database Setup

### Step 1: Create the swipes table
Run this SQL in your Supabase SQL Editor:

```sql
CREATE TABLE IF NOT EXISTS swipes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    swiper_device_id TEXT NOT NULL,
    swiped_profile_id INTEGER NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('like', 'pass')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(swiper_device_id, swiped_profile_id)
);

CREATE INDEX IF NOT EXISTS idx_swipes_swiper_device_id ON swipes(swiper_device_id);
CREATE INDEX IF NOT EXISTS idx_swipes_swiped_profile_id ON swipes(swiped_profile_id);
CREATE INDEX IF NOT EXISTS idx_swipes_action ON swipes(action);
```

### Step 2: Ensure device_id column exists
If you haven't already, run:

```sql
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS device_id TEXT UNIQUE;

CREATE INDEX IF NOT EXISTS idx_profiles_device_id ON profiles(device_id);
```

## How It Works

### Backend
1. **`GET /getStack?deviceId=<deviceId>`** - Fetches profiles excluding:
   - User's own profile (by `device_id`)
   - Profiles user has passed (from `swipes` table)

2. **`POST /swipes`** - Records a swipe action:
   ```json
   {
     "swiperDeviceId": "device-uuid",
     "swipedProfileId": "profile-uuid",
     "action": "like" // or "pass"
   }
   ```

### Frontend
- Automatically sends `deviceId` when fetching the stack
- Records swipes when user swipes left (pass) or right (like)
- Filters happen server-side, so users never see their own profile or passed profiles

## Testing

1. **Test filtering your own profile:**
   ```bash
   curl "http://localhost:4000/getStack?deviceId=your-device-id"
   ```
   Your profile should not appear in results.

2. **Test recording a swipe:**
   ```bash
   curl -X POST http://localhost:4000/swipes \
     -H "Content-Type: application/json" \
     -d '{
       "swiperDeviceId": "test-device",
       "swipedProfileId": "550e8400-e29b-41d4-a716-000000000001",
       "action": "pass"
     }'
   ```

3. **Test that passed profiles are filtered:**
   After recording a pass, fetch the stack again - that profile should not appear.

## Notes

- The system gracefully handles missing `swipes` table (logs warning but continues)
- Swipes are upserted (can update if user changes their mind)
- Profile IDs are automatically converted between UUID (frontend) and integer (database)

