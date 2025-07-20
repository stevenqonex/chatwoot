# Enterprise Features Setup Guide

## Overview

This guide explains how to enable enterprise features in both development and production environments using the `setup_enterprise.rake` task. **Production setup is for testing and evaluation purposes only** and should not be used in production without proper enterprise licensing.

## ⚠️ Important Legal Notice

**WARNING**: Enterprise features require a valid Chatwoot Enterprise subscription for production use. The production setup bypasses license validation for testing purposes only.

- **Development/Testing**: Permitted for evaluation and testing
- **Production Use**: Requires valid enterprise license and compliance with terms of service
- **Legal Compliance**: Respect Chatwoot's intellectual property rights
- **Terms of Service**: Must comply with Chatwoot's subscription terms

## 🚀 Quick Setup

### Any Environment Setup (Development or Production)

#### 1. Complete Environment Setup with Safeguards

```bash
# Complete environment setup (includes working safeguards)
rails chatwoot:dev:setup_dev_environment                    # For development
rails chatwoot:dev:enable_enterprise                        # For development
RAILS_ENV=production rails chatwoot:dev:enable_enterprise   # For production
```

This command will:
- ✅ Set pricing plan to 'premium'
- ✅ Set unlimited licenses (999,999)
- ✅ Enable all premium features for existing accounts
- ✅ **Disable Chatwoot Hub sync** (prevents license validation)
- ✅ **Clear Stripe billing data** (prevents billing conflicts)
- ✅ Show current configuration status

**Environment Detection:**
- **Development**: Runs without confirmation
- **Production**: Requires explicit 'YES' confirmation with legal warnings
- **Command Format**: Must prefix with `RAILS_ENV=production` for production mode

#### 2. Verify Setup

```bash
# Check current enterprise status with safeguards
rails chatwoot:dev:show_enterprise_status
```

#### 3. Reset When Done

```bash
# Disable enterprise features and restore all services
rails chatwoot:dev:disable_enterprise
```

**Expected Output:**
```
📊 Enterprise Configuration Status
========================================
Environment: production
Enterprise Directory: ✅ Present
Current Plan: premium
License Quantity: 999999

🔧 Development Mode Status:
   Hub Sync: ❌ Disabled
   Version Checks: ❌ Disabled

🚨 PRODUCTION ENVIRONMENT DETECTED:
   - Ensure you have proper enterprise licensing
   - Monitor usage and comply with terms of service
   - Consider purchasing enterprise license for production use
```

## 🛡️ Safeguards

### What Are Safeguards?
Safeguards prevent external services from interfering with your environment:

#### **1. Chatwoot Hub Sync Disable (✅ Works)**
```bash
# Prevents license data syncing with Chatwoot servers
rails chatwoot:dev:disable_hub_sync
rails chatwoot:dev:enable_hub_sync  # To re-enable
```

#### **2. Stripe Billing Data Clear (✅ Works)**
```bash
# Prevents Stripe billing events from overriding manual settings
rails chatwoot:dev:clear_stripe_data
```

### Why Use Safeguards?

| Issue | Without Safeguards | With Safeguards |
|-------|-------------------|-----------------|
| **Hub Sync** | License data might be reset | ✅ License data stays stable |
| **Stripe Billing** | Billing events might override settings | ✅ Manual settings preserved |
| **External Services** | Your services work normally | ✅ Your services work normally |

### What Safeguards Don't Do:
- ❌ Don't disable your external services (Twilio, Sentry, etc.)
- ❌ Don't prevent you from using your API keys
- ❌ Don't affect third-party integrations

## 🎯 Available Enterprise Features

### Premium Features (Enterprise)
- `disable_branding` - Remove Chatwoot branding
- `audit_logs` - Comprehensive activity tracking
- `sla` - Service Level Agreements
- `captain_integration` - AI-powered conversation assistance
- `custom_roles` - Granular permission management
- `help_center_embedding_search` - AI-powered help center search
- `captain_integration_v2` - Captain V2 (internal)

### Internal Features (Development/Testing)
- `inbox_view` - Inbox view
- `shopify_integration` - Shopify integration
- `search_with_gin` - GIN search
- `channel_voice` - Voice channel
- `contact_chatwoot_support_team` - Contact Chatwoot support

### Feature Categories

#### AI & Automation
- **Captain Integration**: AI-powered conversation assistance
- **Copilot Threads**: Advanced AI conversation management

#### Advanced Management
- **Custom Roles**: Granular permission management
- **Audit Logs**: Comprehensive activity tracking
- **Team Management**: Advanced team collaboration

#### Branding & Customization
- **Custom Branding**: Remove Chatwoot branding
- **White-label Solutions**: Complete brand customization

