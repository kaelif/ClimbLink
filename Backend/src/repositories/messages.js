const supabase = require('../config/supabaseClient');

/**
 * Send a message from one user to another
 * @param {string} senderDeviceId - Device ID of the sender
 * @param {string} recipientDeviceId - Device ID of the recipient
 * @param {string} content - Message content
 * @returns {object} Created message
 */
async function sendMessage(senderDeviceId, recipientDeviceId, content) {
  try {
    if (!senderDeviceId || !recipientDeviceId || !content || content.trim() === '') {
      throw new Error('senderDeviceId, recipientDeviceId, and content are required');
    }

    // Get sender's profile ID
    const { data: senderProfile, error: senderError } = await supabase
      .from('profiles')
      .select('id')
      .eq('device_id', senderDeviceId)
      .single();

    if (senderError || !senderProfile) {
      throw new Error(`Sender profile not found for deviceId: ${senderDeviceId}`);
    }

    // Get recipient's profile ID
    const { data: recipientProfile, error: recipientError } = await supabase
      .from('profiles')
      .select('id')
      .eq('device_id', recipientDeviceId)
      .single();

    if (recipientError || !recipientProfile) {
      throw new Error(`Recipient profile not found for deviceId: ${recipientDeviceId}`);
    }

    const senderId = typeof senderProfile.id === 'number' ? senderProfile.id : parseInt(senderProfile.id, 10);
    const recipientId = typeof recipientProfile.id === 'number' ? recipientProfile.id : parseInt(recipientProfile.id, 10);

    // Create the message
    const { data, error } = await supabase
      .from('messages')
      .insert({
        sender_id: senderId,
        recipient_id: recipientId,
        content: content.trim(),
        is_read: false,
      })
      .select()
      .single();

    if (error) {
      console.error('Error sending message:', error);
      throw error;
    }

    return data;
  } catch (error) {
    console.error('Error in sendMessage:', error);
    throw error;
  }
}

/**
 * Get all messages between two users
 * @param {string} deviceId1 - Device ID of first user
 * @param {string} deviceId2 - Device ID of second user
 * @returns {Array} Array of messages
 */
async function getConversation(deviceId1, deviceId2) {
  try {
    // Get profile IDs for both users
    const { data: profile1, error: error1 } = await supabase
      .from('profiles')
      .select('id')
      .eq('device_id', deviceId1)
      .single();

    const { data: profile2, error: error2 } = await supabase
      .from('profiles')
      .select('id')
      .eq('device_id', deviceId2)
      .single();

    if (error1 || !profile1 || error2 || !profile2) {
      throw new Error('One or both profiles not found');
    }

    const id1 = typeof profile1.id === 'number' ? profile1.id : parseInt(profile1.id, 10);
    const id2 = typeof profile2.id === 'number' ? profile2.id : parseInt(profile2.id, 10);

    // Fetch all messages between these two users
    const { data, error } = await supabase
      .from('messages')
      .select('*')
      .or(`and(sender_id.eq.${id1},recipient_id.eq.${id2}),and(sender_id.eq.${id2},recipient_id.eq.${id1})`)
      .order('created_at', { ascending: true });

    if (error) {
      console.error('Error fetching conversation:', error);
      throw error;
    }

    // Return messages with metadata about which user is which
    // We'll include the profile IDs so frontend can determine ownership
    return {
      messages: data || [],
      currentUserId: id1, // Assuming deviceId1 is the current user
      otherUserId: id2,
    };
  } catch (error) {
    console.error('Error in getConversation:', error);
    throw error;
  }
}

/**
 * Get all conversations for a user (list of people they've messaged or been messaged by)
 * @param {string} deviceId - Device ID of the user
 * @returns {Array} Array of conversation summaries with last message and other user info
 */
