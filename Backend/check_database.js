// Check database connection and if climblink database exists
require('dotenv').config();
const { Pool } = require('pg');

async function checkDatabase() {
  console.log('Checking database connection...\n');
  console.log('Connection string:', process.env.DATABASE_URL?.replace(/:[^:@]+@/, ':****@'));
  
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: false,
  });

  try {
    // Try to connect and query
    const result = await pool.query('SELECT current_database() as db_name, version() as pg_version');
    console.log('✅ Connected successfully!');
    console.log('📊 Current database:', result.rows[0].db_name);
    console.log('📊 PostgreSQL version:', result.rows[0].pg_version.split(' ')[0], result.rows[0].pg_version.split(' ')[1]);
    
    // Check if profiles table exists
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'profiles'
      );
    `);
    
    if (tableCheck.rows[0].exists) {
      console.log('✅ Profiles table exists');
      
      // Count rows
      const count = await pool.query('SELECT COUNT(*) FROM profiles');
      console.log('📊 Number of profiles:', count.rows[0].count);
    } else {
      console.log('❌ Profiles table does NOT exist');
      console.log('   Run: Backend/db/create_profiles_table.sql');
    }
    
    await pool.end();
  } catch (error) {
    console.log('❌ Connection failed:', error.message);
    console.log('\nPossible issues:');
    console.log('1. Wrong password in .env file');
    console.log('2. Database "climblink" does not exist');
    console.log('3. PostgreSQL is not running');
    console.log('4. Wrong username or host');
    await pool.end();
    process.exit(1);
  }
}

checkDatabase();

