# frozen_string_literal: true

namespace :chatwoot do
  namespace :dev do
    desc 'Enable all enterprise features for development'
    task enable_enterprise: :environment do
      puts "🚀 Enabling enterprise features for development..."
      
      # Check if enterprise directory exists
      unless ChatwootApp.enterprise?
        puts "❌ Enterprise directory not found. Please ensure you have the enterprise edition."
        exit 1
      end
      
      # Set premium plan
      premium_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
      premium_config.update!(value: 'premium')
      puts "✅ Set pricing plan to: premium"
      
      # Set unlimited licenses
      quantity_config = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
      quantity_config.update!(value: '999999')
      puts "✅ Set license quantity to: 999999"
      
      # Disable Chatwoot Hub sync (this actually works)
      disable_hub_sync
      
      # Disable version checks
      disable_version_checks
      
      # Clear Stripe billing data to prevent conflicts
      clear_stripe_billing_data
      
      # Enable all features for existing accounts
      puts "🔄 Enabling features for existing accounts..."
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
        print "."
      end
      puts ""
      
      # Verify configuration
      puts "\n📊 Current Configuration:"
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
      
      puts "\n✅ Enterprise features enabled successfully!"
      puts "💡 You can now test all premium features in your development environment."
      puts "⚠️  Remember: This is for development only. Use proper licenses in production."
      puts "\n🔧 Development Mode Active:"
      puts "   - Chatwoot Hub sync disabled (prevents license conflicts)"
      puts "   - Version checks disabled (prevents update notifications)"
      puts "   - Stripe billing data cleared (prevents billing conflicts)"
      puts "   - External services still work with your API keys"
    end

    desc 'Disable enterprise features (reset to community)'
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
      
      # Disable all premium features for existing accounts
      puts "🔄 Disabling premium features for existing accounts..."
      Account.find_each do |account|
        account.disable_features!(
          'captain_integration',
          'custom_branding',
          'audit_logs',
          'disable_branding',
          'agent_capacity',
          'sla',
          'custom_roles'
        )
        print "."
      end
      puts ""
      
      puts "\n✅ Enterprise features disabled successfully!"
      puts "📊 Current Configuration:"
      puts "   Plan: #{ChatwootHub.pricing_plan}"
      puts "   License Quantity: #{ChatwootHub.pricing_plan_quantity}"
    end

    desc 'Disable Chatwoot Hub sync for development'
    task disable_hub_sync: :environment do
      disable_hub_sync
      puts "✅ Chatwoot Hub sync disabled for development"
    end

    desc 'Enable Chatwoot Hub sync'
    task enable_hub_sync: :environment do
      enable_hub_sync
      puts "✅ Chatwoot Hub sync enabled"
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
      
      puts "Enterprise Directory: #{ChatwootApp.enterprise? ? '✅ Present' : '❌ Not Found'}"
      puts "Current Plan: #{ChatwootHub.pricing_plan}"
      puts "License Quantity: #{ChatwootHub.pricing_plan_quantity}"
      puts "Environment: #{Rails.env}"
      
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
      
      if feature_name.blank?
        puts "❌ Please specify a feature name: rails chatwoot:dev:enable_feature[feature_name]"
        puts "Available features: captain_integration, custom_branding, audit_logs, disable_branding, agent_capacity, sla, custom_roles"
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
      
      if feature_name.blank?
        puts "❌ Please specify a feature name: rails chatwoot:dev:disable_feature[feature_name]"
        puts "Available features: captain_integration, custom_branding, audit_logs, disable_branding, agent_capacity, sla, custom_roles"
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
      # Set environment variable to disable telemetry (this actually works)
      ENV['DISABLE_TELEMETRY'] = 'true'
      
      # Create or update installation config to disable hub sync
      hub_sync_config = InstallationConfig.find_or_create_by(name: 'DISABLE_HUB_SYNC')
      hub_sync_config.update!(value: 'true')
      
      puts "✅ Disabled Chatwoot Hub sync"
    end

    def enable_hub_sync
      # Remove environment variable
      ENV.delete('DISABLE_TELEMETRY')
      
      # Update installation config to enable hub sync
      hub_sync_config = InstallationConfig.find_or_create_by(name: 'DISABLE_HUB_SYNC')
      hub_sync_config.update!(value: 'false')
      
      puts "✅ Enabled Chatwoot Hub sync"
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