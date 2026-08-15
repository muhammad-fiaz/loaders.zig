---
title: Guide
description: Learn how to use loaders.zig for terminal progress bars and spinners.
---

# Guides

Step-by-step guides for using loaders.zig in your Zig applications.

## Getting Started

- [Getting Started](/guide/getting-started) — install the library, create your first progress bar and spinner, and learn the core concepts (thread modes, rendering, writing output).

## Core Concepts

- **Thread modes** — `.none` (manual), `.auto` (background thread), `.external` (caller-driven).
- **Auto-start** — bars and spinners start automatically on first update (`setProgress`, `tick`, `tickFrame`) when left in the `.pending` state.
- **Templates** — every widget renders through the template engine; see [Templates](/api/templates) for all tokens.
- **Writing output** — always use `loaders.stdoutWriter(io)` (returns a pointer) to write lines after a widget; see [Terminal Helpers](/api/terminal).

## Quick Reference

| Topic | Link |
|-------|------|
| Progress Bar | [API](/api/progress-bar) |
| Spinner | [API](/api/spinner) |
| Block Bar | [API](/api/block-bar) |
| Indeterminate | [API](/api/indeterminate) |
| MultiBar | [API](/api/multi-bar) |
| BatchRunner | [API](/api/batch-runner) |
| StepSequence | [API](/api/step-sequence) |
| Templates & Formatters | [API](/api/templates) |
| Terminal Helpers | [API](/api/terminal) |
| All examples | [Examples](/examples/) |