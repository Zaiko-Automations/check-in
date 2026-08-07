source "https://rubygems.org"

ruby "3.4.4"

gem "rails", "~> 7.1.6"
gem "sprockets-rails"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Image processing for Active Storage variants
gem "image_processing", "~> 1.2"

# Authentication (admin panel)
gem "devise"

# Multi-tenant scoping by subdomain
gem "acts_as_tenant"

# QR Code generation (SVG)
gem "rqrcode"

# Background jobs — webhook dispatch to n8n
gem "sidekiq"

# Redis (Sidekiq backend)
gem "redis", ">= 4.0.1"

# AWS S3 / Cloudflare R2 for image storage (public URLs)
gem "aws-sdk-s3", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  gem "web-console"
end

gem "dotenv-rails", "~> 3.2", groups: [:development, :test]
