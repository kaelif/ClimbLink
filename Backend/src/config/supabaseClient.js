require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL?.trim();
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY?.trim();

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    'Missing SUPABASE_URL or SUPABASE_ANON_KEY in environment variables.\n' +
    'Please add SUPABASE_ANON_KEY to your .env file.\n' +
    'You can find it in your Supabase dashboard under Project Settings > API.'
  );
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

module.exports = supabase;