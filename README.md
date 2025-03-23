bundler-resolutions
===================

[![Gem Version](https://img.shields.io/gem/v/bundler-resolutions?color=green)](https://rubygems.org/gems/bundler-resolutions)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[bundler-resolutions](https://github.com/hlascelles/bundler-resolutions) is a [bundler](https://bundler.io/)
plugin that allows you to specify gem version requirements for your `Gemfile` without explicitly declaring
a concrete dependency on those gems. It acts much like the
[resolutions](https://classic.yarnpkg.com/lang/en/docs/selective-version-resolutions/) feature in
[Yarn](https://yarnpkg.com/).

> [!WARNING]  
> This is an experimental project and neither its API stability nor correctness should be assumed

## Usage

Add `bundler-resolutions` to your Gemfile, and add a `.bundler-resolutions.yml` file to
specify the gems you want to specify versions requirements for.

### Example 1

In this example the resulting `Gemfile.lock` will have nokogiri locked to `1.16.5` or above, but
nokogiri will not be present in the `DEPENDENCIES` section of the lock file. Also, if `rails` were
to change to a version that did not depend on nokogiri, then the resolution would not be used or
appear in the lock file at all.

`.bundler-resolutions.yml`:
```yaml
gems:
  nokogiri: ">= 1.16.5" # CVE-2024-34459
```

`Gemfile`:
```ruby
gem 'bundler-resolutions'
gem "rails"
```

### Example 2

Here, the `Gemfile.lock` from this example will not have nokogiri at all, as it is neither
explicitly declared in the Gemfile, nor brought in as a transitive dependency.

`.bundler-resolutions.yml`:
```yaml
gems:
  nokogiri: ">= 1.16.5" # CVE-2024-34459
```

```ruby
gem 'bundler-resolutions'
gem "thor"
```

## Detail

`bundler-resolutions` allows you to specify version requirements in a config file 
to indicate that you have version requirements for those gems *if* they were to be brought
in as transitive dependencies, but that you don't depend on them yourself directly.

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

`bundler-resolutions` works by patching the `bundler` `Resolver` `filtered_versions_for` method to
allow for the resolution restrictions from the versions specified in the config file.

This is a very early version, and it should be considered experimental.

Future work may include relating this to bundler-audit, and other security tools, so you
will automatically gain version restrictions against known CVEs.
