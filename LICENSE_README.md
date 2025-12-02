# Chatwoot License System Documentation

## Overview

Chatwoot implements a comprehensive license validation system that manages access to features across different editions (Community, Enterprise, and Cloud). This document explains how the licensing system works and how to configure it for different use cases.

## License Types

### 1. Community Edition (MIT License)
- **License**: MIT License (see `LICENSE` file)
- **Features**: Basic customer support features
- **Limitations**: No premium features, limited integrations
- **Cost**: Free

### 2. Enterprise Edition (Proprietary License)
- **License**: Chatwoot Enterprise License (see `enterprise/LICENSE`)
- **Features**: All premium features, advanced integrations, custom branding
- **Limitations**: Requires valid subscription and user seat licenses
- **Cost**: Paid subscription

### 3. Cloud Edition (SaaS)
- **License**: Subscription-based with different tiers
- **Features**: Managed service with premium features
- **Limitations**: Usage-based limits and plan restrictions
- **Cost**: Monthly/annual subscription

## License Validation System

### Core Components

#### 1. ChatwootHub Class (`lib/chatwoot_hub.rb`)
The central license management system:

```ruby
# Get current pricing plan
ChatwootHub.pricing_plan
# Returns: 'community', 'premium', 'enterprise', etc.

# Get license quantity
ChatwootHub.pricing_plan_quantity
# Returns: Number of purchased user licenses
```

#### 2. Installation Configuration
License data is stored in `InstallationConfig`:

```yaml
# config/installation_config.yml
INSTALLATION_PRICING_PLAN: 'community'  # or 'premium', 'enterprise'
INSTALLATION_PRICING_PLAN_QUANTITY: 0   # Number of user licenses
```

#### 3. User License Validation
Enterprise user creation is validated against license limits:

```ruby
# enterprise/app/models/enterprise/concerns/user.rb
def ensure_installation_pricing_plan_quantity
  return unless ChatwootHub.pricing_plan == 'premium'
  errors.add(:base, 'User limit reached. Please purchase more licenses from super admin') if User.count >= ChatwootHub.pricing_plan_quantity
end
```

## Enterprise Features

### Premium Features Available

#### 1. AI & Automation
- **Captain Integration**: AI-powered conversation assistance
- **Copilot Threads**: Advanced AI conversation management
- **Automated Responses**: Smart reply suggestions

#### 2. Advanced Management
- **Custom Roles**: Granular permission management
- **Audit Logs**: Comprehensive activity tracking
- **Team Management**: Advanced team collaboration features

#### 3. Branding & Customization
- **Custom Branding**: Remove Chatwoot branding
- **White-label Solutions**: Complete brand customization
- **Custom Domain Support**: Use your own domain

#### 4. Advanced Integrations
- **Multiple Channel Support**: Twitter, Facebook, Instagram, Email
- **CRM Integrations**: Salesforce, HubSpot, etc.
- **Webhook Support**: Custom integrations

#### 5. Analytics & Reporting
- **Advanced Analytics**: Detailed conversation analytics
- **Custom Reports**: Tailored reporting solutions
- **Performance Metrics**: Team and agent performance tracking

## Enabling All Enterprise Features

### For Development/Testing Purposes

#### Method 1: Environment Variable Configuration

1. **Set Enterprise Mode**:
```bash
# In your environment or .env file
DISABLE_ENTERPRISE=false
CW_EDITION=enterprise
```

2. **Configure Installation Settings**:
```bash
# Set premium plan with unlimited licenses
rails console
```

```ruby
# In Rails console
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'premium')
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update!(value: 999999)
```

#### Method 2: Direct Database Configuration

```sql
-- Update installation configuration
UPDATE installation_configs 
SET value = 'premium' 
WHERE name = 'INSTALLATION_PRICING_PLAN';

UPDATE installation_configs 
SET value = '999999' 
WHERE name = 'INSTALLATION_PRICING_PLAN_QUANTITY';
```

#### Method 3: Using Rake Tasks

Create a custom rake task for development setup:

```ruby
# lib/tasks/dev/setup_enterprise.rake
namespace :chatwoot do
  namespace :dev do
    desc 'Enable all enterprise features for development'
    task enable_enterprise: :environment do
      puts "Enabling enterprise features..."
      
      # Set premium plan
      premium_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
      premium_config.update!(value: 'premium')
      
      # Set unlimited licenses
      quantity_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
      quantity_config.update!(value: '999999')
      
      # Enable all features for existing accounts
      Account.find_each do |account|
        account.enable_features!(
          'captain_integration',
          'custom_branding',
          'audit_logs',
          'disable_branding',
          'agent_capacity',
          'inbound_emails',
          'help_center',
          'campaigns',
          'team_management',
          'channel_twitter',
          'channel_facebook',
          'channel_email',
          'channel_instagram',
          'sla',
          'custom_roles'
        )
      end
      
      puts "✅ Enterprise features enabled successfully!"
      puts "Current plan: #{ChatwootHub.pricing_plan}"
      puts "License quantity: #{ChatwootHub.pricing_plan_quantity}"
    end
  end
end
```

