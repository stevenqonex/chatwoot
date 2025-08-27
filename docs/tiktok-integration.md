# TikTok Business Messaging API Integration

This document describes the integration of TikTok Business Messaging API with Chatwoot, allowing businesses to manage TikTok customer conversations alongside other communication channels.

## Overview

The TikTok Business Messaging API integration enables Chatwoot users to:
- Receive messages from TikTok users
- Send replies to TikTok conversations
- Manage TikTok business conversations in a unified interface
- Handle media attachments (images, videos, audio, files)

## Architecture

The integration follows Chatwoot's established channel architecture patterns:

```
Channel::Tiktok (Model)
├── Tiktok::BaseService (Shared API utilities)
├── Tiktok::Providers::BaseService (Provider base class)
│   └── Tiktok::Providers::TiktokBusinessService (Provider Service)
├── Tiktok::ConversationService (Conversation Management)
├── Tiktok::ImageUploadService (Media Upload)
├── Tiktok::ImageDownloadService (Media Download)
├── Tiktok::MessageLimitService (Message Limits)
├── Tiktok::WebhookSetupService (Webhook Management)
├── Tiktok::IncomingMessageService (Incoming Message Processing)
├── Tiktok::SendOnTiktokService (Outgoing Message Service)
└── Webhooks::TiktokController (Webhook Endpoint)
```

## Setup

### 1. Environment Variables

Add the following environment variables to your Chatwoot installation:

```bash
# TikTok Business API Configuration
TIKTOK_APP_ID=your_tiktok_app_id
TIKTOK_APP_SECRET=your_tiktok_app_secret
TIKTOK_WEBHOOK_VERIFY_TOKEN=your_webhook_verify_token
```

**Note**: The `TIKTOK_APP_ID` is automatically included in API headers for proper authentication.

### 2. TikTok App Configuration

