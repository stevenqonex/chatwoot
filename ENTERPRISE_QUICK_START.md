# Enterprise Features Setup Guide

## Overview

This guide explains how to enable enterprise features in both development and production environments using the `setup_enterprise.rake` task.

## 🚀 Quick Setup

### Any Environment Setup (Development or Production)

#### 1. Complete Environment Setup with All Safeguards (Recommended)

```bash
# Complete environment setup with ALL protections (includes backdoor protection)
rails chatwoot:dev:setup_enterprise_safe                    # For any environment
rails chatwoot:dev:setup_dev_environment                     # For development only
rails chatwoot:dev:enable_enterprise                         # Basic setup only
```

This command will:
- ✅ Set pricing plan to 'premium'
- ✅ Set unlimited licenses (999,999)
- ✅ Enable all premium features for existing accounts
- ✅ **Disable ALL reset mechanisms** (prevents license conflicts)
- ✅ **Disable backdoor endpoints** (protects from super admin changes)
- ✅ **Clear Stripe billing data** (prevents billing conflicts)
- ✅ **Create enterprise backup** (for restoration if needed)
- ✅ Show current configuration status

#### 2. Verify Complete Setup

```bash
# Check current enterprise status with ALL safeguards
rails chatwoot:dev:show_enterprise_status

# Check reset mechanisms status
rails chatwoot:dev:check_reset_mechanisms

# Check backdoor endpoints status
rails chatwoot:dev:check_backdoor_endpoints
```

#### 3. Reset When Done

```bash
# Disable enterprise features and restore all services
rails chatwoot:dev:disable_enterprise

# Restore reset mechanisms (if needed)
rails chatwoot:dev:restore_reset_mechanisms

# Restore enterprise settings from backup (if needed)
rails chatwoot:dev:restore_enterprise_backup
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
   Premium Config Warning: ✅ Cleared
   Reset Mechanisms: ✅ DISABLED
   Backdoor Endpoints: ✅ PROTECTED

```

## 🛡️ Comprehensive Safeguards

### What Are Safeguards?
Safeguards prevent external services and internal mechanisms from interfering with your environment:

#### **1. Reset Mechanisms Disabled (✅ Complete Protection)**
```bash
# Disable ALL mechanisms that can reset enterprise features
rails chatwoot:dev:disable_reset_mechanisms

# Check status
rails chatwoot:dev:check_reset_mechanisms

# Restore if needed
rails chatwoot:dev:restore_reset_mechanisms
```

**Protects Against:**
- Daily Hub Sync Job (CheckNewVersionsJob)
- ReconcilePlanConfigService
- Stripe Billing Events
- Version Check Notifications

#### **2. Backdoor Endpoints Disabled (✅ Complete Protection)**
```bash
# Disable potential backdoor endpoints
rails chatwoot:dev:disable_backdoor_endpoints

# Check status
rails chatwoot:dev:check_backdoor_endpoints

# Restore if needed
rails chatwoot:dev:restore_enterprise_backup
```

**Protects Against:**
- Super Admin Installation Config Controller
- Super Admin App Config Controller
- Stripe Webhook Endpoint
- Variant Toggle Rake Task

#### **3. Chatwoot Hub Sync Disable (✅ Works)**
```bash
# Prevents license data syncing with Chatwoot servers
rails chatwoot:dev:disable_hub_sync
rails chatwoot:dev:enable_hub_sync  # To re-enable
```

#### **4. Stripe Billing Data Clear (✅ Works)**
```bash
# Prevents Stripe billing events from overriding manual settings
rails chatwoot:dev:clear_stripe_data
```

### Why Use Comprehensive Safeguards?

