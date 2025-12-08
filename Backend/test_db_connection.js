// Quick script to test PostgreSQL connection
// Run with: node test_db_connection.js

require('dotenv').config();
const { Pool } = require('pg');

const testConnections = [
  // Try with password from .env
  process.env.DATABASE_URL,
  // Try without password
  process.env.DATABASE_URL?.replace(/:\w+@/, '@'),
  // Try with empty password
  process.env.DATABASE_URL?.replace(/postgres:postgres@/, 'postgres@'),
];

async function testConnection(connectionString, label) {
  console.log(`\nTesting: ${label}`);
  console.log(`Connection string: ${connectionString?.replace(/:[^:@]+@/, ':****@')}`);
  
  const pool = new Pool({
    connectionString,
    ssl: false,
  });

  try {
    const result = await pool.query('SELECT version()');
    console.log('✅ Connection successful!');
    console.log(`PostgreSQL version: ${result.rows[0].version.split(' ')[0]} ${result.rows[0].version.split(' ')[1]}`);
    await pool.end();
    return true;
  } catch (error) {
    console.log(`❌ Connection failed: ${error.message}`);
    await pool.end();
    return false;
  }
}

async function main() {
  console.log('Testing PostgreSQL connections...\n');
  
  // Test current .env connection
  if (process.env.DATABASE_URL) {
    const success = await testConnection(process.env.DATABASE_URL, 'Current .env DATABASE_URL');
    if (success) {
      console.log('\n✅ Your current DATABASE_URL works!');
      return;
    }
  }

  // Try without password
  if (process.env.DATABASE_URL) {
    const noPassword = process.env.DATABASE_URL.replace(/:\w+@/, '@');
    const success = await testConnection(noPassword, 'Without password');
    if (success) {
      console.log('\n✅ Connection works WITHOUT password!');
      console.log(`\nUpdate your .env file to:`);
      console.log(`DATABASE_URL=${noPassword}`);
      return;
    }
  }

  console.log('\n❌ None of the connection attempts worked.');
  console.log('\nPlease check:');
  console.log('1. PostgreSQL is running');
  console.log('2. Your PostgreSQL username (might not be "postgres")');
  console.log('3. Your PostgreSQL password');
  console.log('4. The database "climblink" exists');
  console.log('\nYou can find your PostgreSQL credentials in pgAdmin or check your PostgreSQL installation.');
}

main().catch(console.error);

