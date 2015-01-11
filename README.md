[![gildas/ruby-ic API Documentation](https://www.omniref.com/github/gildas/ruby-ic.png)](https://www.omniref.com/github/gildas/ruby-ic)

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

## Online Documentation

The online documentation can be found at: http://rubydoc.info/github/gildas/ruby-ic

## Testing
in the spec folder, write a **login.json** file that contains the server and the credentials for the test:
```json
{
  "network":       "192.168.116.\\d{0,3}",
  "application":   "icws rspec test",
  "server":        "my_cic_server.acme.com",
  "user":          "gildas.cherruel",
  "password":      "s3cr3t",
  "workstation":   "7001",
  "remotestation": "gildasmobile",
  "remotenumber":  "0123456789",
  "persistent":    false
}
```
The _workstation_, _remotestation_, _remotenumber_ + _persistent_ keys are used when testing the **Connection** object
with various types of **StationSettings**.

By default, the connections will be done over https on port 8019.
You can change that by adding _scheme_ and _port_ to the **login.json** file.

if you connect to various networks and need to test with different servers (like on a laptop at home or at work),
simply write several **login-my_location.json** files. Make sure the network key matches the network you want to test in.
The Rake tasks will automatically update the login.json link for you.
You can also force the network by providing the network via the environment:

```bash
$ rake network=10.0.0.1
```

All json files in the spec folder are ignored by git,
so there should be no risk of accidentally give your password to the community!

## Contributing

1. Fork it ( https://github.com/gildas/ruby-ic/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
