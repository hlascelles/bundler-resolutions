# Instructions for LLM Coding Agents Working on `bundler-resolutions`

This document provides guidance and best practices for Large Language Model (LLM) coding agents contributing to the `bundler-resolutions` gem.

## Project Overview: `bundler-resolutions`

Before making changes, it's important to understand what this gem does.

**Core Purpose:**
The `bundler-resolutions` gem allows developers to specify version requirements for Ruby gems within a project. Crucially, it does this *without* needing to declare these gems as direct dependencies in the `Gemfile`. This is primarily for managing transitive dependencies: ensuring that if other gems pull in certain dependencies, those dependencies meet specific version criteria.

**How it Works:**
The gem integrates with Bundler by patching its resolver mechanism. During dependency resolution, `bundler-resolutions` steps in and filters the available versions of gems. This filtering is based on version constraints defined in a dedicated configuration file.

**Configuration:**
- **Default Config File:** The gem primarily looks for a YAML file named `.bundler-resolutions.yml`. It searches for this file in the current directory and then traverses upwards to parent directories up to the root.
- **Environment Variable Override:** The path to the configuration file can be explicitly set using the `BUNDLER_RESOLUTIONS_CONFIG` environment variable.

**Configuration File Format Example:**
The YAML configuration file has a main `gems` key. Under this key, individual gem names are mapped to their required version constraints (similar to `Gemfile` syntax).

```yaml
gems:
  nokogiri: ">= 1.16.5" # Example: Ensure nokogiri is at least 1.16.5 if it's a transitive dependency
  thor: ">= 1.0.1, < 2.0" # Example: Constrain thor to versions between 1.0.1 (inclusive) and 2.0 (exclusive)
```

## General Best Practices for Contributing

When making changes to this repository, please adhere to the following guidelines:

1.  **Understand the Scope:** Before coding, ensure you understand the issue or feature request. If anything is unclear, ask for clarification.
2.  **Focused Changes:** Make changes that are directly related to the task at hand. Avoid altering unrelated code or reformatting code outside the scope of your changes. This helps keep pull requests small and easy to review.
3.  **Testing is Key:**
    *   Write new tests for new features or bug fixes.
    *   Ensure all existing tests pass after your changes.
    *   Run tests using the project's designated test script/command (e.g., `bundle exec rspec` or `specs.sh`).
4.  **Follow Existing Style:** Adhere to the existing code style, conventions, and patterns found in the codebase. This includes aspects like variable naming, commenting, and file structure.
5.  **Atomic Commits:** Keep your commits small, focused, and logical. Each commit should represent a single, atomic change. Write clear and descriptive commit messages.
6.  **Read `AGENTS.md`:** If an `AGENTS.md` file exists in a directory you are working in, or any parent directory, its instructions take precedence unless they conflict with user instructions for the current task.
7.  **Dependency Management:**
    *   Be mindful of changes to `Gemfile` or `bundler-resolutions.gemspec`.
    *   If you modify dependencies, ensure `Gemfile.lock` is updated accordingly by running `bundle install`.
8.  **Documentation:** If your changes affect user-facing behavior or internal mechanisms in a significant way, consider if any documentation (like the README or code comments) needs updating.
9.  **Communicate:** If you're stuck, have made significant changes to an approved plan, or need user input, use the appropriate tools to communicate.

By following these guidelines, you'll help maintain the quality and consistency of the `bundler-resolutions` codebase.
