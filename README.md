# jwks-provider

A Rails gem for managing **JWKS (JSON Web Key Set)** operations. It generates RSA private/public key pairs for **staging** and **production** environments, exposes a `JsonWebKey` controller concern, and automatically wires up the `/.well-known/jwks` endpoint.

Built on top of [`jwk`](https://rubygems.org/gems/jwk) and [`jose`](https://rubygems.org/gems/jose).

## Installation

Add to your application's `Gemfile`:

```ruby
gem "jwks-provider"
```

Then run:

```bash
bundle install
```

## Quick Start

Run the install generator once:

```bash
rails generate jwks_provider:install
```

This single command will:

1. **Generate RSA key pairs** — creates `config/keys/staging/private_key.pem`, `config/keys/staging/public_key.pem`, `config/keys/staging/jwks.json` and the equivalent files under `config/keys/production/`.
2. **Add private keys to `.gitignore`** — private key PEM files are never committed.
3. **Copy `app/controllers/concerns/json_web_key.rb`** — a ready-to-include controller concern.
4. **Copy `app/controllers/jwks_controller.rb`** — serves the public JWKS payload.
5. **Inject route** — adds `get ".well-known/jwks", to: "jwks#index"` into `config/routes.rb`.

## Generated Files

### `config/keys/`

| File | Description |
|------|-------------|
| `staging/private_key.pem`    | RSA-2048 private key for staging (gitignored) |
| `staging/public_key.pem`     | RSA-2048 public key for staging |
| `staging/jwks.json`          | Public JWK Set for staging |
| `production/private_key.pem` | RSA-2048 private key for production (gitignored) |
| `production/public_key.pem`  | RSA-2048 public key for production |
| `production/jwks.json`       | Public JWK Set for production |

### `app/controllers/concerns/json_web_key.rb`

Include this concern in any controller that needs to verify JWTs:

```ruby
class ApiController < ApplicationController
  include JsonWebKey

  def show
    verified, payload = verify_jwt(request.headers["Authorization"].split.last)
    render json: payload if verified
  end
end
```

### `app/controllers/jwks_controller.rb`

Serves the public key set at `/.well-known/jwks`. No additional configuration needed.

## Regenerating Keys Only

To regenerate key pairs without re-running the full install:

```bash
rails generate jwks_provider:keys
```

Keys are **not** overwritten if they already exist. Delete the existing PEM files first to force regeneration.

## API

```ruby
# Load a JWK for the current environment
JwksProvider::KeySet.for("production")      # => JOSE::JWK

# Get the public JWKS hash (safe to render as JSON)
JwksProvider::KeySet.public_jwks("staging") # => { keys: [...] }

# Verify a JWT string
verified, payload = JwksProvider::KeySet.verify_jwt(token, Rails.env)
```

## Development

```bash
bin/setup      # install dependencies
rake spec      # run tests
bin/console    # interactive prompt
```

To release a new version, update `lib/jwks/provider/version.rb` and run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umbjm/jwks-provider.