async function getConversations(deviceId) {
  try {
    // Get user's profile ID
    const { data: userProfile, error: profileError } = await supabase
      .from('profiles')
      .select('id')
      .eq('device_id', deviceId)
      .single();

    if (profileError || !userProfile) {
      throw new Error(`Profile not found for deviceId: ${deviceId}`);
    }

    const userId = typeof userProfile.id === 'number' ? userProfile.id : parseInt(userProfile.id, 10);

    // Get all messages where user is sender or recipient
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('*')
      .or(`sender_id.eq.${userId},recipient_id.eq.${userId}`)
      .order('created_at', { ascending: false });

    if (messagesError) {
      console.error('Error fetching messages:', messagesError);
      throw messagesError;
    }

    if (!messages || messages.length === 0) {
      return [];
    }

    // Group messages by conversation partner and get the most recent message
    const conversationsMap = new Map();

    for (const message of messages) {
      const otherUserId = message.sender_id === userId ? message.recipient_id : message.sender_id;
      
      if (!conversationsMap.has(otherUserId)) {
        conversationsMap.set(otherUserId, {
          otherUserId,
          lastMessage: message,
          unreadCount: 0,
        });
      }

      const conversation = conversationsMap.get(otherUserId);
      
      // Update if this is a more recent message
      if (new Date(message.created_at) > new Date(conversation.lastMessage.created_at)) {
        conversation.lastMessage = message;
      }

      // Count unread messages (only if user is recipient)
      if (message.recipient_id === userId && !message.is_read) {
        conversation.unreadCount++;
      }
    }

    // Fetch profile information for all conversation partners
    const otherUserIds = Array.from(conversationsMap.keys());
    const { data: profiles, error: profilesError } = await supabase
      .from('profiles')
      .select('id, name, profile_image_name, device_id')
      .in('id', otherUserIds);

    if (profilesError) {
      console.error('Error fetching profiles:', profilesError);
      throw profilesError;
    }

    // Combine conversation data with profile info
    const conversations = Array.from(conversationsMap.values()).map(conv => {
      const profile = profiles?.find(p => {
        const pid = typeof p.id === 'number' ? p.id : parseInt(p.id, 10);
        return pid === conv.otherUserId;
      });

      return {
        otherUserId: conv.otherUserId,
        otherUserDeviceId: profile?.device_id || null,
        otherUserName: profile?.name || 'Unknown',
        otherUserImage: profile?.profile_image_name || 'person.circle.fill',
        lastMessage: conv.lastMessage,
        unreadCount: conv.unreadCount,
        lastMessageAt: conv.lastMessage.created_at,
      };
    });

    // Sort by most recent message
    conversations.sort((a, b) => new Date(b.lastMessageAt) - new Date(a.lastMessageAt));

    return conversations;
  } catch (error) {
    console.error('Error in getConversations:', error);
    throw error;
  }
}

/**
 * Mark messages as read
 * @param {string} deviceId - Device ID of the user
 * @param {string} otherDeviceId - Device ID of the other user in the conversation
 * @returns {number} Number of messages marked as read
 */
async function markMessagesAsRead(deviceId, otherDeviceId) {
  try {
    // Get profile IDs
    const { data: userProfile, error: userError } = await supabase
      .from('profiles')
      .select('id')
      .eq('device_id', deviceId)
      .single();

    const { data: otherProfile, error: otherError } = await supabase
      .from('profiles')
      .select('id')
      .eq('device_id', otherDeviceId)
      .single();

    if (userError || !userProfile || otherError || !otherProfile) {
      throw new Error('One or both profiles not found');
    }

    const userId = typeof userProfile.id === 'number' ? userProfile.id : parseInt(userProfile.id, 10);
    const otherUserId = typeof otherProfile.id === 'number' ? otherProfile.id : parseInt(otherProfile.id, 10);

    // Mark all unread messages from other user to current user as read
    const { data, error } = await supabase
      .from('messages')
      .update({ is_read: true })
      .eq('sender_id', otherUserId)
      .eq('recipient_id', userId)
      .eq('is_read', false)
      .select();

    if (error) {
      console.error('Error marking messages as read:', error);
      throw error;
    }

    return data?.length || 0;
  } catch (error) {
    console.error('Error in markMessagesAsRead:', error);
    throw error;
  }
}

module.exports = {
  sendMessage,
  getConversation,
  getConversations,
  markMessagesAsRead,
};

