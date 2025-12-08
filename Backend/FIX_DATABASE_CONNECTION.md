# Fixing PostgreSQL Connection

## The Problem
Your `.env` file has incorrect PostgreSQL credentials. The password "postgres" is not working.

## Solution Options

### Option 1: Find Your PostgreSQL Password in pgAdmin

1. **Open pgAdmin**
2. **Check your server connection:**
   - Look at the server you're connected to (usually "PostgreSQL" or "localhost")
   - Right-click on it → **Properties**
   - Check the **Connection** tab to see the username
   - The password is stored in pgAdmin but not visible (it's encrypted)

3. **Test the connection:**
   - Try connecting with different passwords you might have set
   - Common default passwords: `postgres`, `admin`, `password`, or no password

### Option 2: Reset PostgreSQL Password

If you forgot your password, you can reset it:

**On macOS (if installed via Homebrew):**
```bash
# Stop PostgreSQL
brew services stop postgresql

# Start PostgreSQL in single-user mode
/usr/local/var/postgres/bin/postgres --single -D /usr/local/var/postgres -U postgres

# Then in the postgres prompt, run:
ALTER USER postgres PASSWORD 'your_new_password';
\q
```

**Or use pgAdmin:**
1. Connect to your server (if you can)
2. Right-click on **Login/Group Roles** → **Create** → **Login/Group Role**
3. Or modify existing user: Right-click on **postgres** user → **Properties** → **Definition** tab → Set password

### Option 3: Use Your macOS Username

Sometimes PostgreSQL uses your macOS username instead of "postgres":

1. **Check your macOS username:**
   ```bash
   whoami
   ```

2. **Update `.env` file:**
   ```env
   DATABASE_URL=postgresql://YOUR_MAC_USERNAME@localhost:5432/climblink
   ```
   (Replace `YOUR_MAC_USERNAME` with the output of `whoami`)

### Option 4: Check if PostgreSQL Requires No Password

Some PostgreSQL installations allow local connections without a password:

1. **Update `.env` file:**
   ```env
   DATABASE_URL=postgresql://postgres@localhost:5432/climblink
   ```
   (No password in the connection string)

### Option 5: Check PostgreSQL Configuration

The issue might be in PostgreSQL's `pg_hba.conf` file. Check if it allows password authentication or requires a different method.

## Quick Test

After updating your `.env` file, test the connection:

```bash
cd Backend
node test_db_connection.js
```

## Once Connected

After you get the connection working:

1. **Make sure the database exists:**
   - In pgAdmin, check if `climblink` database exists
   - If not, create it: Right-click **Databases** → **Create** → **Database** → Name: `climblink`

2. **Run the schema:**
   - In pgAdmin Query Tool on `climblink` database
   - Execute `Backend/db/create_database.sql` or `Backend/db/create_profiles_table.sql`

3. **Start the server:**
   ```bash
   npm start
   ```

## Common Issues

- **"database does not exist"**: Create the `climblink` database first
- **"password authentication failed"**: Wrong password in `.env`
- **"connection refused"**: PostgreSQL is not running
- **"role does not exist"**: Wrong username in `.env`

