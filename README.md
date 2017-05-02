# SlidingPartition

[![Gem Version](https://badge.fury.io/rb/sliding_partition.svg)](http://badge.fury.io/rb/sliding_partition)
[![Code Climate GPA](https://codeclimate.com/github/paul/sliding_partition.svg)](https://codeclimate.com/github/paul/sliding_partition)
[![Code Climate Coverage](https://codeclimate.com/github/paul/sliding_partition/coverage.svg)](https://codeclimate.com/github/paul/sliding_partition)
[![Gemnasium Status](https://gemnasium.com/paul/sliding_partition.svg)](https://gemnasium.com/paul/sliding_partition)
[![Travis CI Status](https://secure.travis-ci.org/paul/sliding_partition.svg)](https://travis-ci.org/paul/sliding_partition)

<!-- Tocer[start]: Auto-generated, don't remove. -->

# Table of Contents

- [Features](#features)
- [Screencasts](#screencasts)
- [Requirements](#requirements)
- [Setup](#setup)
- [Usage](#usage)
  - [Rails](#rails)
- [Tests](#tests)
- [Versioning](#versioning)
- [Code of Conduct](#code-of-conduct)
- [Contributions](#contributions)
- [License](#license)
- [History](#history)
- [Credits](#credits)

<!-- Tocer[finish]: Auto-generated, don't remove. -->

# Features

# Screencasts

# Requirements

0. [MRI 2.3.1](https://www.ruby-lang.org)

# Setup

For a secure install, type the following (recommended):

    gem cert --add <(curl --location --silent /gem-public.pem)
    gem install sliding_partition --trust-policy MediumSecurity

NOTE: A HighSecurity trust policy would be best but MediumSecurity enables signed gem verification while
allowing the installation of unsigned dependencies since they are beyond the scope of this gem.

For an insecure install, type the following (not recommended):

    gem install sliding_partition

Add the following to your Gemfile:

    gem "sliding_partition"

# Usage

## Rails

Create a migration for the parent table. This table won't contain any data
itself, but gives us the skeleton that the other tables will inherit, and will
be used by the model for queries.

```ruby
class AddEventsTable
  def change
    create_table :events do |t|
      t.string    :name
      t.timestamp :event_at
      t.timestamps
    end

    add_index :events, [:name, :event_at]
  end
end
```

Once that table exists, set up a config to tell SlidingPartition how you want it partitioned:

```ruby
# config/sliding_partitions.rb

SlidingPartition.define(Event) do |partition|
  partition.time_column          = :event_at
  partition.suffix               = "%Y%m%d"   # A strftime-formatted string, will be appended to all partition table names
  partition.partition_interval   = 1.month
  partition.retention_interval   = 6.months
end
```

Now, have SlidingPartition manage these tables.

```ruby
SlidingPartition.initialize!
```

Finally, you'll want SlidingPartition to run periodically, to ensure the next
period's table is created ahead of time. We recommend that you run it several
times leading up to the next date, it does no harm to have the empty table
sitting around for future use, in case something fails and it takes it awhile
to fix it. We also recommend you put this in a background job, and trigger it
using clockwork or some other recurring job spawner. SlidingPartition comes
with an ActiveJob Job for this purpose.

```ruby
module Clockwork

  every 1.day do
    SlidingPartition::Job.perform_later
  end

end
```

# Tests

To test, run:

    bundle exec rake

# Versioning

Read [Semantic Versioning](http://semver.org) for details. Briefly, it means:

- Patch (x.y.Z) - Incremented for small, backwards compatible bug fixes.
- Minor (x.Y.z) - Incremented for new, backwards compatible public API enhancements and/or bug fixes.
- Major (X.y.z) - Incremented for any backwards incompatible public API changes.

# Code of Conduct

Please note that this project is released with a [CODE OF CONDUCT](CODE_OF_CONDUCT.md). By participating in this project
you agree to abide by its terms.

# Contributions

Read [CONTRIBUTING](CONTRIBUTING.md) for details.

# License

Copyright (c) 2016 []().
Read the [LICENSE](LICENSE.md) for details.

# History

Read the [CHANGELOG](CHANGELOG.md) for details.
Built with [Gemsmith](https://github.com/bkuhlmann/gemsmith).

# Credits

Developed by [Paul Sadauskas]() at []().
