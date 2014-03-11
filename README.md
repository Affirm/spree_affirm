SpreeAffirm
===========

Introduction goes here.

Installation
------------

1. Add this extension to your Gemfile with this line:

    gem 'spree_affirm', :github => "affirm/spree_affirm"

2. Install the gem using Bundler:

        bundle install

3. Copy & run migrations

        bundle exec rails g spree_affirm:install

4. Restart your server

Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_affirm/factories'
```

Copyright (c) 2014 [name of extension creator], released under the New BSD License
