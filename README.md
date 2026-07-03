# jwks-provider

A Rails gem for managing **JWKS (JSON Web Key Set)** operations. It generates EC (prime256v1) key pairs for **staging** and **production** environments, exposes a `JsonWebKey` controller concern, and automatically wires up the `/.well-known/jwks` endpoint.

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

The app name is embedded into the generated `JsonWebKey` concern:

```ruby
"alias/my-app-id-token-stg-signing-key-kms-asymmetric-key"
"alias/my-app-id-token-prd-signing-key-kms-asymmetric-key"
```

This single command will:

1. **Copy `app/controllers/concerns/json_web_key.rb`** — a ready-to-include controller concern with your app name baked in.
2. **Copy `app/controllers/jwks_controller.rb`** — serves the public JWKS payload.
3. **Inject route** — adds `get ".well-known/jwks", to: "jwks#index"` into `config/routes.rb`.

## Generated Files

### `config/keys/`

| File | Description |
|------|-------------|
| `staging/enc_key.pem`    | EC prime256v1 private key for staging |
| `staging/sig_key.pem`     | EC prime256v1 public key for staging |
| `production/enc_key.pem` | EC prime256v1 private key for production |
| `production/sig_key.pem`  | EC prime256v1 public key for production |

### `app/controllers/concerns/json_web_key.rb`

Include this concern in any controller that needs to verify JWTs:

```ruby
class ApiController < ApplicationController
  include JsonWebKey
end
```

### `app/controllers/jwks_controller.rb`

Serves the public key set at `/.well-known/jwks`. No additional configuration needed.

## Development

```bash
bin/setup      # install dependencies
rake spec      # run tests
bin/console    # interactive prompt
```

To release a new version, update `lib/jwks_provider/version.rb` and run `bundle exec rake release`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/umbjm/jwks-provider.
