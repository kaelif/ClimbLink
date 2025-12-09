/**
 * Test script to verify Supabase database connection
 * Run with: node test-db-connection.js
 */

require('dotenv').config();
const supabase = require('./src/config/supabaseClient');

async function testConnection() {
  console.log('🔍 Testing Supabase Connection...\n');
  
  // Test 1: Check environment variables
  console.log('1️⃣ Checking environment variables:');
  console.log(`   SUPABASE_URL: ${process.env.SUPABASE_URL ? '✅ Set' : '❌ Missing'}`);
  console.log(`   SUPABASE_ANON_KEY: ${process.env.SUPABASE_ANON_KEY ? '✅ Set' : '❌ Missing'}\n`);
  
  // Test 2: Test basic connection
  console.log('2️⃣ Testing database connection:');
  try {
    const { data, error, count } = await supabase
      .from('profiles')
      .select('*', { count: 'exact' })
      .limit(1);
    
    if (error) {
      console.log(`   ❌ Connection failed: ${error.message}`);
      console.log(`   Details: ${JSON.stringify(error, null, 2)}\n`);
      return;
    }
    
    console.log(`   ✅ Connected successfully!`);
    console.log(`   Total profiles in database: ${count || 0}\n`);
    
    // Test 3: Fetch and display sample data
    if (data && data.length > 0) {
      console.log('3️⃣ Sample profile data:');
      const sample = data[0];
      console.log(`   ID: ${sample.id}`);
      console.log(`   Name: ${sample.name}`);
      console.log(`   Age: ${sample.age}`);
      console.log(`   Skill Level: ${sample.skill_level}`);
      console.log(`   Location: ${sample.location}`);
      console.log(`   Does Bouldering: ${sample.does_bouldering}`);
      console.log(`   Does Sport: ${sample.does_sport}`);
      console.log(`   Does Trad: ${sample.does_trad}\n`);
    }
    
    // Test 4: Test the repository function
    console.log('4️⃣ Testing repository getStack() function:');
    const { getStack } = require('./src/repositories/profiles');
    const transformedProfiles = await getStack();
    console.log(`   ✅ Successfully transformed ${transformedProfiles.length} profiles`);
    
    if (transformedProfiles.length > 0) {
      console.log(`\n5️⃣ Sample transformed profile (frontend format):`);
      const sample = transformedProfiles[0];
      console.log(JSON.stringify(sample, null, 2));
    }
    
    console.log('\n✅ All tests passed! Database connection is working.\n');
    
  } catch (error) {
    console.log(`   ❌ Error: ${error.message}`);
    console.log(`   Stack: ${error.stack}\n`);
  }
}

testConnection();

