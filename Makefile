# Variables
APP_NAME := chatwoot
RAILS_ENV ?= development

# Targets
setup:
	gem install bundler
	bundle install
	pnpm install

db_create:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:create

db_migrate:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:migrate

db_seed:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:seed

db_reset:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:reset

db:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails db:chatwoot_prepare

console:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails console

server:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails server -b 0.0.0.0 -p 3000

# Enterprise Setup Targets
enterprise_enable:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails chatwoot:dev:enable_enterprise

enterprise_disable:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails chatwoot:dev:disable_enterprise

enterprise_status:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails chatwoot:dev:show_enterprise_status

enterprise_features:
	RAILS_ENV=$(RAILS_ENV) bundle exec rails chatwoot:dev:list_premium_features

burn:
	bundle && pnpm install

run:
	@if [ -f ./.overmind.sock ]; then \
		echo "Overmind is already running. Use 'make force_run' to start a new instance."; \
	else \
		overmind start -f Procfile.dev; \
	fi

run_production:
	@if [ -f ./.overmind.sock ]; then \
		echo "Overmind is already running. Use 'make force_run_production' to start a new instance."; \
	else \
		RAILS_ENV=production PORT=3000 overmind start -f Procfile; \
	fi

force_run:
	rm -f ./.overmind.sock
	rm -f tmp/pids/*.pid
	overmind start -f Procfile.dev

force_run_production:
	rm -f ./.overmind.sock
	rm -f tmp/pids/*.pid
	RAILS_ENV=production PORT=3000 overmind start -f Procfile

force_run_tunnel:
	lsof -ti:3000 | xargs kill -9 2>/dev/null || true
	rm -f ./.overmind.sock
	rm -f tmp/pids/*.pid
	overmind start -f Procfile.tunnel

debug:
	overmind connect backend

debug_worker:
	overmind connect worker

docker: 
	docker build -t $(APP_NAME) -f ./docker/Dockerfile .

.PHONY: setup db_create db_migrate db_seed db_reset db console server burn docker run run_production force_run force_run_production force_run_tunnel debug debug_worker enterprise_enable enterprise_disable enterprise_status enterprise_features
