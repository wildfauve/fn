# Fn

Fn is a collection of Higher Level functions implemented with simple lambdas and currying.  And why not.  Its not meant to be complete, not very sophisticated.  Rather is a "play with functions" project.  Its split into 2 parts:

+ Common higher-level functions, such as `compose` or `flat_map`
+ More specialised authorisation testing functions, designed for adding authorisation tests to your code.  

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fn'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fn

## Usage

### General Higher Level Functions

### Authorisation Functions

The `#authorise` function takes the following arguments:
+ enforcer.  A function that will be given the result (wrapped in a Monad) of the authorisation policies and can decide what to do with it.  There are 2 defined;
  - `nil_enforcer`, which is an identity function and return the input value
  - `auth_error_raise_enforcer`, which takes 2 curried arguments; an exception to raise and the value
+ policies.  Each policy is a function that takes the context and returns either a Success Monad or a Failure Monad wrapping the context.  Thats it.
+ data context.  The data context is the input into the authorisation policies.  Its provided as the last argument so that the remainder (basically the configuration) can be partially applied, and then the partially applied function can be passed around and given state when you want.

The simplist policy (and perhaps the most useless) would look like this:

```ruby
-> ctx { M.Success(ctx) }
```

Takes in the context and returns it wrapped in a success.  Nice!

Lets have a look at the supplied Slack Token policy.  The policy looks like this;

```ruby
-> expected_token, ctx { Fn.either.(Fn.tests.(Fn.all?, slack_token_tests(expected_token)), Fn.success, Fn.failure ).(ctx) }.curry
```
What this is doing is, taking the expected Slack token, a context that (somewhere) will contain a provided Slack token, running all the tests defined by `slack_token_tests`, and if that all pass, return the context wrapped in a Success Monad.  The significant test is

```ruby
-> t, ctx { ctx[:token] == t }.curry
```

where `t` is the expected token, and the context (`ctx`) is a hash containing a key `token` which must equal the expected token.

So, to set this up, to be partially applied, we can start by defining the policy execution functions.

```ruby
policy_fn = Afn.authorise.(Afn.auth_error_raise_enforcer.(StandardError)).([Fn::Afn.slack_token_policy.("slack_token")])

# then at sometime later, perhaps when we have the token, we can then check it by applying the last argument, the ctx
result = policy_fn.({token: "slack_token"})  # => Success({token: "slack_token"})
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/fn. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fn project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/fn/blob/master/CODE_OF_CONDUCT.md).