| Issue | Without Safeguards | With Safeguards |
|-------|-------------------|-----------------|
| **Hub Sync** | License data might be reset daily | ✅ License data stays stable |
| **Stripe Billing** | Billing events might override settings | ✅ Manual settings preserved |
| **Super Admin** | Could accidentally reset via UI | ✅ Pricing plan locked |
| **Webhooks** | External events could reset features | ✅ Webhooks disabled |
| **Console Commands** | Accidental reset via rake tasks | ✅ Protected with backups |
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
# Complete environment with ALL protections (Recommended)
rails chatwoot:dev:setup_enterprise_safe

# Development Environment
rails chatwoot:dev:setup_dev_environment
rails chatwoot:dev:enable_enterprise

# Production Environment (Evaluation Only)
RAILS_ENV=production rails chatwoot:dev:enable_enterprise

# Individual safeguard controls
rails chatwoot:dev:disable_reset_mechanisms
rails chatwoot:dev:disable_backdoor_endpoints
rails chatwoot:dev:disable_hub_sync
rails chatwoot:dev:disable_version_checks
rails chatwoot:dev:clear_stripe_data
```

### Status Check Commands
```bash
# Check complete status
rails chatwoot:dev:show_enterprise_status

# Check reset mechanisms status
rails chatwoot:dev:check_reset_mechanisms

# Check backdoor endpoints status
rails chatwoot:dev:check_backdoor_endpoints
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

### Restore Commands
```bash
# Restore reset mechanisms (use with caution)
rails chatwoot:dev:restore_reset_mechanisms

# Restore enterprise settings from backup
rails chatwoot:dev:restore_enterprise_backup

# Disable enterprise features
rails chatwoot:dev:disable_enterprise
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
Redis::Alfred.get('ENTERPRISE_RESET_MECHANISMS_DISABLED')  # Reset mechanisms disabled?
Redis::Alfred.get('ENTERPRISE_PRICING_PLAN_LOCKED')        # Pricing plan locked?
```
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
# If license data keeps resetting, ensure ALL safeguards are active
rails chatwoot:dev:setup_enterprise_safe

# Check specific safeguard status
rails chatwoot:dev:check_reset_mechanisms
rails chatwoot:dev:check_backdoor_endpoints
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

### Super Admin Can't Edit Settings
```bash
# This is expected behavior - pricing plan is locked for protection
# If you need to make changes, temporarily restore mechanisms
rails chatwoot:dev:restore_reset_mechanisms
# Make your changes
# Then re-disable for protection
rails chatwoot:dev:disable_reset_mechanisms
```

## 🎯 Quick Reference

### Complete Setup (Recommended)
```bash
# Complete environment with ALL protections
rails chatwoot:dev:setup_enterprise_safe

# Development environment
rails chatwoot:dev:setup_dev_environment

# Basic enterprise features only
rails chatwoot:dev:enable_enterprise
```

### Status Check
```bash
# Complete status check
rails chatwoot:dev:show_enterprise_status

# Check reset mechanisms
rails chatwoot:dev:check_reset_mechanisms

# Check backdoor protection
rails chatwoot:dev:check_backdoor_endpoints
```

### Reset Everything
```bash
# Disable enterprise features
rails chatwoot:dev:disable_enterprise

# Restore reset mechanisms (if needed)
rails chatwoot:dev:restore_reset_mechanisms

# Restore from backup (if needed)
rails chatwoot:dev:restore_enterprise_backup
```

### Individual Controls
```bash
# Safeguards
rails chatwoot:dev:disable_reset_mechanisms
rails chatwoot:dev:disable_backdoor_endpoints
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
- ✅ Disabling reset mechanisms - Prevents daily sync resets
- ✅ Disabling backdoor endpoints - Protects from admin changes
- ✅ Creating backups - Allows restoration if needed

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

### Protection Levels:
- 🛡️ **Basic**: `enable_enterprise` - Just enables features
- 🛡️ **Standard**: `setup_dev_environment` - Includes basic safeguards
- 🛡️ **Complete**: `setup_enterprise_safe` - ALL protections enabled

---

**Happy Development! 🎉**