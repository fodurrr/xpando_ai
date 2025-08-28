# Deployment Architecture

## Deployment Strategy

**Frontend Deployment:**
- **Platform:** Fly.io (Phoenix app with LiveView)
- **Build Command:** `mix assets.deploy && mix phx.digest`
- **Output Directory:** `_build/prod/rel/xpando_web`
- **CDN/Edge:** Fly.io edge locations

**Backend Deployment:**
- **Platform:** Fly.io clustered deployment
- **Build Command:** `mix release`
- **Deployment Method:** Docker containers with distributed Erlang

## CI/CD Pipeline

### GitHub Actions with DevBox Integration

```yaml
# .github/workflows/deploy.yaml
name: Deploy to Production

on:
  push:
    branches: [main]

env:
  FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
  MIX_ENV: prod

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install DevBox
        uses: jetpack-io/devbox-install-action@v0.9.0
      
      - name: Setup environment with DevBox
        run: devbox run -- echo "DevBox environment loaded"
      
      - name: Install dependencies
        run: devbox run -- mix deps.get
      
      - name: Install pnpm dependencies
        run: devbox run -- bash -c "cd apps/xpando_web/assets && pnpm install"
      
      - name: Run tests
        run: devbox run -- mix test
      
      - name: Check formatting
        run: devbox run -- mix format --check-formatted
      
      - name: Run Dialyzer
        run: devbox run -- mix dialyzer

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flyctl
        uses: superfly/flyctl-actions/setup-flyctl@master
      
      - name: Deploy to Fly.io
        run: |
          flyctl deploy --remote-only \
            --config fly.production.toml \
            --strategy rolling
```

## Docker Configuration with DevBox

### Production Dockerfile
```dockerfile
# Dockerfile
FROM jetpack/devbox:latest AS builder

WORKDIR /app

# Copy DevBox config
COPY devbox.json devbox.lock ./

# Initialize DevBox environment
RUN devbox run -- echo "DevBox initialized"

# Copy source code
COPY . .

# Install dependencies and build release
RUN devbox run -- mix deps.get --only prod
RUN devbox run -- mix compile
RUN devbox run -- bash -c "cd apps/xpando_web/assets && pnpm install --frozen-lockfile && pnpm run build"
RUN devbox run -- mix phx.digest
RUN devbox run -- mix release

# Runtime stage
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
  libssl1.1 \
  libsctp1 \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy release from builder
COPY --from=builder /app/_build/prod/rel/xpando ./

ENV MIX_ENV=prod

CMD ["bin/xpando", "start"]
```

## Environments

| Environment | Frontend URL | Backend URL | Purpose |
|------------|--------------|-------------|---------|
| Development | http://localhost:4000 | http://localhost:4000/api | Local development with DevBox |
| Staging | https://staging.xpando.ai | https://staging-api.xpando.ai | Pre-production testing |
| Production | https://xpando.ai | https://api.xpando.ai | Live environment |