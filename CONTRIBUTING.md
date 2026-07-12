# Contributing to loaders.zig

Thanks for your interest in contributing to `loaders.zig`! This document covers the process for reporting issues, suggesting features, and submitting code changes.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Code Style](#code-style)
- [Documentation](#documentation)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Bugs](#reporting-bugs)
- [Requesting Features](#requesting-features)

---

## Code of Conduct

Be respectful and constructive. We're here to build something useful together.

---

## Getting Started

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/loaders.zig.git
   cd loaders.zig
   ```
3. **Create a branch** for your change:
   ```bash
   git checkout -b my-feature
   ```

---

## Development Setup

### Prerequisites

| Requirement | Version |
|-------------|---------|
| **Zig** | 0.16.0 |
| **OS** | Linux, macOS, or Windows |

### Build and Test

```bash
# Run all tests
zig build test --summary all

# Build all examples
zig build examples

# Run all examples
zig build run-all-examples

# Format check
zig fmt --check build.zig src/ examples/
```

### Documentation (optional)

Docs are built with [VitePress](https://vitepress.dev/) and [Bun](https://bun.sh/):

```bash
cd docs
bun install
bun run dev      # local dev server
bun run build    # production build
```

---

## Project Structure

```
loaders.zig/
├── src/
│   ├── loaders.zig        # Root module (public API entry point)
│   ├── bar.zig            # Progress bar implementation
│   ├── spinner.zig        # Background-threaded spinner
│   ├── batch.zig           # BatchBar multi-task progress
│   ├── color.zig          # ANSI color/escape code generation
│   ├── style.zig          # BarStyle + SpinnerStyle presets
│   ├── terminal.zig       # TTY detection, terminal sizing
│   ├── utils.zig          # Pure utility functions
│   ├── version.zig        # Version metadata
│   └── update_checker.zig # GitHub release update checker
├── examples/              # Example programs
├── docs/                  # VitePress documentation site
├── build.zig              # Build system
├── build.zig.zon          # Package manifest
└── README.md
```

---

## Making Changes

### Workflow

1. Create a topic branch from `main`.
2. Make your changes in small, focused commits.
3. Write or update tests for any new functionality.
4. Ensure all tests pass: `zig build test --summary all`
5. Ensure examples build: `zig build examples`
6. Format your code: `zig fmt src/ examples/`
7. Push and open a pull request.

### Commit Messages

Use clear, concise commit messages:

- `add fire bar style preset`
- `fix indeterminate bar bounce range`
- `docs: update spinner guide examples`

---

## Testing

All tests live inside each source file as `test` blocks. The root `src/loaders.zig` pulls in tests from all sub-modules.

```bash
# Run all tests
zig build test --summary all
```

When adding new functionality:
- Add unit tests in the relevant source file.
- Test both the happy path and edge cases.
- Tests should not require a real TTY — use `TermInfo.dumb` and `color_enabled = false`.

---

## Code Style

Follow existing conventions:

- **No comments** unless explicitly requested.
- Use `snake_case` for variables and functions.
- Use `PascalCase` for types and structs.
- Keep functions focused and short.
- Prefer stack allocation over heap when possible.
- All public types and functions must have doc comments (`///`).

Format with:

```bash
zig fmt src/ examples/
```

CI will reject PRs that fail `zig fmt --check`.

---

## Documentation

- Update `docs/guide/` if you change user-facing behavior.
- Update `docs/api/index.md` if you add or change public API.
- Add SEO frontmatter (`description`, `keywords`) to new doc pages.
- Test docs locally: `cd docs && bun install && bun run dev`

---

## Submitting a Pull Request

1. Fill out the PR template completely.
2. Link any related issues.
3. PRs should target the `main` branch.
4. Keep PRs focused — one feature or fix per PR.
5. Ensure CI passes (tests, examples, format check).

### PR Checklist

- [ ] `zig build test --summary all` passes
- [ ] `zig build examples` succeeds
- [ ] `zig fmt --check build.zig src/ examples/` passes
- [ ] Tests added for new functionality
- [ ] Documentation updated (if applicable)

---

## Reporting Bugs

Use the [bug report template](https://github.com/muhammad-fiaz/loaders.zig/issues/new?template=bug_report.yml). Include:

- Zig version and OS
- Minimal code to reproduce
- Expected vs actual behavior

---

## Requesting Features

Use the [feature request template](https://github.com/muhammad-fiaz/loaders.zig/issues/new?template=feature_request.yml). Describe the use case and expected API.

---

## Questions?

Open a [discussion](https://github.com/muhammad-fiaz/loaders.zig/discussions) or ask in the relevant issue.
