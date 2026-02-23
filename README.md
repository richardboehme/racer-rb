# Racer

> [!WARNING]
> This is an early-stage implementation. It may crash, produce incorrect type signatures, or behave unexpectedly. Use with caution.

Racer generates [RBS](https://github.com/ruby/rbs) type signatures by tracing your application at runtime during test runs. Run your test suite and find the collected signatures written to `sig/generated/`.

## Installation

Add to your `Gemfile` (test group recommended):

```ruby
gem "racer-rb"
```

> [!NOTE]
> Note that Racer requires Ruby 4 and json-c to compile properly.

## Usage

### Minitest

At the top of your test helper, require the Minitest integration:

```ruby
require "racer/minitest"
```

### RSpec

In your spec helper, require the RSpec integration:

```ruby
require "racer/rspec"

RSpec.configure do |config|
  Racer::RSpecPlugin.configure(config)
end
```

Make sure to require Racer at the top of the spec helper.

### Rails

When using Rails, a Railtie is automatically loaded. It sets up tracing around each test with a `path_regex` scoped to `app/`, `lib/`, `test/`, and `spec/`.

### Standalone

You can also use Racer manually:

```ruby
require "racer"

pid = Racer.start_agent
Racer.start(path_regex: /my_app/, max_generic_depth: 2)

# ... run your code ...

Racer.stop
Racer.flush
Racer.stop_agent(pid)
```

**Options for `Racer.start`:**

| Option | Default | Description |
|---|---|---|
| `path_regex` | `nil` | Only trace files whose path matches this regex. Highly recommended to avoid tracing of gem internals. |
| `max_generic_depth` | `2` | Maximum depth for tracking generic type arguments (e.g. `Array[String]`). |

### Tips

* Ensure to use eager loading when generating type signatures to trace DSL method calls (e.g. by setting the `CI=1` env variable in Rails setups)
* Racer works out of the box with parallel tests. No need to configure anything.
* Racer integrates with gem signatures using RBS collection, however the support might not be stable.

## Output

Generated RBS files are written to `sig/generated/`. These can be used with tools like [Steep](https://github.com/soutaro/steep) for static type checking.

## How it works

Racer hooks into Ruby's TracePoint mechanism via a C extension to observe method calls, parameter types, return values, and module hierarchy during test runs. Traces are sent to a background agent process over a Unix socket, which collects and deduplicates them. When the test suite finishes, the agent writes RBS files to `sig/generated/`.

Some more info can be found in the [slides](https://github.com/richardboehme/racer-rb-presentation/) that were used to present this gem at [Dresden.rb user group](https://dresdenrb.onruby.de/).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/richardboehme/racer-rb.

## License

MIT
