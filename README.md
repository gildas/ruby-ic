ruby-ic
=======

Interactive Intelligence's Interaction Center API for Ruby

## Installation

Add this line to your application's Gemfile:

    gem 'ruby-ic'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby-ic

## Usage

TODO: Write usage instructions here

## Testing
in the spec folder, write a login.json file that contains the server and the credentials for the test:
```json
{
  "server": "my_cic_server.acme.com",
  "user":   "gildas.cherruel",
  "password: "s3cr3t",
}
```
This file is ignored by git, so there should be no risk of accidentaly give your password to the community!

By default, the connections will be done over https on port 8019. You can change that by adding "scheme" and "port" to the login.json file.

## Contributing

1. Fork it ( https://github.com/gildas/ruby-ic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
