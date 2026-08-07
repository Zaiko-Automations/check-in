# ════════════════════════════════════════════════════════════════
# Check-in Expresso — Dockerfile (multi-stage build)
# ════════════════════════════════════════════════════════════════

# ── Estágio 1: Builder ──────────────────────────────────────────
FROM ruby:3.3-alpine AS builder

# Dependências de build
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    git \
    curl \
    nodejs \
    npm \
    tzdata \
    yaml-dev

WORKDIR /app

# Gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Código fonte
COPY . .

# Pré-compila assets para produção
RUN RAILS_ENV=production \
    SECRET_KEY_BASE=dummy_key_for_asset_precompile \
    bundle exec rails assets:precompile

# Remove arquivos desnecessários para produção
RUN rm -rf node_modules tmp/cache vendor/bundle spec

# ── Estágio 2: Produção ─────────────────────────────────────────
FROM ruby:3.3-alpine AS production

# Apenas runtime deps
RUN apk add --no-cache \
    postgresql-client \
    tzdata \
    curl \
    libpq

WORKDIR /app

# Copia gems do builder
COPY --from=builder /usr/local/bundle /usr/local/bundle
# Copia app do builder
COPY --from=builder /app .

# Cria usuário não-root
RUN addgroup -g 1000 -S rails && \
    adduser -u 1000 -S rails -G rails && \
    chown -R rails:rails /app

USER rails

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    PORT=3000

EXPOSE 3000

# Healthcheck via /up
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/up || exit 1

CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
