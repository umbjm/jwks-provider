# jwks-provider

A Rails gem for managing **JWKS (JSON Web Key Set)** operations. It generates EC (prime256v1) key pairs for **staging** and **production** environments, provides a `JwksProvider::JsonWebKey` module that can be included directly in controllers, and automatically wires up the `/.well-known/jwks` endpoint.

Built on top of [`jwt`](https://rubygems.org/gems/jwt) and [`jose`](https://rubygems.org/gems/jose), both of which are automatically required in your app once this gem is loaded — no need to add them to your app's `Gemfile` separately.

## Installation

Add to your application's `Gemfile`:

```ruby
gem "jwks-provider", git: "https://github.com/umbjm/jwks-provider"
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

The generator will prompt for an **application name** used to build KID aliases:

```
Enter application name for KID aliases (e.g. my-app): my-app
```

You can also pass it directly to skip the prompt:

```bash
rails generate jwks_provider:install --app-name my-app
```

The app name is stored in an initializer and used to build KID aliases at runtime:

```ruby
"alias/my-app-id-token-stg-signing-key-kms-asymmetric-key"
"alias/my-app-id-token-prd-signing-key-kms-asymmetric-key"
```

This single command will:

1. **Generate EC key pairs** — creates `config/keys/enc_key_stg.pem`, `config/keys/sig_key_stg.pem`, `config/keys/enc_key_prd.pem`, and `config/keys/sig_key_prd.pem`.
2. **Create `config/initializers/jwks_provider.rb`** — sets `JwksProvider.app_name` with your app name.
3. **Copy `app/controllers/jwks_controller.rb`** — serves the public JWKS payload.
4. **Inject route** — adds `get ".well-known/jwks", to: "jwks#index"` into `config/routes.rb`.

## Generated Files

### `config/keys/`

| File | Description |
|------|-------------|
| `enc_key_stg.pem` | EC prime256v1 private key for staging |
| `sig_key_stg.pem` | EC prime256v1 public key for staging |
| `enc_key_prd.pem` | EC prime256v1 private key for production |
| `sig_key_prd.pem` | EC prime256v1 public key for production |

### `config/initializers/jwks_provider.rb`

Sets the application name used in KID aliases:

```ruby
JwksProvider.app_name = "my-app"
```

### `app/controllers/jwks_controller.rb`

Serves the public key set at `/.well-known/jwks`:

```ruby
class JwksController < ApplicationController
  include JwksProvider::JsonWebKey

  def index
    render json: keys_set
  end
end
```

## Usage

Include `JwksProvider::JsonWebKey` in any controller that needs to expose JWKS:

```ruby
class ApiController < ApplicationController
  include JwksProvider::JsonWebKey
end
```

### Key loading

- **Signing key** — read from `config/keys/sig_key_#{kid_alias}.pem` (e.g. `sig_key_stg.pem` in non-production, `sig_key_prd.pem` in production).
- **Encryption key** — read from the `ENC_KEY` environment variable. Make sure to set this in your environment:

```bash
export ENC_KEY="-----BEGIN EC PRIVATE KEY-----\n..."
```

## Development

```bash
bin/setup      # install dependencies
rake spec      # run tests
bin/console    # interactive prompt
```

To release a new version, update `lib/jwks_provider/version.rb` and run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umbjm/jwks-provider.
