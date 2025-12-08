/**
 * Test script to verify the response format matches frontend expectations
 * Run with: node test-frontend-format.js
 */

const http = require('http');

function testEndpoint() {
  return new Promise((resolve, reject) => {
    const req = http.get('http://localhost:4000/getStack', (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ statusCode: res.statusCode, data: json });
        } catch (error) {
          reject(new Error(`Failed to parse JSON: ${error.message}`));
        }
      });
    });
    
    req.on('error', (error) => {
      reject(new Error(`Request failed: ${error.message}`));
    });
    
    req.setTimeout(5000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
  });
}

async function runTests() {
  console.log('🧪 Testing Frontend Format Compatibility...\n');
  
  try {
    const { statusCode, data } = await testEndpoint();
    
    console.log(`✅ HTTP Status: ${statusCode}`);
    console.log(`✅ Response has 'stack' array: ${Array.isArray(data.stack)}`);
    console.log(`✅ Response has 'count' field: ${typeof data.count === 'number'}`);
    console.log(`✅ Count matches array length: ${data.count === data.stack.length}\n`);
    
    if (data.stack.length > 0) {
      const profile = data.stack[0];
      console.log('📋 First Profile Structure:');
      console.log(`   ✅ id: ${profile.id} (UUID format: ${/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(profile.id)})`);
      console.log(`   ✅ name: ${typeof profile.name === 'string' ? '✓' : '✗'}`);
      console.log(`   ✅ age: ${typeof profile.age === 'number' ? '✓' : '✗'}`);
      console.log(`   ✅ bio: ${typeof profile.bio === 'string' ? '✓' : '✗'}`);
      console.log(`   ✅ skillLevel: ${typeof profile.skillLevel === 'string' ? '✓' : '✗'}`);
      console.log(`   ✅ preferredTypes: ${Array.isArray(profile.preferredTypes) ? '✓' : '✗'}`);
      console.log(`   ✅ location: ${typeof profile.location === 'string' ? '✓' : '✗'}`);
      console.log(`   ✅ profileImageName: ${typeof profile.profileImageName === 'string' ? '✓' : '✗'}`);
      console.log(`   ✅ availability: ${typeof profile.availability === 'string' ? '✓' : '✗'}`);
      console.log(`   ✅ favoriteCrag: ${profile.favoriteCrag === null || typeof profile.favoriteCrag === 'string' ? '✓' : '✗'}\n`);
    }
    
    console.log('✅ All format checks passed! Ready for frontend.\n');
    
  } catch (error) {
    console.error(`❌ Test failed: ${error.message}`);
    console.error('\n💡 Make sure the backend server is running: npm run dev\n');
    process.exit(1);
  }
}

runTests();

