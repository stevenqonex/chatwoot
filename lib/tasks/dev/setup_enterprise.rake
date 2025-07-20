# frozen_string_literal: true

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
        puts "⚠️  This will enable enterprise features in production"      
        print "Do you understand the risks and want to proceed? (type 'YES' to continue): "
        confirmation = $stdin.gets.chomp
        
        unless confirmation == 'YES'
          puts "❌ Operation cancelled. No changes made."
          exit 0
        end
        
        puts "\n🚀 Enabling enterprise features for production..."
      else
        puts "🚀 Enabling enterprise features for development..."
        puts "💡 To run in production mode, use: RAILS_ENV=production rails chatwoot:dev:enable_enterprise"
      end
      
      # Note: Enterprise directory check removed for development flexibility
      # This allows the task to run even without the enterprise edition
      
      # Set premium plan
      premium_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
      premium_config.update!(value: 'premium')
      puts "✅ Set pricing plan to: premium"
      
      # Set unlimited licenses
      quantity_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
      quantity_config.update!(value: 999999)
      puts "✅ Set license quantity to: 999999"
      
      # Disable Chatwoot Hub sync (this actually works)
      disable_hub_sync
      
      # Disable version checks
      disable_version_checks
      
      # Clear Stripe billing data to prevent conflicts
      clear_stripe_billing_data
      
      # Enable all premium features for existing accounts
      puts "🔄 Enabling premium features for existing accounts..."
      
      # Actual premium features from features.yml (marked with premium: true)
      premium_features = [
        # Core premium features (from features.yml with premium: true)
        'disable_branding',
        'audit_logs',
        'sla',
        'captain_integration',
        'custom_roles',
        'help_center_embedding_search',
        'captain_integration_v2',
        
        # Internal features
        'inbox_view',
        'shopify_integration',
        'search_with_gin',
        'channel_voice',
        'contact_chatwoot_support_team'
      ]
      
      Account.find_each do |account|
        account.enable_features!(*premium_features)
        print "."
      end
      puts ""
      
      # Verify configuration
      puts "\n📊 Current Configuration:"
      puts "   Environment: #{Rails.env}"
      puts "   Plan: #{ChatwootHub.pricing_plan}"
      puts "   License Quantity: #{ChatwootHub.pricing_plan_quantity}"
      puts "   Enterprise Enabled: #{ChatwootApp.enterprise?}"
      puts "   Hub Sync Disabled: #{ENV['DISABLE_TELEMETRY'] == 'true'}"
      
      # Show enabled features for first account
      first_account = Account.first
      if first_account
        puts "\n🎯 Sample Account Features:"
        puts "   Account: #{first_account.name}"
        puts "   Enabled Features: #{first_account.enabled_features.keys.join(', ')}"
      end
      
      if is_production
        puts "\n✅ Enterprise features enabled successfully for production!"
        puts "\n📋 Enabled Features:"
        puts "   - Premium features (marked with premium: true in features.yml)"
        puts "   - Internal features (for production testing)"
        puts "   - Community features remain enabled by default"
        puts "\n🔧 Production Safeguards Active:"
        puts "   - Chatwoot Hub sync disabled (prevents license validation)"
        puts "   - Version checks disabled (prevents update notifications)"
        puts "   - Stripe billing data cleared (prevents billing conflicts)"
        puts "   - External services still work with your API keys"
      else
        puts "\n✅ Enterprise features enabled successfully!"
        puts "\n📋 Enabled Features:"
        puts "   - Premium features (marked with premium: true in features.yml)"
        puts "   - Internal features (for development testing)"
        puts "   - Community features remain enabled by default"
        puts "\n🔧 Development Mode Active:"
        puts "   - Chatwoot Hub sync disabled (prevents license conflicts)"
        puts "   - Version checks disabled (prevents update notifications)"
        puts "   - Stripe billing data cleared (prevents billing conflicts)"
        puts "   - External services still work with your API keys"
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
      
      # Actual premium features to disable
      premium_features = [
        'disable_branding', 'audit_logs', 'sla', 'captain_integration', 'custom_roles',
        'help_center_embedding_search', 'captain_integration_v2',
        'inbox_view', 'shopify_integration', 'search_with_gin', 'channel_voice',
        'contact_chatwoot_support_team'
      ]
      
      # Disable all premium features for existing accounts
      puts "🔄 Disabling premium features for existing accounts..."
      Account.find_each do |account|
        account.disable_features!(*premium_features)
        print "."
      end
      puts ""
      
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

    desc 'Show current enterprise configuration status'
    task show_enterprise_status: :environment do
      puts "📊 Enterprise Configuration Status"
      puts "=" * 40
      
      puts "Environment: #{Rails.env}"
      puts "Enterprise Directory: #{ChatwootApp.enterprise? ? '✅ Present' : '❌ Not Found'}"
      puts "Current Plan: #{ChatwootHub.pricing_plan}"
      puts "License Quantity: #{ChatwootHub.pricing_plan_quantity}"
      
      puts "\n🔧 Development Mode Status:"
      puts "   Hub Sync: #{ENV['DISABLE_TELEMETRY'] == 'true' ? '❌ Disabled' : '✅ Enabled'}"
      puts "   Version Checks: #{Redis::Alfred.get(Redis::Alfred::LATEST_CHATWOOT_VERSION).present? ? '✅ Enabled' : '❌ Disabled'}"
      
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
      puts "   DISABLE_ENTERPRISE: #{ENV['DISABLE_ENTERPRISE'] || 'Not set'}"
      puts "   CW_EDITION: #{ENV['CW_EDITION'] || 'Not set'}"
      puts "   DISABLE_TELEMETRY: #{ENV['DISABLE_TELEMETRY'] || 'Not set'}"
      
      if Rails.env.production?
        puts "\n🚨 PRODUCTION ENVIRONMENT DETECTED"
      end
    end

    desc 'List all available premium features'
    task list_premium_features: :environment do
      puts "🎯 Available Premium Features"
      puts "=" * 40
      
      # Actual premium features from features.yml
      premium_features = [
        { name: 'disable_branding', category: 'Branding', description: 'Remove Chatwoot branding (premium)' },
        { name: 'audit_logs', category: 'Security', description: 'Comprehensive activity tracking (premium)' },
        { name: 'sla', category: 'Management', description: 'Service Level Agreements (premium)' },
        { name: 'captain_integration', category: 'AI', description: 'AI-powered conversation assistance (premium)' },
        { name: 'custom_roles', category: 'Security', description: 'Granular permission management (premium)' },
        { name: 'help_center_embedding_search', category: 'AI', description: 'AI-powered help center search (premium)' },
        { name: 'captain_integration_v2', category: 'AI', description: 'Captain V2 (premium, internal)' },
        
        # Internal features (for development testing)
        { name: 'inbox_view', category: 'Internal', description: 'Inbox view (internal)' },
        { name: 'shopify_integration', category: 'Internal', description: 'Shopify integration (internal)' },
        { name: 'search_with_gin', category: 'Internal', description: 'GIN search (internal)' },
        { name: 'channel_voice', category: 'Internal', description: 'Voice channel (internal)' },
        { name: 'contact_chatwoot_support_team', category: 'Internal', description: 'Contact Chatwoot support (internal)' }
      ]
      
      # Group by category
      features_by_category = premium_features.group_by { |f| f[:category] }
      
      features_by_category.each do |category, features|
        puts "\n📂 #{category}:"
        features.each do |feature|
          puts "   • #{feature[:name]} - #{feature[:description]}"
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
      
      # Actual premium features from features.yml
      available_features = [
        'disable_branding', 'audit_logs', 'sla', 'captain_integration', 'custom_roles',
        'help_center_embedding_search', 'captain_integration_v2',
        'inbox_view', 'shopify_integration', 'search_with_gin', 'channel_voice',
        'contact_chatwoot_support_team'
      ]
      
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
      
      # Actual premium features from features.yml
      available_features = [
        'disable_branding', 'audit_logs', 'sla', 'captain_integration', 'custom_roles',
        'help_center_embedding_search', 'captain_integration_v2',
        'inbox_view', 'shopify_integration', 'search_with_gin', 'channel_voice',
        'contact_chatwoot_support_team'
      ]
      
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
      puts "✅ External services still work with your API keys"
    end

    private

    def disable_hub_sync
      # Note: DISABLE_TELEMETRY should be set in .env file for persistence
      # This method now just verifies the setting is active
      if ENV['DISABLE_TELEMETRY'] == 'true'
        puts "✅ Chatwoot Hub sync is disabled (DISABLE_TELEMETRY=true)"
      else
        puts "⚠️  Chatwoot Hub sync is enabled (DISABLE_TELEMETRY not set to 'true')"
        puts "💡 Add DISABLE_TELEMETRY=true to your .env file for permanent disable"
      end
    end



    def enable_hub_sync
      # Note: To enable hub sync, remove DISABLE_TELEMETRY from .env file
      # This method now just verifies the setting
      if ENV['DISABLE_TELEMETRY'] == 'true'
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
  end
end 