Run the task:
```bash
rails chatwoot:dev:enable_enterprise
```

### For Production Use

#### 1. Valid Enterprise License
To use enterprise features in production, you need:
- Valid Chatwoot Enterprise subscription
- Correct number of user licenses
- Compliance with Enterprise License terms

#### 2. License Activation
1. Purchase enterprise license from Chatwoot
2. Configure billing information
3. Sync license data with Chatwoot Hub
4. Enable features based on subscription tier

## Feature Flag System

### Checking Feature Access

```ruby
# In Ruby code
account.feature_enabled?('captain_integration')
account.enabled_features # Returns hash of enabled features
```

```javascript
// In JavaScript/Vue components
const isFeatureEnabled = useMapGetter('accounts/isFeatureEnabledonAccount');
const hasFeature = isFeatureEnabled.value(accountId, 'captain_integration');
```

### Policy-based Access Control

```javascript
// app/javascript/dashboard/composables/usePolicy.js
const shouldShow = (featureFlag, permissions, installationTypes) => {
  // Check permissions
  if (!checkPermissions(perms)) return false;
  
  // Check installation type
  if (!checkInstallationType(installation)) return false;
  
  // Check feature flag
  return isFeatureFlagEnabled(flag);
};
```

## Usage Limits and Monitoring

### Agent Limits
```ruby
# Check available agent slots
account.usage_limits[:agents]
account.available_agent_count
```

### Captain Usage Limits
```ruby
# Check AI response limits
account.captain_monthly_limit[:responses]
account.increment_response_usage
```

### Monitoring Usage
```ruby
# Get current usage statistics
account.usage_limits
# Returns: { agents: 10, inboxes: 5, captain: { documents: 100, responses: 50 } }
```

## Billing Integration

### Stripe Integration (Cloud)
```ruby
# enterprise/app/services/enterprise/billing/handle_stripe_event_service.rb
class Enterprise::Billing::HandleStripeEventService
  def process_subscription_updated
    update_account_attributes(subscription, plan)
    update_plan_features
    reset_captain_usage
  end
end
```

### Plan Features Mapping
```ruby
STARTUP_PLAN_FEATURES = %w[
  inbound_emails help_center campaigns team_management
  channel_twitter channel_facebook channel_email channel_instagram
  captain_integration
]

BUSINESS_PLAN_FEATURES = %w[sla custom_roles]

ENTERPRISE_PLAN_FEATURES = %w[audit_logs disable_branding]
```

## Troubleshooting

### Common Issues

#### 1. "User limit reached" Error
**Cause**: Exceeded purchased license quantity
**Solution**: 
- Purchase more licenses, or
- For development: Increase `INSTALLATION_PRICING_PLAN_QUANTITY`

#### 2. Feature Not Available
**Cause**: Feature not enabled for current plan
**Solution**:
```ruby
# Enable specific feature
account.enable_features!('captain_integration')
```

#### 3. Enterprise Features Not Loading
**Cause**: Enterprise edition not properly configured
**Solution**:
```bash
# Check enterprise directory exists
ls enterprise/

# Verify environment variables
echo $DISABLE_ENTERPRISE
echo $CW_EDITION
```

### Debug Commands

```ruby
# Check current license status
ChatwootHub.pricing_plan
ChatwootHub.pricing_plan_quantity

# Check account features
account.enabled_features
account.feature_enabled?('captain_integration')

# Check usage limits
account.usage_limits
```

## Security Considerations

### License Validation
- License validation occurs on user creation
- Feature access is checked on each request
- Usage limits are enforced in real-time

### Development vs Production
- **Development**: Can bypass license checks for testing
- **Production**: Must have valid licenses and comply with terms

### Best Practices
1. Never bypass license validation in production
2. Regularly audit feature usage
3. Monitor license compliance
4. Keep license data synchronized

## Legal Compliance

### Enterprise License Terms
- Enterprise features require valid subscription
- Usage must comply with Chatwoot Terms of Service
- License violations may result in service suspension

### Development License
- Development/testing use is permitted
- Must not use bypassed licenses in production
- Respect intellectual property rights

## Support and Resources

### Documentation
- [Chatwoot Documentation](https://www.chatwoot.com/docs)
- [Enterprise Features Guide](https://www.chatwoot.com/docs/enterprise)
- [API Documentation](https://www.chatwoot.com/docs/api)

### Community Support
- [GitHub Issues](https://github.com/chatwoot/chatwoot/issues)
- [Community Forum](https://community.chatwoot.com)
- [Discord Channel](https://discord.gg/chatwoot)

### Enterprise Support
- [Enterprise Support Portal](https://support.chatwoot.com)
- [Sales Inquiries](https://www.chatwoot.com/contact)

---

**Note**: This documentation is for development and testing purposes. For production use, ensure compliance with Chatwoot's licensing terms and obtain proper enterprise licenses. 