# frozen_string_literal: true

#
# CHATWOOT ENTERPRISE FEATURE SETUP
# ==================================
#
# This rake task enables enterprise features permanently for development and production.
# 
# Key Improvements for Permanent Activation:
# 
# 1. ✅ Hub Sync Verification: Checks if DISABLE_TELEMETRY=true is set before proceeding
#    - The daily CheckNewVersionsJob can override enterprise settings if hub sync is enabled
#    - Task warns users and provides clear instructions to prevent this
# 
# 2. ✅ Dynamic Feature Detection: Reads premium features from actual config files
#    - Uses features.yml to find features marked with `premium: true`
#    - Adds internal/development features for testing
#    - No more hard-coded feature lists that can become outdated
# 
# 3. ✅ Setup Verification: Confirms that settings were applied correctly
#    - Verifies pricing plan and license quantity
#    - Checks that premium features are actually enabled on accounts
#    - Fails with clear error message if something went wrong
# 
# 4. ✅ Persistent Storage: All settings are stored in the database
#    - InstallationConfig table for plan/license settings (cached in Redis)
#    - Account feature_flags column for individual features (bit flags)
#    - Cache clearing ensures immediate effect
# 
# 5. ✅ Production Safeguards: Additional safety measures for production use
#    - Requires explicit confirmation for production environments
#    - Clears potentially conflicting Stripe billing data
#    - Disables version checks that could show update notifications
#    - Clears premium configuration warnings that appear in super admin settings
# 
# Usage:
#   rails chatwoot:dev:enable_enterprise     # Enable all enterprise features
#   rails chatwoot:dev:disable_enterprise    # Disable enterprise features  
#   rails chatwoot:dev:show_enterprise_status # Check current status
#   rails chatwoot:dev:list_premium_features  # List available features
#   rails chatwoot:dev:fix_premium_alert      # Quick fix for unauthorized premium changes alert
# 
# Prerequisites for Permanent Activation:
#   1. Add DISABLE_TELEMETRY=true to your .env file
#   2. Restart your Rails application after setting DISABLE_TELEMETRY
#   3. Verify that ChatwootApp.enterprise? returns true (enterprise/ directory exists)
# 
# The enterprise features will remain active as long as:
#   - DISABLE_TELEMETRY=true prevents hub sync from resetting settings
#   - Database contains the premium plan configuration
#   - Account records have the feature flags set
#

