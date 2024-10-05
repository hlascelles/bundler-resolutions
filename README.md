bundler-resolutions
===================

[![Gem Version](https://img.shields.io/gem/v/bundler-resolutions?color=green)](https://rubygems.org/gems/bundler-resolutions)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[bundler-resolutions](https://github.com/hlascelles/bundler-resolutions) is a [bundler](https://bundler.io/)
plugin that allows you to specify gem version requirements in your `Gemfile` without explicitly declaring
a concrete dependency on those gems. It acts much like the
[resolutions](https://classic.yarnpkg.com/lang/en/docs/selective-version-resolutions/) feature in
[Yarn](https://yarnpkg.com/).

> [!WARNING]  
> This is an experimental project and neither its API stability nor correctness should be assumed

## Usage

Add `bundler-resolutions` to your Gemfile, and add a `resolutions` group to specify the gems you
want to specify versions requirements for.

The resulting `Gemfile.lock` in this example will have nokogiri locked to `1.16.5` or above.

```ruby
plugin 'bundler-resolutions'

gem "rails"

group :resolutions do
  gem "nokogiri", ">= 1.16.5" # CVE-2024-34459
end
```

However the `Gemfile.lock` from this example will not have nokogiri at all, as it is neither
explicitly declared, nor brought in as a transitive dependency.

```ruby
plugin 'bundler-resolutions'

group :resolutions do
  gem "nokogiri", ">= 1.16.5" # CVE-2024-34459
end
```

## Detail

`bundler-resolutions` allows you to specify version requirements using standard gem syntax in your
Gemfile to indicate that you have version requirements for those gems *if* they were to be brought
in as transitive dependencies, but that you don't depend on them yourself directly.

An example use case is in the Gemfile given below. Here we are saying that although we do not use nokogiri
specifically ourselves, we want to ensure that if it is pulled in by other gems then it will
always be above the know version with a CVE.

```ruby
source "https://rubygems.org"

plugin 'bundler-resolutions'

gem "rails"

group :resolutions do
  gem "nokogiri", ">= 1.16.5" # CVE-2024-34459
end
```

The big difference between doing this and just declaring it in your Gemfile is that it will only 
be used in resolutions (and be written to your lock file) if the gems you do directly depend on
continue to use it. If they stop using it, then your resolutions will take no part in the
bundler lock resolution.

The other difference is that even if it does take part in the resolutions, it will not be
present in the `DEPENDENCIES` section of the lock file, as it is not a direct dependency.

## Use cases

There are a number of reasons you may want to prevent the usage of some gem versions, but without
declaring their direct use in Gemfiles. Also there are reasons to set versions across a monorepo
of many Gemfiles, but where not all apps use all blessed versions, such as:

1. You have learnt of a CVE of a gem.
1. You have internal processes that mandate the usage of certain gem versions for legal or sign off reasons.
1. You wish to take a paranoid approach to updating certain high value target gems. eg `devise`.
1. You want certain gem collections to move in lockstep. eg `sinatra`, `rack` and `rack-protection`, which are relatively tightly coupled.
1. You know of gems that are very slow to install and you have preinstalled them in internal base images. eg `rugged` or `sorbet`.
1. You know of gems that are tightly coupled to ruby itself that shouldn't be upgraded. eg `stringio` and `psych`.
1. You know of gem incompatibilities with your codebase in their later versions.
1. You know that different OS architectures do not work with some versions.
1. You wish to prevent unintentional downgrades of dependencies when using `bundle` commands.

## How it works

`bundler-resolutions` works by patching the Gemfile DSL to allow for special processing
of the `resolutions` group. It also patches the bundler `filtered_versions_for` method to
allow for the resolution restrictions from the versions specified in the `resolutions` group.

This is a very early version, and it should be considered experimental.

Future work may include relating this to bundler-audit, and other security tools, so you
will automatically gain version restrictions against known CVEs.