#### Advanced Integrations
- **Multiple Channels**: Twitter, Facebook, Instagram, Email
- **CRM Integrations**: Salesforce, HubSpot, etc.

## 🔧 Manual Configuration

### Environment Variables

#### Development Setup
```bash
# In your .env file - Complete development setup
DISABLE_TELEMETRY=true  # This is the only one that actually works
```

#### Production Setup
```bash
# In your .env file - Production setup
RAILS_ENV=production
DISABLE_TELEMETRY=true  # Disables Chatwoot Hub sync
```

### Rails Console Commands
```ruby
# Set premium plan
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update!(value: 'premium')

# Set unlimited licenses
InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update!(value: '999999')

# Disable hub sync (this actually works)
ENV['DISABLE_TELEMETRY'] = 'true'

# Clear Stripe billing data
Account.find_each do |account|
  if account.custom_attributes['stripe_customer_id'].present?
    account.custom_attributes.delete('stripe_customer_id')
    account.custom_attributes.delete('stripe_price_id')
    account.custom_attributes.delete('stripe_product_id')
    account.custom_attributes.delete('plan_name')
    account.custom_attributes.delete('subscribed_quantity')
    account.custom_attributes.delete('subscription_status')
    account.custom_attributes.delete('subscription_ends_on')
    account.save!
  end
end

# Enable features for an account
account.enable_features!('captain_integration', 'custom_branding', 'audit_logs')
```

## 🛠️ Useful Commands

### Complete Setup Commands
```bash
# Development Environment
rails chatwoot:dev:enable_enterprise
rails chatwoot:dev:setup_dev_environment

# Production Environment (Evaluation Only)
RAILS_ENV=production rails chatwoot:dev:enable_enterprise

# Individual safeguard controls
rails chatwoot:dev:disable_hub_sync
rails chatwoot:dev:disable_version_checks
rails chatwoot:dev:clear_stripe_data
```

### Feature Management
```bash
# Enable specific feature
rails chatwoot:dev:enable_feature[captain_integration]

# Disable specific feature
rails chatwoot:dev:disable_feature[captain_integration]

# Reset Captain usage
rails chatwoot:dev:reset_captain_usage
```

### Status Checks
```bash
# Check complete status
rails chatwoot:dev:show_enterprise_status
```

```ruby
# In Rails console
ChatwootHub.pricing_plan                    # Current plan
ChatwootHub.pricing_plan_quantity           # License quantity
account.feature_enabled?('captain_integration')  # Check feature
account.enabled_features                    # All enabled features

# Check safeguard status
ENV['DISABLE_TELEMETRY']                    # Hub sync disabled?
Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION)  # Version checks disabled?
```

## 🚨 Important Notes

### Development vs Production
- ⚠️ **Development**: These commands are for development and testing only
- ⚠️ **Production**: Requires explicit confirmation and includes legal warnings
- ⚠️ **Evaluation**: Production setup is for evaluation purposes only
- ⚠️ **Licensing**: Always use proper enterprise licenses for production business use

### Legal Compliance
- 📋 **Development**: Permitted for testing and evaluation
- 📋 **Production**: Requires valid enterprise license for business use
- 📋 **Terms**: Must comply with Chatwoot's terms of service
- 📋 **Rights**: Respect Chatwoot's intellectual property rights
- 📋 **Safeguards**: Are for development isolation only

### What Safeguards Do
- 🛡️ **Prevent License Conflicts**: No external license validation
- 🛡️ **Isolate Environment**: No interference from Chatwoot services
- 🛡️ **Disable Update Notifications**: No version check banners
- 🛡️ **Preserve Settings**: Manual configurations stay intact
- 🛡️ **Allow External Services**: Your services work with your API keys

### What Safeguards Don't Do
- ❌ Don't disable your external services (Twilio, Sentry, etc.)
- ❌ Don't prevent you from using your API keys
- ❌ Don't affect third-party integrations
- ❌ Don't make production use legal

## 🔍 Troubleshooting

### "Enterprise directory not found"
```bash
# Check if enterprise directory exists
ls enterprise/

# If missing, ensure you have enterprise edition
git clone https://github.com/chatwoot/chatwoot.git
cd chatwoot
git checkout enterprise
```

### "This task is designed for production environments only"

**Cause**: Running production task in non-production environment
**Solution**: Set `RAILS_ENV=production` before running the task

### "Operation cancelled. No changes made."

**Cause**: Did not type 'YES' when prompted (production tasks)
**Solution**: Run the task again and type 'YES' when prompted

### "User limit reached" Error
```bash
# Increase license quantity
rails chatwoot:dev:enable_enterprise
```

### Features Not Available
```bash
# Check current status
rails chatwoot:dev:show_enterprise_status

# Re-enable features
rails chatwoot:dev:enable_enterprise
```