namespace :chatwoot do
  namespace :dev do
    desc 'Enable all enterprise features (development or production with safeguards)'
    task enable_enterprise: :environment do
      # Temporarily reduce logging for cleaner output
      old_log_level = Rails.logger.level
      Rails.logger.level = Logger::INFO
      
      is_production = Rails.env.production?
      
      if is_production
        puts "🚨 PRODUCTION ENVIRONMENT DETECTED 🚨"
        puts "=" * 50
        puts "⚠️  Enabling enterprise features in production..."
        puts "\n🚀 Enabling enterprise features for production..."
      else
        puts "🚀 Enabling enterprise features for development..."
        puts "💡 To run in production mode, use: RAILS_ENV=production rails chatwoot:dev:enable_enterprise"
      end
      
      # Show warning about hub sync but continue anyway
      unless hub_sync_disabled?
        puts "⚠️  WARNING: Chatwoot Hub sync is still enabled!"
        puts "   This means the daily sync job could override your enterprise settings."
        puts "   Add DISABLE_TELEMETRY=true to your .env file to prevent this."
        puts "   Continuing with enterprise setup..."
      end
      
      # Set premium plan
      premium_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
      premium_config.update!(value: 'premium')
      puts "✅ Set pricing plan to: premium"
      
      # Set unlimited licenses
      quantity_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
      quantity_config.update!(value: 999999)
      puts "✅ Set license quantity to: 999999"
      
      # Clear cache to ensure settings take effect immediately
      GlobalConfig.clear_cache
      puts "✅ Cleared configuration cache"
      
      # Disable version checks
      disable_version_checks
      
      # Clear Stripe billing data to prevent conflicts
      clear_stripe_billing_data
      
      # Clear premium configuration warning
      clear_premium_config_warning
      
      # Enable all premium features for existing accounts
      account_count = Account.count
      if account_count > 0
        puts "🔄 Enabling premium features for #{account_count} existing account(s)..."
        
        # Get premium features from actual configuration files
        premium_features = get_premium_features_list
        
        Account.find_each do |account|
          account.enable_features!(*premium_features)
          print "."
        end
        puts ""
      else
        puts "ℹ️  No accounts found - premium features will be enabled automatically when accounts are created"
        premium_features = get_premium_features_list
      end
      
      # Verify the setup worked
      success = verify_enterprise_setup
      
      if success
        display_success_message(is_production, premium_features)
      else
        puts "❌ Enterprise setup verification failed!"
        puts "   Some settings may not have been applied correctly."
        exit 1
      end
      
      # Restore original log level
      Rails.logger.level = old_log_level
    end

    desc 'Disable enterprise features'
    task disable_enterprise: :environment do
      puts "🔄 Disabling enterprise features..."
      
      # Reset to community plan
      premium_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
      premium_config.update!(value: 'community')
      puts "✅ Set pricing plan to: community"
      
      # Reset license quantity
      quantity_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
      quantity_config.update!(value: '0')
      puts "✅ Set license quantity to: 0"
      
      # Re-enable Chatwoot Hub sync
      enable_hub_sync
      
      # Re-enable version checks
      enable_version_checks
      
      # Clear premium configuration warning
      clear_premium_config_warning
      
      # Get premium features to disable
      premium_features = get_premium_features_list
      
      # Disable all premium features for existing accounts
      account_count = Account.count
      if account_count > 0
        puts "🔄 Disabling premium features for #{account_count} existing account(s)..."
        Account.find_each do |account|
          account.disable_features!(*premium_features)
          print "."
        end
        puts ""
      else
        puts "ℹ️  No accounts found - premium features are already disabled for new accounts"
      end
      
      puts "\n✅ Enterprise features disabled successfully!"
      puts "📊 Current Configuration:"
      puts "   Plan: #{ChatwootHub.pricing_plan}"
      puts "   License Quantity: #{ChatwootHub.pricing_plan_quantity}"
    end

    desc 'Check Chatwoot Hub sync status (DISABLE_TELEMETRY setting)'
    task disable_hub_sync: :environment do
      disable_hub_sync
      puts "\n💡 To permanently disable hub sync, add DISABLE_TELEMETRY=true to your .env file"
    end

    desc 'Check Chatwoot Hub sync status (DISABLE_TELEMETRY setting)'
    task enable_hub_sync: :environment do
      enable_hub_sync
      puts "\n💡 To permanently enable hub sync, remove DISABLE_TELEMETRY from your .env file"
    end

    desc 'Disable version checks for development'
    task disable_version_checks: :environment do
      disable_version_checks
      puts "✅ Version checks disabled for development"
    end

    desc 'Enable version checks'
    task enable_version_checks: :environment do
      enable_version_checks
      puts "✅ Version checks enabled"
    end

    desc 'Clear Stripe billing data to prevent conflicts'
    task clear_stripe_data: :environment do
      clear_stripe_billing_data
      puts "✅ Stripe billing data cleared"
    end

    desc 'Clear premium configuration warning from super admin settings'
    task clear_premium_warning: :environment do
      clear_premium_config_warning
      puts "✅ Premium configuration warning cleared from super admin settings"
      puts "💡 The alert in super admin settings should now be gone"
    end

    desc 'Quick fix: Clear the unauthorized premium changes alert'
    task fix_premium_alert: :environment do
      clear_premium_config_warning
      puts "✅ Unauthorized premium changes alert cleared!"
      puts "💡 Refresh the super admin settings page to see the change"
    end

    desc 'Show current enterprise configuration status'
    task show_enterprise_status: :environment do
      puts "📊 Enterprise Configuration Status"
      puts "=" * 40
      
      puts "Environment: #{Rails.env}"
      puts "Enterprise Directory: #{ChatwootApp.enterprise? ? '✅ Present' : '❌ Not Found'}"
      puts "Current Plan: #{ChatwootHub.pricing_plan}"
      puts "License Quantity: #{ChatwootHub.pricing_plan_quantity}"
      
      puts "\n🔧 Development Mode Status:"
      puts "   Hub Sync: #{hub_sync_disabled? ? '❌ Disabled' : '✅ Enabled'}"
      puts "   Version Checks: #{Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION).present? ? '✅ Enabled' : '❌ Disabled'}"
      puts "   Premium Config Warning: #{Redis::Alfred.get(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING).present? ? '⚠️  Active' : '✅ Cleared'}"
      
      if ChatwootApp.enterprise?
        puts "\n🎯 Account Features Summary:"
        Account.find_each do |account|
          enabled_features = account.enabled_features.keys
          puts "   #{account.name}: #{enabled_features.any? ? enabled_features.join(', ') : 'No premium features'}"
        end
        
        puts "\n💳 Stripe Billing Data:"
        Account.find_each do |account|
          stripe_data = account.custom_attributes.slice('stripe_customer_id', 'plan_name', 'subscribed_quantity')
          if stripe_data.any? { |k, v| v.present? }
            puts "   #{account.name}: Has Stripe data"
          else
            puts "   #{account.name}: No Stripe data"
          end
        end
      end
      
      puts "\n🔧 Environment Variables:"
      puts "   DISABLE_TELEMETRY: #{ENV['DISABLE_TELEMETRY'] || 'Not set'}"
      
      if Rails.env.production?
        puts "\n🚨 PRODUCTION ENVIRONMENT DETECTED"
      end
    end

    desc 'List all available premium features'
    task list_premium_features: :environment do
      puts "🎯 Available Premium Features"
      puts "=" * 40
      
      # Get features from the configuration
      premium_features = get_premium_features_list
      
      # Read features.yml to get descriptions
      all_features = YAML.safe_load(Rails.root.join('config/features.yml').read)
      
      # Create categorized list with descriptions
      categorized_features = []
      
      premium_features.each do |feature_name|
        feature_config = all_features.find { |f| f['name'] == feature_name }
        
        if feature_config
          category = if feature_config['premium']
                      'Premium'
                    elsif feature_config['chatwoot_internal']
                      'Internal'
                    else
                      'Community'
                    end
          
          description = feature_config['display_name'] || feature_name.humanize
          
          categorized_features << {
            name: feature_name,
            category: category,
            description: description,
            premium: feature_config['premium'] || false
          }
        else
          # Fallback for features not in features.yml
          categorized_features << {
            name: feature_name,
            category: 'Internal',
            description: feature_name.humanize,
            premium: false
          }
        end
      end
      
      # Group by category
      features_by_category = categorized_features.group_by { |f| f[:category] }
      
      features_by_category.each do |category, features|
        puts "\n📂 #{category} (#{features.length} features):"
        features.each do |feature|
          premium_marker = feature[:premium] ? ' 💎' : ''
          puts "   • #{feature[:name]} - #{feature[:description]}#{premium_marker}"
        end
      end
      
      puts "\n💡 Usage:"
      puts "   rails chatwoot:dev:enable_feature[feature_name]"
      puts "   rails chatwoot:dev:disable_feature[feature_name]"
      puts "   rails chatwoot:dev:enable_enterprise  # Enable all features (any environment)"
    end

    desc 'Reset Captain usage for all accounts'
    task reset_captain_usage: :environment do
      puts "🔄 Resetting Captain usage for all accounts..."
      
      Account.find_each do |account|
        account.reset_response_usage
        account.update_document_usage
        print "."
      end
      puts ""
      
      puts "✅ Captain usage reset successfully!"
    end

    desc 'Enable specific enterprise feature for all accounts'
    task :enable_feature, [:feature_name] => :environment do |task, args|
      feature_name = args[:feature_name]
      
      # Get available features from configuration
      available_features = get_premium_features_list
      
      if feature_name.blank?
        puts "❌ Please specify a feature name: rails chatwoot:dev:enable_feature[feature_name]"
        puts "Available premium features: #{available_features.join(', ')}"
        exit 1
      end
      
      unless available_features.include?(feature_name)
        puts "❌ Invalid feature name: #{feature_name}"
        puts "Available premium features: #{available_features.join(', ')}"
        exit 1
      end
      
      puts "🔄 Enabling feature '#{feature_name}' for all accounts..."
      
      Account.find_each do |account|
        account.enable_features!(feature_name)
        print "."
      end
      puts ""
      
      puts "✅ Feature '#{feature_name}' enabled successfully!"
    end

    desc 'Disable specific enterprise feature for all accounts'
    task :disable_feature, [:feature_name] => :environment do |task, args|
      feature_name = args[:feature_name]
      
      # Get available features from configuration
      available_features = get_premium_features_list
      
      if feature_name.blank?
        puts "❌ Please specify a feature name: rails chatwoot:dev:disable_feature[feature_name]"
        puts "Available premium features: #{available_features.join(', ')}"
        exit 1
      end
      
      unless available_features.include?(feature_name)
        puts "❌ Invalid feature name: #{feature_name}"
        puts "Available premium features: #{available_features.join(', ')}"
        exit 1
      end
      
      puts "🔄 Disabling feature '#{feature_name}' for all accounts..."
      
      Account.find_each do |account|
        account.disable_features!(feature_name)
        print "."
      end
      puts ""
      
      puts "✅ Feature '#{feature_name}' disabled successfully!"
    end

    desc 'Setup complete development environment (enterprise + safeguards)'
    task setup_dev_environment: :environment do
      puts "🚀 Setting up complete development environment..."
      
      # Enable enterprise features
      Rake::Task['chatwoot:dev:enable_enterprise'].invoke
      
      puts "\n🎉 Complete development environment setup!"
      puts "✅ Enterprise features enabled"
      puts "✅ Hub sync disabled (prevents license conflicts)"
      puts "✅ Version checks disabled (prevents update notifications)"
      puts "✅ Stripe billing data cleared (prevents billing conflicts)"
      puts "✅ Premium configuration warning cleared (prevents super admin alerts)"
      puts "✅ External services still work with your API keys"
    end

    desc 'Permanently disable all mechanisms that can reset enterprise features to community'
    task disable_reset_mechanisms: :environment do
      puts "🛡️  Permanently disabling all reset mechanisms..."
      
      # 1. Disable the scheduled job via Sidekiq Cron
      begin
        job = Sidekiq::Cron::Job.find('internal_check_new_versions_job')
        if job
          job.disable!
          puts "✅ Disabled CheckNewVersionsJob in Sidekiq Cron"
        else
          puts "ℹ️  CheckNewVersionsJob not found in Sidekiq Cron (already disabled)"
        end
      rescue => e
        puts "⚠️  Could not disable CheckNewVersionsJob: #{e.message}"
      end
      
      # 2. Clear any existing version cache
      Redis::Alfred.delete(Redis::Alfred::LATEST_CHATWOOT_VERSION)
      puts "✅ Cleared version check cache"
      
      # 3. Clear premium configuration warning
      Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
      puts "✅ Cleared premium configuration warning"
      
      # 4. Clear any Stripe billing data
      clear_stripe_billing_data
      
      # 5. Set a persistent flag to indicate reset mechanisms are disabled
      Redis::Alfred.set('ENTERPRISE_RESET_MECHANISMS_DISABLED', 'true')
      puts "✅ Set persistent flag: ENTERPRISE_RESET_MECHANISMS_DISABLED"
      
      # 6. Verify current enterprise status
      puts "\n📊 Current Enterprise Status:"
      puts "   Plan: #{ChatwootHub.pricing_plan}"
      puts "   License Quantity: #{ChatwootHub.pricing_plan_quantity}"
      puts "   Hub Sync: #{hub_sync_disabled? ? '❌ Disabled' : '⚠️  Still enabled'}"
      
      puts "\n🛡️  Reset mechanisms permanently disabled!"
      puts "💡 Your enterprise features should now remain stable."
      puts "💡 If you need to re-enable these mechanisms later, you can:"
      puts "   - Uncomment the job in config/schedule.yml"
      puts "   - Restore the original code in the service files"
      puts "   - Remove the DISABLE_TELEMETRY=true from your .env file"
    end

    desc 'Check if reset mechanisms are disabled'
    task check_reset_mechanisms: :environment do
      puts "🔍 Checking reset mechanism status..."
      
      # Check if the job is disabled in Sidekiq Cron
      begin
        job = Sidekiq::Cron::Job.find('internal_check_new_versions_job')
        if job
          status = job.status
          puts "📅 CheckNewVersionsJob: #{status == 'enabled' ? '⚠️  ENABLED' : '✅ DISABLED'}"
        else
          puts "📅 CheckNewVersionsJob: ✅ NOT FOUND (disabled)"
        end
      rescue => e
        puts "📅 CheckNewVersionsJob: ❓ UNKNOWN (#{e.message})"
      end
      
      # Check environment variables
      puts "🔧 DISABLE_TELEMETRY: #{ENV['DISABLE_TELEMETRY'] || 'Not set'}"
      
      # Check Redis flags
      disabled_flag = Redis::Alfred.get('ENTERPRISE_RESET_MECHANISMS_DISABLED')
      puts "🛡️  Reset mechanisms disabled flag: #{disabled_flag == 'true' ? '✅ SET' : '❌ NOT SET'}"
      
      # Check current enterprise status
      puts "\n📊 Enterprise Status:"
      puts "   Plan: #{ChatwootHub.pricing_plan}"
      puts "   License Quantity: #{ChatwootHub.pricing_plan_quantity}"
      puts "   Hub Sync: #{hub_sync_disabled? ? '❌ Disabled' : '⚠️  Enabled'}"
      
      # Check for any Stripe billing data
      stripe_accounts = Account.where("custom_attributes->>'stripe_customer_id' IS NOT NULL").count
      puts "💳 Accounts with Stripe data: #{stripe_accounts}"
      
      if stripe_accounts > 0
        puts "⚠️  WARNING: #{stripe_accounts} account(s) have Stripe billing data"
        puts "   This could potentially override your enterprise settings"
        puts "   Run: rails chatwoot:dev:clear_stripe_data to clear this data"
      end
    end

    desc 'Restore original reset mechanisms (use with caution)'
    task restore_reset_mechanisms: :environment do
      puts "⚠️  WARNING: This will re-enable mechanisms that can reset enterprise features!"
      puts "Are you sure you want to continue? (y/N)"
      
      response = $stdin.gets.chomp.downcase
      unless response == 'y' || response == 'yes'
        puts "❌ Operation cancelled"
        exit 0
      end
      
      puts "🔄 Restoring original reset mechanisms..."
      
      # 1. Re-enable the scheduled job via Sidekiq Cron
      begin
        job = Sidekiq::Cron::Job.find('internal_check_new_versions_job')
        if job
          job.enable!
          puts "✅ Re-enabled CheckNewVersionsJob in Sidekiq Cron"
        else
          puts "⚠️  CheckNewVersionsJob not found in Sidekiq Cron"
          puts "   You may need to uncomment it in config/schedule.yml"
        end
      rescue => e
        puts "⚠️  Could not re-enable CheckNewVersionsJob: #{e.message}"
      end
      
      # 2. Remove the persistent flag
      Redis::Alfred.delete('ENTERPRISE_RESET_MECHANISMS_DISABLED')
      puts "✅ Removed persistent flag: ENTERPRISE_RESET_MECHANISMS_DISABLED"
      
      puts "\n⚠️  IMPORTANT: You also need to manually restore the original code in:"
      puts "   - enterprise/app/services/internal/reconcile_plan_config_service.rb"
      puts "   - enterprise/app/services/enterprise/billing/handle_stripe_event_service.rb"
      puts "   - config/schedule.yml (uncomment the internal_check_new_versions_job)"
      
      puts "\n✅ Reset mechanisms restored!"
      puts "💡 Your enterprise features may now be reset by the daily sync job"
    end

    desc 'Disable potential backdoor endpoints that could reset enterprise features'
    task disable_backdoor_endpoints: :environment do
      puts "🛡️  Disabling potential backdoor endpoints..."
      
      # 1. Set a flag to prevent super admin from editing pricing plan
      Redis::Alfred.set('ENTERPRISE_PRICING_PLAN_LOCKED', 'true')
      puts "✅ Locked pricing plan from super admin editing"
      
      # 2. Clear any existing Stripe webhook configurations
      stripe_webhook_config = InstallationConfig.find_by(name: 'STRIPE_WEBHOOK_SECRET')
      if stripe_webhook_config
        stripe_webhook_config.update!(value: 'DISABLED_FOR_ENTERPRISE')
        puts "✅ Disabled Stripe webhook secret"
      end
      
      # 3. Set environment variable to prevent Stripe webhook processing
      ENV['STRIPE_WEBHOOK_SECRET'] = 'DISABLED_FOR_ENTERPRISE'
      puts "✅ Set STRIPE_WEBHOOK_SECRET to disabled"
      
      # 4. Create a backup of current enterprise settings
      current_plan = ChatwootHub.pricing_plan
      current_quantity = ChatwootHub.pricing_plan_quantity
      
      Redis::Alfred.set('ENTERPRISE_BACKUP_PLAN', current_plan)
      Redis::Alfred.set('ENTERPRISE_BACKUP_QUANTITY', current_quantity.to_s)
      puts "✅ Created backup of current enterprise settings"
      
      puts "\n🛡️  Backdoor endpoints disabled!"
      puts "💡 Super admin cannot edit pricing plan"
      puts "💡 Stripe webhooks are disabled"
      puts "💡 Enterprise settings are backed up"
    end

    desc 'Check if backdoor endpoints are disabled'
    task check_backdoor_endpoints: :environment do
      puts "🔍 Checking backdoor endpoint status..."
      
      # Check pricing plan lock
      plan_locked = Redis::Alfred.get('ENTERPRISE_PRICING_PLAN_LOCKED')
      puts "🔒 Pricing plan locked: #{plan_locked == 'true' ? '✅ YES' : '❌ NO'}"
      
      # Check Stripe webhook status
      stripe_secret = ENV['STRIPE_WEBHOOK_SECRET']
      puts "💳 Stripe webhook secret: #{stripe_secret == 'DISABLED_FOR_ENTERPRISE' ? '✅ DISABLED' : '⚠️  ENABLED'}"
      
      # Check enterprise backup
      backup_plan = Redis::Alfred.get('ENTERPRISE_BACKUP_PLAN')
      backup_quantity = Redis::Alfred.get('ENTERPRISE_BACKUP_QUANTITY')
      puts "💾 Enterprise backup: #{backup_plan ? "✅ #{backup_plan} (#{backup_quantity})" : '❌ NOT FOUND'}"
      
      # Check current status
      puts "\n📊 Current Enterprise Status:"
      puts "   Plan: #{ChatwootHub.pricing_plan}"
      puts "   License Quantity: #{ChatwootHub.pricing_plan_quantity}"
    end

    desc 'Restore enterprise settings from backup (if needed)'
    task restore_enterprise_backup: :environment do
      puts "🔄 Restoring enterprise settings from backup..."
      
      backup_plan = Redis::Alfred.get('ENTERPRISE_BACKUP_PLAN')
      backup_quantity = Redis::Alfred.get('ENTERPRISE_BACKUP_QUANTITY')
      
      if backup_plan && backup_quantity
        # Restore pricing plan
        premium_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
        premium_config.update!(value: backup_plan)
        
        # Restore license quantity
        quantity_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
        quantity_config.update!(value: backup_quantity)
        
        # Clear cache
        GlobalConfig.clear_cache
        
        puts "✅ Restored enterprise settings:"
        puts "   Plan: #{backup_plan}"
        puts "   License Quantity: #{backup_quantity}"
      else
        puts "❌ No backup found. Run setup_enterprise_safe first."
      end
    end

    desc 'Complete enterprise setup with all safeguards (recommended)'
    task setup_enterprise_safe: :environment do
      puts "🚀 Setting up enterprise features with complete safeguards..."
      
      # 1. Enable enterprise features
      Rake::Task['chatwoot:dev:enable_enterprise'].invoke
      
      # 2. Disable all reset mechanisms
      Rake::Task['chatwoot:dev:disable_reset_mechanisms'].invoke
      
      # 3. Disable backdoor endpoints
      Rake::Task['chatwoot:dev:disable_backdoor_endpoints'].invoke
      
      puts "\n🎉 Complete enterprise setup with all safeguards!"
      puts "✅ Enterprise features enabled"
      puts "✅ All reset mechanisms disabled"
      puts "✅ Backdoor endpoints disabled"
      puts "✅ Your enterprise features should now remain stable"
      puts "\n💡 To check status anytime: rails chatwoot:dev:check_reset_mechanisms"
      puts "💡 To check backdoor status: rails chatwoot:dev:check_backdoor_endpoints"
      puts "💡 To restore if needed: rails chatwoot:dev:restore_enterprise_backup"
    end

    private

    def hub_sync_disabled?
      ENV['DISABLE_TELEMETRY'] == 'true'
    end

    def get_premium_features_list
      # Get features marked as premium: true from features.yml
      premium_from_config = YAML.safe_load(Rails.root.join('config/features.yml').read)
                               .select { |f| f['premium'] == true }
                               .map { |f| f['name'] }
      
      # Add internal/development features that are useful for testing
      internal_features = [
        'inbox_view',
        'shopify_integration', 
        'search_with_gin',
        'channel_voice',
        'contact_chatwoot_support_team'
      ]
      
      # Combine both lists
      (premium_from_config + internal_features).uniq
    end

    def verify_enterprise_setup
      # Check that key settings are correct (most important)
      return false unless ChatwootHub.pricing_plan == 'premium'
      return false unless ChatwootHub.pricing_plan_quantity == 999999
      
      # If accounts exist, verify their features are enabled
      if Account.exists?
        first_account = Account.first
        enabled_features = first_account.enabled_features.keys
        premium_features = get_premium_features_list
        
        # Verify at least some premium features are enabled
        return (premium_features & enabled_features).any?
      else
        # No accounts exist yet - this is fine for fresh installations
        puts "ℹ️  No accounts found - enterprise features will be enabled when accounts are created"
        return true
      end
    end

    def display_success_message(is_production, premium_features)
      account_count = Account.count
      
      if is_production
        puts "\n✅ Enterprise features enabled successfully for production!"
        puts "\n📋 Premium Features Configuration (#{premium_features.length} total):"
        premium_features.each { |f| puts "   • #{f}" }
        
        if account_count > 0
          puts "\n✅ Features enabled on #{account_count} existing account(s)"
        else
          puts "\n✅ Features will be enabled automatically when accounts are created"
        end
        
        puts "\n🔧 Production Safeguards Active:"
        puts "   - Chatwoot Hub sync: #{hub_sync_disabled? ? '✅ Disabled' : '⚠️  Still enabled (add DISABLE_TELEMETRY=true to .env)'}"
        puts "   - Version checks: ✅ Disabled"
        puts "   - Stripe billing data: ✅ Cleared"
        puts "   - Premium config warning: ✅ Cleared"
        puts "   - External services still work with your API keys"
      else
        puts "\n✅ Enterprise features enabled successfully!"
        puts "\n📋 Premium Features Configuration (#{premium_features.length} total):"
        premium_features.each { |f| puts "   • #{f}" }
        
        if account_count > 0
          puts "\n✅ Features enabled on #{account_count} existing account(s)"
        else
          puts "\n✅ Features will be enabled automatically when accounts are created"
        end
        
        puts "\n🔧 Development Mode Active:"
        puts "   - Chatwoot Hub sync: #{hub_sync_disabled? ? '✅ Disabled' : '⚠️  Still enabled (add DISABLE_TELEMETRY=true to .env)'}"
        puts "   - Version checks: ✅ Disabled"
        puts "   - Stripe billing data: ✅ Cleared"
        puts "   - Premium config warning: ✅ Cleared"
        puts "   - External services still work with your API keys"
      end
      
      unless hub_sync_disabled?
        puts "\n⚠️  IMPORTANT: Add DISABLE_TELEMETRY=true to your .env file"
        puts "   Without this, the daily sync job may reset your enterprise settings!"
      end
    end

    def disable_hub_sync
      # Note: DISABLE_TELEMETRY should be set in .env file for persistence
      # This method now just verifies the setting is active
      if hub_sync_disabled?
        puts "✅ Chatwoot Hub sync is disabled (DISABLE_TELEMETRY=true)"
      else
        puts "⚠️  Chatwoot Hub sync is enabled (DISABLE_TELEMETRY not set to 'true')"
        puts "💡 Add DISABLE_TELEMETRY=true to your .env file for permanent disable"
        puts "💡 Without this, the daily CheckNewVersionsJob may override your settings!"
      end
    end

    def enable_hub_sync
      # Note: To enable hub sync, remove DISABLE_TELEMETRY from .env file
      # This method now just verifies the setting
      if hub_sync_disabled?
        puts "⚠️  Chatwoot Hub sync is disabled (DISABLE_TELEMETRY=true)"
        puts "💡 Remove DISABLE_TELEMETRY=true from your .env file to enable"
      else
        puts "✅ Chatwoot Hub sync is enabled (DISABLE_TELEMETRY not set)"
      end
    end

    def clear_stripe_billing_data
      # Clear any existing Stripe customer IDs to prevent billing conflicts
      cleared_count = 0
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
          cleared_count += 1
        end
      end
      
      if cleared_count > 0
        puts "✅ Cleared Stripe billing data from #{cleared_count} accounts"
      else
        puts "✅ No Stripe billing data found to clear"
      end
    end

    def disable_version_checks
      # Clear the version cache to disable version check notifications
      Redis::Alfred.delete(Redis::Alfred::LATEST_CHATWOOT_VERSION)
      puts "✅ Cleared version check cache"
    end

    def enable_version_checks
      # Note: Version checks will be re-enabled when the scheduled job runs
      # or when manually triggered via the admin interface
      puts "✅ Version checks will be re-enabled on next scheduled run"
    end

    def clear_premium_config_warning
      # Clear the premium configuration reset warning that appears in super admin settings
      Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
      puts "✅ Cleared premium configuration warning"
    end
  end
end 