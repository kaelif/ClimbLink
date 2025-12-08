# Database Setup Guide

## Step 1: Create the Database

### Using pgAdmin:
1. Open pgAdmin
2. Connect to your PostgreSQL server (usually `localhost:5432`)
3. Right-click on "Databases" → "Create" → "Database"
4. Name: `climblink`
5. Click "Save"

### Using Terminal (if psql is available):
```bash
psql -U postgres -c "CREATE DATABASE climblink;"
```

## Step 2: Update .env File

Edit `Backend/.env` and update the `DATABASE_URL` with your actual PostgreSQL credentials:

```env
DATABASE_URL=postgresql://YOUR_USERNAME:YOUR_PASSWORD@localhost:5432/climblink
```

**Common configurations:**
- Default PostgreSQL: `postgresql://postgres:postgres@localhost:5432/climblink`
- If no password: `postgresql://postgres@localhost:5432/climblink`
- If different port: `postgresql://postgres:postgres@localhost:YOUR_PORT/climblink`

## Step 3: Run the Schema

After creating the database, run the SQL schema:

### Using pgAdmin:
1. Right-click on the `climblink` database
2. Select "Query Tool"
3. Open `Backend/db/create_database.sql`
4. Copy and paste the contents
5. Click "Execute" (F5)

### Using Terminal:
```bash
psql -U postgres -d climblink -f Backend/db/create_database.sql
```

## Step 4: Seed Sample Data (Optional)

### Using pgAdmin:
1. Open Query Tool on `climblink` database
2. Open `Backend/db/seed_data.sql`
3. Copy and paste the contents
4. Click "Execute" (F5)

### Using Terminal:
```bash
psql -U postgres -d climblink -f Backend/db/seed_data.sql
```

## Step 5: Verify Setup

Now you can run:
```bash
npx prisma studio
```

Or test the backend:
```bash
npm start
```

Then test the endpoint:
```bash
curl http://localhost:4000/getStack
```


