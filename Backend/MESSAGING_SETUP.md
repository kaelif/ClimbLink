# Messaging Feature Setup Guide

## Overview
The messaging feature allows users to send and receive messages between matched profiles. Messages are stored in a `messages` table and accessed via REST API endpoints.

## Database Setup

### Step 1: Create the messages table
Run the SQL script in your Supabase SQL Editor:

```sql
-- See Backend/db/create_messages_table.sql for the full schema
```

Or copy the contents of `Backend/db/create_messages_table.sql` into the Supabase SQL Editor and execute it.

The table includes:
- `id`: Primary key (SERIAL)
- `sender_id`: Foreign key to profiles table
- `recipient_id`: Foreign key to profiles table
- `content`: Message text
- `is_read`: Boolean flag for read status
- `created_at`: Timestamp

## API Endpoints

### Send a Message
```
POST /messages
Body: {
  "senderDeviceId": "device-uuid",
  "recipientDeviceId": "device-uuid",
  "content": "Hello!"
}
```

### Get Conversation
```
GET /messages/conversation?deviceId1=<deviceId1>&deviceId2=<deviceId2>
Returns: {
  "messages": [...],
  "currentUserId": <integer>,
  "otherUserId": <integer>
}
```

### Get All Conversations
```
GET /messages/conversations/:deviceId
Returns: {
  "conversations": [
    {
      "otherUserId": <integer>,
      "otherUserDeviceId": "device-uuid",
      "otherUserName": "Name",
      "otherUserImage": "person.circle.fill",
      "lastMessage": {...},
      "unreadCount": 0,
      "lastMessageAt": "timestamp"
    }
  ]
}
```

### Mark Messages as Read
```
POST /messages/read
Body: {
  "deviceId": "device-uuid",
  "otherDeviceId": "device-uuid"
}
```

## Frontend Integration

### Views
- **ChatListView**: Shows all conversations for the current user
- **ChatView**: Individual conversation view with message input

### Navigation
- Access ChatListView from MatchesView via the message icon in the toolbar
- Start a conversation from a match's profile (requires device ID mapping)

### Usage
1. Users can view all their conversations in ChatListView
2. Tap a conversation to open ChatView
3. Type and send messages
4. Messages are automatically marked as read when viewing a conversation
5. Unread message counts are shown in the conversation list

## Notes
- Messages use device IDs to identify users (not profile UUIDs)
- The backend converts device IDs to profile IDs internally
- Profile IDs are integers in the database, but converted to UUIDs for the frontend
- The `currentUserId` in conversation responses helps the frontend determine message ownership


