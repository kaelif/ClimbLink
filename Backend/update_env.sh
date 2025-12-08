#!/bin/bash
# Quick script to update .env file with different PostgreSQL credentials

echo "PostgreSQL Connection String Updater"
echo "======================================"
echo ""
echo "Current DATABASE_URL:"
grep DATABASE_URL .env || echo "Not found"
echo ""
echo "Options:"
echo "1. Use macOS username (jordan) with no password"
echo "2. Use postgres username with no password"
echo "3. Use postgres username with custom password"
echo "4. Enter custom connection string"
echo ""
read -p "Choose option (1-4): " choice

case $choice in
  1)
    NEW_URL="postgresql://jordan@localhost:5432/climblink"
    ;;
  2)
    NEW_URL="postgresql://postgres@localhost:5432/climblink"
    ;;
  3)
    read -sp "Enter password: " password
    echo ""
    NEW_URL="postgresql://postgres:${password}@localhost:5432/climblink"
    ;;
  4)
    read -p "Enter full connection string: " NEW_URL
    ;;
  *)
    echo "Invalid option"
    exit 1
    ;;
esac

# Update .env file
if grep -q "DATABASE_URL=" .env; then
  # Replace existing DATABASE_URL
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|DATABASE_URL=.*|DATABASE_URL=${NEW_URL}|" .env
  else
    # Linux
    sed -i "s|DATABASE_URL=.*|DATABASE_URL=${NEW_URL}|" .env
  fi
else
  # Add new DATABASE_URL
  echo "DATABASE_URL=${NEW_URL}" >> .env
fi

echo ""
echo "✅ Updated .env file!"
echo "New DATABASE_URL: ${NEW_URL}"
echo ""
echo "Test the connection with: node test_db_connection.js"

