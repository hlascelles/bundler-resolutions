## 0.6.1 (2026-02-19)

- Gem dependency updates and rubocop fixes

## 0.6.0 (2026-02-06)

- Signal bundler that locked specs have invalid dependencies [#61](https://github.com/hlascelles/bundler-resolutions/pull/61)

## 0.5.0 (2025-05-03)

- Allow YAML arrays and CSVs for versions [#41](https://github.com/hlascelles/bundler-resolutions/pull/41)

## 0.4.0 (2025-05-03)

- Allow existing lockfiles to be noticed [#37](https://github.com/hlascelles/bundler-resolutions/pull/37)

## 0.3.0 (2025-05-03)

- BREAKING CHANGE: Add resolution versions to concrete dependencies [#27](https://github.com/hlascelles/bundler-resolutions/pull/27)

## 0.2.0 (2025-03-23)

- BREAKING CHANGE: Refactor to use config file [#18](https://github.com/hlascelles/bundler-resolutions/pull/18)
  To upgrade to this version you must now supply a `.bundler-resolutions.yml` file. This can be
  in the root of your project, or the location to it can be specified using the `BUNDLER_RESOLUTIONS_CONFIG` ENV.

## 0.1.0 (2024-10-02)

- First version
