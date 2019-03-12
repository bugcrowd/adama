# Commander Adama

![Adama](https://raw.githubusercontent.com/wiki/bugcrowd/adama/images/adama.jpg)

Adama is a bare bones command pattern library inspired by Collective Idea's [Interactor](https://github.com/collectiveidea/interactor) gem.

Commands are small classes that represent individual units of work. Each command is executed by a client "calling" it. An invoker is a class responsible for the execution of one or more commands.

## Getting Started

Add Commander Adama to your Gemfile and `bundle install`.

```ruby
gem 'adama'
```

## Usage

### Command

To create a command, include the `Adama::Command` module in your command's class definition:

```ruby
class DestroyCylons
  include Adama::Command
end
```

Including the `Adama::Command` module extends the class with the `.call` class method. So you would execute the command like this:

```ruby
DestroyCylons.call(captain: :apollo)
```

The above `.call` method creates an instance of the `DestroyCylons` class, then calls the `#call` instance method. If the `#call` method fails, the `#rollback` method is then called.

At this point our command `DestroyCylons` doesn't do much. As explained above, the `Adama::Command` module has two instance methods: `call` and `rollback`. By default these methods are empty and should be overridden like this:

```ruby
class DestroyCylons
  include Adama::Command

  validate_presence_of :captain

  def call
    got_destroy_cylons(captain)
  end

  def rollback
    retreat_and_jump_away()
  end
end
```

Each validated attribute is available as an attr_accessor on the instance of the command, so you can reference them directly in the `#call` method. within the `#call` and `#rollback` instance methods due to an `attr_reader` in the `Adama::Command` module.

### Invoker

To create an invoker, include the `Adama::Invoker` module in your invoker's class definition:

```ruby
class RebuildHumanRace
  include Adama::Invoker
end
```

Because the `Adama::Invoker` module extends `Adama::Command` you can execute an invoker in the exact same way you execute a command, with the `.call` class method:

```ruby
RebuildHumanRace.call(captain: :apollo, president: :laura)
```

The `Adama::Invoker` module _also_ extends your invoker class with the `.invoke` class method, which allows you to specify a list of commands to run in sequence, e.g.:

```ruby
class RebuildHumanRace
  include Adama::Invoker

  invoke(
    GetArrowOfApollo,
    DestroyCylons,
    FindEarth,
  )
end
```

Now, when you run `RebuildHumanRace.call(captain: :apollo, president: :laura)` it will execute `GetArrowOfApollo`, then `DestroyCylons`, then finally `FindEarth` commands in order.

If there is an error in any of those commands, the invoker will call `FindEarth.rollback`, then `DestroyCylons.rollback`, then `GetArrowOfApollo.rollback` leaving everything just as it was in the beginning.

#### Instance Invoker List

Typically your Invoker class takes responsibility for an immutable set of actions, however sometimes it's handy to be able to adjust the invoked commands on the fly while keeping the error handling and rollback functionality of the invoker.

e.g.

```ruby
class FightCylons
  include Adama::Invoker
end

attack1 = Invoker.new(captain: :apollo, lieutenant:  :starbuck).invoke(Advance, Strafe, Fire)
attack2 = Invoker.new(captain: :apollo, lieutenant:  :starbuck).invoke(Advance, Fire)

attack1.run
attack2.run
```

It's important to see that we're using the `#run` instance method on the Invoker instance (as the `.call` class method would). This ensures we execute the invoker in the error / rollback handler. Calling the `#call` instance method directly would simply execute each command, without any Invoker level error handling.

### Errors

`Adama::Command#call` or `Adama::Invoker#call` will *always* raise an error of type `Adama::Errors::BaseError`.

More specifically:

If a command fails, it will raise `Adama::Errors::CommandError`.

If a command fails while being called in an invoker, the commands will be rolled back and the invoker will raise `Adama::Errors::InvokerError`.

If a command fails while rolling back within the invoker, the invoker will raise `Adama::Errors::InvokerRollbackError`.

The base error type `Adama::Errors::Adama` is designed to be initialized with three optional keyword args:

`error` - the original exception that was rescued in the command or invoker.
`command` - the failed command instance.
`invoker` - the failed invoker instance, set if the command or rollback failed in an invoker.

```ruby
module Adama
  module Errors
    class BaseError < StandardError
      attr_reader :error, :command, :invoker

      def initialize(error: nil, command: nil, invoker: nil)
        @error = error
        @command = command
        @invoker = invoker
      end
    end
  end
end
```

### TODOS

I'm contemplating adding support for per-command validation, potentially through the [dry-validation](https://github.com/dry-rb/dry-validation) gem,

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bugcrowd/adama. So Say We All.
