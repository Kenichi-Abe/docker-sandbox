#!/bin/bash
set -euo pipefail

# 公式 redmine entrypoint の最小相当
# REDMINE_DB_MYSQL から database.yml を生成して migrate する

cd /usr/src/redmine

if [ -n "${REDMINE_DB_MYSQL:-}" ]; then
  cat > config/database.yml <<EOF
production:
  adapter: mysql2
  database: ${REDMINE_DB_DATABASE:-redmine}
  host: ${REDMINE_DB_MYSQL}
  port: ${REDMINE_DB_PORT:-3306}
  username: ${REDMINE_DB_USERNAME:-root}
  password: "${REDMINE_DB_PASSWORD:-}"
  encoding: ${REDMINE_DB_ENCODING:-utf8mb4}
EOF
fi

if [ -z "${SECRET_KEY_BASE:-}" ] && [ -z "${RAILS_SECRET:-}" ]; then
  export SECRET_KEY_BASE="$(ruby -e 'require "securerandom"; print SecureRandom.hex(64)')"
fi

if [ -z "${REDMINE_NO_DB_MIGRATE:-}" ]; then
  # DB 起動待ち
  if [ -n "${REDMINE_DB_MYSQL:-}" ]; then
    echo "Waiting for Percona at ${REDMINE_DB_MYSQL}:${REDMINE_DB_PORT:-3306} ..."
    for i in $(seq 1 60); do
      if ruby -e "
        require 'mysql2'
        Mysql2::Client.new(
          host: ENV['REDMINE_DB_MYSQL'],
          port: (ENV['REDMINE_DB_PORT'] || '3306').to_i,
          username: ENV['REDMINE_DB_USERNAME'] || 'root',
          password: ENV['REDMINE_DB_PASSWORD'] || '',
          database: ENV['REDMINE_DB_DATABASE'] || 'redmine'
        )
      " >/dev/null 2>&1; then
        break
      fi
      sleep 2
    done
  fi
  bundle exec rake db:migrate
  if [ -n "${REDMINE_PLUGINS_MIGRATE:-}" ]; then
    bundle exec rake redmine:plugins:migrate
  fi
fi

exec "$@"
