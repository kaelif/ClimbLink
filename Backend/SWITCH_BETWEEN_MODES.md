# Switching Between Dummy Data and Database

This guide shows how to switch between using dummy data and the PostgreSQL database.

## Current Mode: DUMMY DATA ✅

The backend is currently configured to use dummy data from `src/data/partners.js`.

## To Switch to Database Mode

### Step 1: Update `src/routes/stack.js`

1. **Comment out** the dummy data section:
   ```javascript
   // const partnersStack = require('../data/partners');
   ```

2. **Uncomment** the database import:
   ```javascript
   const { getStack } = require('../repositories/profiles');
   ```

3. **Comment out** the dummy data response:
   ```javascript
   /*
   res.json({
     stack: partnersStack,
     count: partnersStack.length,
   });
   */
   ```

4. **Uncomment** the database query section (the entire block with `getStack(userProfile)`)

### Step 2: Update `src/app.js`

**Uncomment** the dotenv line:
```javascript
require('dotenv').config();
```

### Step 3: Update `src/db/pool.js`

**Uncomment** the entire file (remove the `/*` and `*/`)

### Step 4: Update `src/repositories/profiles.js`

**Uncomment** the pool import:
```javascript
const pool = require('../db/pool');
```

### Step 5: Ensure `.env` file is configured

Make sure `Backend/.env` has the correct `DATABASE_URL`:
```env
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/climblink
```

### Step 6: Restart the server

```bash
# Stop the current server (Ctrl+C)
npm start
```

## To Switch Back to Dummy Data Mode

Reverse all the steps above:
1. Comment out database code
2. Uncomment dummy data code
3. Restart the server

## Quick Reference

**Dummy Data Mode:**
- ✅ No database connection needed
- ✅ Works immediately
- ✅ No `.env` file needed
- ✅ Fast and simple for development

**Database Mode:**
- ✅ Real data from PostgreSQL
- ✅ Filtering and matching logic
- ✅ Requires database setup
- ✅ Requires correct `.env` configuration

