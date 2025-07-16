# Enterprise Features Quick Start Guide

## 🚀 Quick Setup for Development

### 1. Enable All Enterprise Features with Safeguards (Recommended)

```bash
# Complete development environment setup (includes working safeguards)
rails chatwoot:dev:setup_dev_environment
```

This command will:
- ✅ Set pricing plan to 'premium'
- ✅ Set unlimited licenses (999,999)
- ✅ Enable all premium features for existing accounts
- ✅ **Disable Chatwoot Hub sync** (prevents license validation)
- ✅ **Clear Stripe billing data** (prevents billing conflicts)
- ✅ Show current configuration status

### 2. Alternative: Enable Enterprise Features Only

```bash
# Enable enterprise features (includes basic safeguards)
rails chatwoot:dev:enable_enterprise
```

### 3. Verify Setup

```bash
# Check current enterprise status with safeguards
rails chatwoot:dev:show_enterprise_status
```

### 4. Reset When Done

```bash
# Disable enterprise features and restore all services
rails chatwoot:dev:disable_enterprise
```

## 🛡️ Development Safeguards

### What Are Safeguards?
Development safeguards prevent external services from interfering with your development environment:

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

### AI & Automation
- **Captain Integration**: AI-powered conversation assistance
- **Copilot Threads**: Advanced AI conversation management

### Advanced Management
- **Custom Roles**: Granular permission management
- **Audit Logs**: Comprehensive activity tracking
- **Team Management**: Advanced team collaboration

### Branding & Customization
- **Custom Branding**: Remove Chatwoot branding
- **White-label Solutions**: Complete brand customization

### Advanced Integrations
- **Multiple Channels**: Twitter, Facebook, Instagram, Email
- **CRM Integrations**: Salesforce, HubSpot, etc.

## 🔧 Manual Configuration

### Environment Variables (Advanced)
```bash
# In your .env file - Complete development setup
DISABLE_ENTERPRISE=false
CW_EDITION=enterprise
DISABLE_TELEMETRY=true  # This is the only one that actually works
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
# Full development environment (recommended)
rails chatwoot:dev:setup_dev_environment

# Enterprise features only
rails chatwoot:dev:enable_enterprise

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

### Development Only
- ⚠️ These commands are for **development and testing only**
- ⚠️ Never use bypassed licenses in production
- ⚠️ Always use proper enterprise licenses for production
- ⚠️ Safeguards prevent license conflicts but don't make it production-safe

### Legal Compliance
- 📋 Respect Chatwoot's licensing terms
- 📋 Enterprise features require valid subscription in production
- 📋 Development use is permitted for testing purposes
- 📋 Safeguards are for development isolation only

### What Safeguards Do
- 🛡️ **Prevent License Conflicts**: No external license validation
- 🛡️ **Isolate Development**: No interference from Chatwoot services
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

### External Service Issues
```bash
# External services work normally with your API keys
# If you have issues, check your API key configuration
# The safeguards don't affect your external services
```

## 📚 Additional Resources

- [Full License Documentation](LICENSE_README.md)
- [Development Safeguards Config](config/development_safeguards.yml)
- [Chatwoot Documentation](https://www.chatwoot.com/docs)
- [Enterprise Features Guide](https://www.chatwoot.com/docs/enterprise)

## 🎯 Quick Reference

### One-Command Setup
```bash
rails chatwoot:dev:setup_dev_environment
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

**Remember**: Safeguards make development easier but don't make production use legal. Always use proper licenses for production environments. 