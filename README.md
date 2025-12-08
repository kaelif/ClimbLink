# ClimbLink

A Tinder-like mobile app for matching climbing partners. Built with SwiftUI (iOS) and Node.js/Express backend with PostgreSQL.

## Features

- 🧗 Swipeable card interface for browsing climbing partners
- 📍 Location-based matching with distance filtering
- 🎯 Preference-based filtering (age, gender, climbing types)
- 💚 Match system for mutual likes
- 📱 Beautiful, modern iOS interface

## Tech Stack

### Frontend
- **SwiftUI** - iOS app framework
- **Swift** - Programming language
- **Xcode** - Development environment

### Backend
- **Node.js** - Runtime environment
- **Express** - Web framework
- **PostgreSQL** - Database
- **pg** - PostgreSQL client for Node.js

## Prerequisites

Before you begin, ensure you have the following installed:

- **macOS** (for iOS development)
- **Xcode** (latest version recommended)
- **Node.js** (v18 or higher) - [Download](https://nodejs.org/)
- **PostgreSQL** (v14 or higher) - [Download](https://www.postgresql.org/download/)
- **pgAdmin** (optional, for database management) - [Download](https://www.pgadmin.org/)

## Setup Instructions

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ClimbLink
```

### 2. Backend Setup

#### 2.1 Install Dependencies

```bash
cd Backend
npm install
```

#### 2.2 Set Up PostgreSQL Database

**Option A: Using pgAdmin (Recommended for beginners)**

1. Open **pgAdmin**
2. Connect to your PostgreSQL server (usually `localhost:5432`)
3. Right-click on **"Databases"** → **"Create"** → **"Database"**
4. Name: `climblink`
5. Click **"Save"**

**Option B: Using Terminal**

```bash
psql -U postgres -c "CREATE DATABASE climblink;"
```

#### 2.3 Create Database Schema

**Using pgAdmin:**
1. Right-click on the `climblink` database
2. Select **"Query Tool"**
3. Open `Backend/db/create_database.sql`
4. Copy and paste the contents into the query editor
5. Click **"Execute"** (or press F5)

**Using Terminal:**
```bash
psql -U postgres -d climblink -f Backend/db/create_database.sql
```

#### 2.4 Seed Sample Data (Optional)

**Using pgAdmin:**
1. Open Query Tool on the `climblink` database
2. Open `Backend/db/seed_data.sql`
3. Copy and paste the contents
4. Click **"Execute"**

**Using Terminal:**
```bash
psql -U postgres -d climblink -f Backend/db/seed_data.sql
```

#### 2.5 Configure Environment Variables

Create a `.env` file in the `Backend` directory:

```bash
cd Backend
cp .env.example .env  # If .env.example exists, or create manually
```

Edit `.env` and update with your PostgreSQL credentials:

```env
# Database connection string
# Format: postgresql://username:password@host:port/database
DATABASE_URL=postgresql://postgres:your_password@localhost:5432/climblink

# Server port
PORT=4000

# Environment
NODE_ENV=development
```

**Important:** Replace `your_password` with your actual PostgreSQL password. If you don't have a password set, use:
```env
DATABASE_URL=postgresql://postgres@localhost:5432/climblink
```

#### 2.6 Start the Backend Server

```bash
npm start
```

The server should start on `http://localhost:4000`. You should see:
```
ClimbLink backend running on http://localhost:4000
```

**Test the API:**
```bash
curl http://localhost:4000/getStack
```

### 3. Frontend Setup

#### 3.1 Open the Project in Xcode

```bash
cd Frontend
open ClimbLink.xcodeproj
```

#### 3.2 Configure API Endpoint (if needed)

The frontend is configured to connect to `http://localhost:4000` by default. If your backend is running on a different address:

1. Open `Frontend/ClimbLink/Services/ClimbingPartnerService.swift`
2. Update the `baseURL` in the initializer:
   ```swift
   init(baseURL: URL = URL(string: "http://YOUR_IP_ADDRESS:4000")!, ...)
   ```

**Note:** If testing on a physical iOS device (not simulator), you'll need to:
- Use your Mac's IP address instead of `localhost`
- Ensure your Mac and iOS device are on the same network
- Make sure your Mac's firewall allows connections on port 4000

#### 3.3 Select a Simulator

In Xcode:
1. Click on the device selector at the top (next to the play button)
2. Choose an iOS Simulator (e.g., "iPhone 15 Pro")

#### 3.4 Build and Run

1. Press **⌘ + R** (or click the Play button)
2. Wait for the app to build and launch in the simulator
3. The app will automatically fetch profiles from the backend

## Running the Application

### Start Backend

```bash
cd Backend
npm start
```

### Start Frontend

1. Open Xcode
2. Open `Frontend/ClimbLink.xcodeproj`
3. Select a simulator
4. Press **⌘ + R**

## Project Structure

```
ClimbLink/
├── Backend/
│   ├── db/
│   │   ├── create_database.sql    # Database schema
│   │   └── seed_data.sql           # Sample data
│   ├── src/
│   │   ├── db/
│   │   │   └── pool.js            # Database connection pool
│   │   ├── repositories/
│   │   │   └── profiles.js        # Database queries
│   │   ├── routes/
│   │   │   └── stack.js           # API routes
│   │   ├── app.js                 # Express app setup
│   │   └── server.js              # Server entry point
│   ├── .env                        # Environment variables (not in git)
│   └── package.json
│
└── Frontend/
    └── ClimbLink/
        ├── Models/
        │   └── ClimbingPartner.swift
        ├── Services/
        │   └── ClimbingPartnerService.swift
        ├── Views/
        │   ├── MatchingView.swift
        │   ├── SwipeableCard.swift
        │   ├── PartnerDetailView.swift
        │   └── MatchesView.swift
        └── ClimbLinkApp.swift
```

## API Endpoints

### `GET /getStack`

Returns a stack of profiles matching the user's criteria.

**Query Parameters (optional):**
- `age` - User's age (default: 28)
- `gender` - User's gender: 'man', 'woman', 'non-binary', 'prefer not to say' (default: 'man')
- `latitude` - User's latitude (default: 40.014986 - Boulder, CO)
- `longitude` - User's longitude (default: -105.270546)
- `maxDistanceKm` - Maximum distance in km (default: 50)
- `minAgePreference` - Minimum age preference (default: 24)
- `maxAgePreference` - Maximum age preference (default: 40)
- `genderPreference` - 'men', 'women', 'all genders' (default: 'all genders')
- `wantsTrad` - Want trad climbing partners (true/false)
- `wantsSport` - Want sport climbing partners (true/false)
- `wantsBouldering` - Want bouldering partners (true/false)
- `wantsIndoor` - Want indoor climbing partners (true/false)
- `wantsOutdoor` - Want outdoor climbing partners (true/false)

**Example:**
```bash
curl "http://localhost:4000/getStack?age=28&gender=man&maxDistanceKm=50"
```

**Response:**
```json
{
  "stack": [
    {
      "id": "uuid",
      "name": "Alex",
      "age": 28,
      "bio": "...",
      "skillLevel": "Advanced",
      "preferredTypes": ["Sport Climbing", "Bouldering", "Outdoor"],
      "location": "Boulder, CO",
      "profileImageName": "person.circle.fill",
      "availability": "Weekends",
      "favoriteCrag": "Eldorado Canyon"
    }
  ],
  "count": 1
}
```

## Troubleshooting

### Backend Issues

**Database connection error:**
- Verify PostgreSQL is running: `pg_isready`
- Check your `.env` file has the correct `DATABASE_URL`
- Ensure the database `climblink` exists
- Verify your PostgreSQL username and password

**Port already in use:**
- Change the `PORT` in `.env` to a different port (e.g., 4001)
- Or kill the process using port 4000: `lsof -ti:4000 | xargs kill`

### Frontend Issues

**Cannot connect to backend:**
- Ensure the backend server is running
- Check the `baseURL` in `ClimbingPartnerService.swift`
- For physical devices, use your Mac's IP address instead of `localhost`
- Verify both devices are on the same network

**Build errors:**
- Clean build folder: **⌘ + Shift + K**
- Restart Xcode
- Ensure you're using a compatible iOS version (iOS 16+)

**No profiles showing:**
- Check backend logs for errors
- Verify database has data (run seed script)
- Test the API endpoint directly with `curl`

## Development

### Backend Development

```bash
cd Backend
npm run dev  # Runs with NODE_ENV=development
```

### Database Migrations

When updating the database schema:
1. Update `Backend/db/create_database.sql`
2. Run the updated SQL in pgAdmin or via psql
3. Update the repository queries in `Backend/src/repositories/profiles.js` if needed

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

[Add your license here]

## Support

For issues or questions, please open an issue on the repository.

