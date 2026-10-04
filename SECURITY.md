# Security Policy

## Supported Versions

Only the current release line receives security updates.

| progress version | Zig version   | Status                |
|------------------|---------------|-----------------------|
| 0.0.7            | 0.17.0+       | Supported             |
| 0.0.6            | 0.16.0        | Security fixes only   |
| < 0.0.6          | < 0.16.0      | Not supported         |

```text
For Zig 0.16.0, use progress v0.0.6.
For Zig 0.17.0+, use progress v0.0.7.
```

## Reporting a Vulnerability

Report security issues through
[GitHub Issues](https://github.com/muhammad-fiaz/loaders.zig/issues)
or the repository's private vulnerability reporting channel if enabled.
Please include:

- loaders.zig version (`0.0.7` or `0.0.6`)
- Zig version (`zig version`)
- OS and terminal
- Minimal reproduction steps
- Expected vs actual behavior

## Installation Reference

Current release (Zig 0.17.0+):

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.7.tar.gz
```

Last Zig 0.16.0 compatible release:

```bash
zig fetch --save https://github.com/muhammad-fiaz/loaders.zig/archive/refs/tags/0.0.6.tar.gz
```
