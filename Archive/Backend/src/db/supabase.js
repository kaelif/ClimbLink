const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const supabaseUrl = process.env.SUPABASE_URL?.trim();
const supabaseAnonKey = process.env.ANON_KEY?.trim() || process.env.SUPABASE_ANON_KEY?.trim();

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('⚠️  Missing Supabase credentials. Using PostgreSQL connection instead.');
  console.warn('To use Supabase JS client, add SUPABASE_URL and ANON_KEY to .env');
  module.exports = null;
} else {
  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      persistSession: false,
    },
  });

  // Test the connection asynchronously (don't block server startup)
  supabase
    .from('profiles')
    .select('id')
    .limit(1)
    .then(({ error }) => {
      if (error) {
        console.error('❌ Supabase connection error:', error.message);
      } else {
        console.log('✅ Connected to Supabase');
      }
    })
    .catch((err) => {
      console.error('❌ Supabase connection error:', err.message);
    });

  module.exports = supabase;
}

