# GunDog

GunDog is a Tracepoint tool for finding the interface of particular classes
within a given context.

Often times you'd like to refactor a class, but are not sure about what sort of
calls the class may receive.  GunDog sets up special Tracepoint listeners to log
and record code execution metrics on a given class.

## Installation

Add this line to your application's Gemfile:

```ruby gem 'gun_dog' ```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gun_dog

## Usage

To use GunDog find the general area were you'd like to refactor a class.

```
trace = GunDog.trace(MyClassName) do
    some_code_that_executes_your_class
end
```

Trace is a GunDog::TraceReport object that can be saved to JSON (and loaded from
JSON) for analysis.

GunDog is still a pup - here are some upcoming features.

- [ ] TraceReport introspect methods from CallRecords
- [ ] TraceReport pretty reports
- [ ] Trace Multiple Classes with one Dog
- [ ] Inhibit: Generate warnings when methods in a TraceReport are called.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/stephenprater/gun_dog.
