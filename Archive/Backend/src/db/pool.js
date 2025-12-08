// ============================================
// DATABASE CONNECTION - Supabase PostgreSQL
// ============================================
const { Pool } = require('pg');
require('dotenv').config();

// Disable SSL certificate validation for Supabase connections
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// Parse connection string and remove sslmode parameter (we handle SSL in Pool config)
let connectionString = process.env.DATABASE_URL;
if (connectionString && connectionString.includes('sslmode=')) {
  // Remove sslmode parameter from connection string
  connectionString = connectionString.replace(/[?&]sslmode=[^&]*/, '');
  // Clean up any trailing ? or & if they're left
  connectionString = connectionString.replace(/[?&]$/, '');
}

// Configure pool for Supabase with proper SSL handling
const pool = new Pool({
  connectionString: connectionString,
  // Supabase requires SSL, but we need to disable certificate validation
  // because Node.js may have issues with Supabase's certificate chain
  ssl: {
    rejectUnauthorized: false
  },
});

// Test the connection
pool.on('connect', () => {
  console.log('Connected to Supabase PostgreSQL database');
});

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  // Don't exit the process on connection errors - let the server handle it
  // process.exit(-1);
});

module.exports = pool;