### License Data Being Reset
```bash
# If license data keeps resetting, ensure hub sync is disabled
rails chatwoot:dev:disable_hub_sync

# Check if Stripe data is interfering
rails chatwoot:dev:clear_stripe_data
```

### Hub sync still enabled

**Cause**: `DISABLE_TELEMETRY` not set in environment
**Solution**: Add `DISABLE_TELEMETRY=true` to your `.env` file

### External Service Issues
```bash
# External services work normally with your API keys
# If you have issues, check your API key configuration
# The safeguards don't affect your external services
```

## Security Considerations

### What the Safeguards Do
- ✅ Prevent external license validation
- ✅ Disable update notifications
- ✅ Clear billing conflicts
- ✅ Allow external services to work normally

### What the Safeguards Don't Do
- ❌ Don't make production use legal
- ❌ Don't provide enterprise support
- ❌ Don't guarantee compliance with terms
- ❌ Don't replace proper licensing

### Best Practices
1. **Use for evaluation only** - Not for production business use
2. **Monitor usage** - Track feature usage and compliance
3. **Consider licensing** - Purchase proper enterprise license for production
4. **Respect terms** - Comply with Chatwoot's terms of service
5. **Document usage** - Keep records of evaluation period

## Legal Compliance

### Development vs Production
- **Development**: Permitted for testing and evaluation
- **Production**: Requires valid enterprise license
- **Evaluation**: Limited time for testing features
- **Commercial Use**: Must have proper licensing

### Terms of Service
- Enterprise features require valid subscription
- Usage must comply with Chatwoot's terms
- License violations may result in service suspension
- Respect intellectual property rights

### Recommendations
1. **Evaluate thoroughly** - Test all features during evaluation period
2. **Plan licensing** - Determine proper license tier for your needs
3. **Purchase license** - Obtain valid enterprise license for production
4. **Monitor compliance** - Ensure ongoing compliance with terms

## 📚 Additional Resources

- [Full License Documentation](LICENSE_README.md)
- [Development Safeguards Config](config/development_safeguards.yml)
- [Chatwoot Documentation](https://www.chatwoot.com/docs)
- [Enterprise Features Guide](https://www.chatwoot.com/docs/enterprise)

### Legal Resources
- [Chatwoot Terms of Service](https://www.chatwoot.com/terms-of-service/)
- [Enterprise License](enterprise/LICENSE)
- [Subscription Information](https://www.chatwoot.com/pricing)

### Getting Help
- [Chatwoot Community](https://www.chatwoot.com/community)
- [Enterprise Support](https://www.chatwoot.com/support)
- [Contact Sales](https://www.chatwoot.com/contact)

## 🎯 Quick Reference

### Development Setup
```bash
# Complete development environment
rails chatwoot:dev:setup_dev_environment

# Basic enterprise features only
rails chatwoot:dev:enable_enterprise
```

### Production Setup (Evaluation Only)
```bash
# Complete production environment with safeguards
rails chatwoot:dev:setup_production_environment

# Basic production enterprise features
rails chatwoot:dev:enable_enterprise_production
```

### Status Check
```bash
rails chatwoot:dev:show_enterprise_status
```

### Reset Everything
```bash
rails chatwoot:dev:disable_enterprise
```

### Individual Controls
```bash
# Safeguards
rails chatwoot:dev:disable_hub_sync
rails chatwoot:dev:disable_version_checks
rails chatwoot:dev:clear_stripe_data

# Features
rails chatwoot:dev:enable_feature[captain_integration]
rails chatwoot:dev:reset_captain_usage
```

## 💡 Key Points

### What Actually Works:
- ✅ `DISABLE_TELEMETRY` - Disables Chatwoot Hub sync
- ✅ Clearing version cache - Disables update notifications
- ✅ Clearing Stripe data - Prevents billing conflicts
- ✅ Setting premium plan - Enables enterprise features
- ✅ Setting unlimited licenses - Removes user limits

### What Doesn't Work:
- ❌ `DISABLE_EXTERNAL_APIS` - Chatwoot ignores this
- ❌ `DISABLE_THIRD_PARTY_SERVICES` - Chatwoot ignores this
- ❌ `DISABLE_VERSION_CHECK` - Chatwoot ignores this
- ❌ `DISABLE_BILLING_EVENTS` - Chatwoot ignores this

### External Services:
- ✅ **Work normally** with your API keys
- ✅ **Not affected** by the safeguards
- ✅ **Can be configured** as usual
- ✅ **Include**: Twilio, Sentry, New Relic, Facebook, Slack, etc.

---

**Happy Development! 🎉**

**Remember**: 
- Development safeguards make development easier but don't make production use legal
- Production setup is for evaluation purposes only
- Always use proper enterprise licenses for production business use
- Respect Chatwoot's intellectual property rights and terms of service 