1. Create a TikTok Developer account at [TikTok for Developers](https://developers.tiktok.com/)
2. Create a new app with Business Messaging API permissions
3. Configure OAuth redirect URI: `https://your-domain.com/tiktok/callback`
4. Enable the following scopes:
   - `user.info.basic` - Basic user information access
   - `business.messaging` - Business messaging permissions (includes send/receive)
5. Note down your App ID and App Secret

### 3. Webhook Configuration

Configure your TikTok app webhook endpoint:
- URL: `https://your-domain.com/webhooks/tiktok`
- Verify Token: Use the same value as `TIKTOK_WEBHOOK_VERIFY_TOKEN`

## Features

### Message Types Supported

- **Text Messages**: Standard text conversations (max 6,000 characters)
- **Image Messages**: JPG and PNG formats only, up to 3MB
- **Limitations**: Video and voice messages are not supported by TikTok Business API

### Message Format

The TikTok API expects messages in the following format:

**Text Messages:**
```json
{
  "to_user_id": "recipient_id",
  "message_type": "text",
  "content": {
    "text": "message_content"
  }
}
```

**Image Messages (with media_id):**
```json
{
  "to_user_id": "recipient_id",
  "message_type": "image",
  "content": {
    "image": {
      "media_id": "uploaded_media_id",
      "caption": "Optional caption"
    }
  }
}
```

**Authentication Header:**
```
Access-Token: your_access_token
```

### OAuth Flow

The integration uses OAuth 2.0 for secure authentication:
1. User initiates TikTok connection from Chatwoot
2. Redirect to TikTok authorization page
3. User grants permissions
4. TikTok redirects back with authorization code
5. Chatwoot exchanges code for access token
6. Channel is created and webhooks are configured

### Webhook Processing

- Incoming messages are processed asynchronously via `Webhooks::TiktokEventsJob`
- Messages are parsed and converted to Chatwoot format
- Contacts and conversations are automatically created/updated

### TikTok-Specific Constraints

- **Message Window**: 48-hour window after receiving a user message
- **Message Limit**: Maximum 10 messages per 48-hour window
- **Rate Limits**: 10 queries per second (QPS) for messaging operations
- **Regional Limitations**: Not available for US organizations; Limited functionality in EEA, Switzerland, and UK

## API Endpoints

### Webhook Endpoint
```
POST /webhooks/tiktok
```

### OAuth Endpoints
```
POST /api/v1/accounts/:account_id/tiktok/authorization
GET  /tiktok/callback
```

### TikTok API Endpoints
```
GET  /open_api/v1.3/business/account/info
POST /open_api/v1.3/business/message/send/
```

### API Base URL
```
https://business-api.tiktok.com/open_api/v1.3
```

### Complete Endpoint URLs
```
# Authentication
POST https://business-api.tiktok.com/open_api/v1.3/oauth/authorize/
POST https://business-api.tiktok.com/open_api/v1.3/oauth/access_token/

# Account & Business
GET  https://business-api.tiktok.com/open_api/v1.3/business/account/info

# Messaging
POST https://business-api.tiktok.com/open_api/v1.3/business/message/send/
GET  https://business-api.tiktok.com/open_api/v1.3/business/conversation/list/
GET  https://business-api.tiktok.com/open_api/v1.3/business/message/list/

# Media
POST https://business-api.tiktok.com/open_api/v1.3/business/media/upload/
GET  https://business-api.tiktok.com/open_api/v1.3/business/media/download/
```

## Database Schema

```sql
CREATE TABLE channel_tiktok (
  id BIGINT PRIMARY KEY,
  business_id VARCHAR NOT NULL UNIQUE,
  access_token VARCHAR NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  webhook_verify_token VARCHAR,
  provider_config JSONB DEFAULT '{}',
  account_id INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

## Configuration

### Installation Config

The integration adds the following configuration options to Chatwoot:

- `TIKTOK_APP_ID`: TikTok application identifier
- `TIKTOK_APP_SECRET`: TikTok application secret
- `TIKTOK_WEBHOOK_VERIFY_TOKEN`: Webhook verification token

### Feature Flags

- `channel_tiktok`: Enable/disable TikTok channel functionality

## Usage

### Adding TikTok Channel

1. Navigate to Settings > Inboxes
2. Click "Add Inbox"
3. Select "TikTok" from channel options
4. Click "Continue with TikTok"
5. Complete OAuth authorization
6. Configure inbox settings

### Managing Conversations

- TikTok conversations appear alongside other channels
- Standard Chatwoot conversation management applies
- Media attachments are automatically handled
- Message threading and history are preserved

## Error Handling

### Common Issues

1. **Authentication Errors**: Check TikTok app credentials and permissions
2. **Webhook Failures**: Verify webhook URL and verify token
3. **Rate Limiting**: TikTok API has rate limits that may affect message delivery

### Troubleshooting

- Check Chatwoot logs for TikTok-related errors
- Verify environment variables are correctly set
- Ensure TikTok app has required permissions
- Check webhook endpoint accessibility

## Security

- OAuth 2.0 for secure authentication
- Webhook verification token for endpoint security
- Access tokens are encrypted and stored securely
- No sensitive data is logged

## Performance

- Asynchronous webhook processing
- Efficient message parsing and storage
- Minimal impact on Chatwoot performance
- Optimized API calls to TikTok

## Future Enhancements

- Template message support
- Rich media message types
- Advanced interactive elements
- Analytics and reporting integration
- Bulk messaging capabilities

## Support

For issues related to the TikTok integration:
1. Check Chatwoot logs for error details
2. Verify TikTok app configuration
3. Review webhook endpoint accessibility
4. Consult TikTok Business API documentation

## References

- [TikTok Business API Documentation](https://business-api.tiktok.com/portal/docs?id=1832183871604753)
- [Chatwoot Channel Development Guide](https://developers.chatwoot.com/contributing-guide/telegram-channel-setup)
- [OAuth 2.0 Implementation Guide](https://oauth.net/2/)
