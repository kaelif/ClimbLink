const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL?.trim();
const supabaseAnonKey = process.env.ANON_KEY?.trim() || process.env.SUPABASE_ANON_KEY?.trim();

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Missing Supabase credentials. Please check your .env file.');
  console.error('Required: SUPABASE_URL and ANON_KEY (or SUPABASE_ANON_KEY)');
}

const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: false,
  },
});

module.exports = supabase;