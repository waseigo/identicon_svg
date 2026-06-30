# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] — 2026-07-01

### Added

- `@doc` annotations with runnable doctests for `generate/6`.
- Expanded `@moduledoc` with quick-start examples and pipeline description.
- CHANGELOG.md in Keep a Changelog format.
- `:reach` dev dependency for cross-function smell detection.

### Changed

- Pipeline step functions (`hash_input`, `extract_colors`, `square_grid`,
  `extract_foreground_squares`, `find_neighboring_squares`,
  `group_neighbors_into_polygons`, `convert_polygons_into_edgelists`,
  `trace_polygon_edges_to_paths`, `generate_svg`, `return_svg`) made
  private — they are internal implementation details.
- Upgraded `squircle` dependency to `~> 1.0`.

### Fixed

- SVG output uses `version="1.1"` instead of `"1.2"` for browser compatibility.
- Opacity guard now accepts integer values (`is_number` instead of `is_float`).
- `bg_color` atom guard restricted to valid complement types only
  (`:basic`, `:split1`, `:split2`).
- Stub test replaced with real functional tests.
- `is_bitstring/1` replaced with `is_binary/1` (deprecated in recent Elixir).
- Char list deprecation warning (`'...'` → `~c"..."`).

### Removed

- Dead code: `keys_by_value/2`, `generate_coordinates/1`, unused `layer`
  struct field, redundant `edge_connector` clause.

## [0.9.5] — 2026

### Changed

- `shape-rendering` set to `auto` for better visual quality.

## [0.9.4] — 2025

### Added

- Optional squircle cropping via `:squircle_curvature` keyword option.

## [0.9.3] — 2025

### Fixed

- Mask ID now randomly generated to avoid clashes between multiple SVG
  identicons on the same page.

## [0.9.2] — 2025

### Fixed

- SVG dimensions set to 100% width and height.

## [0.9.1] — 2025

### Fixed

- Added `:crypto` and `:eex` to application dependencies so the library
  works as a Hex dependency.

## [0.9.0] — 2025

### Added

- Complete rewrite with pipeline architecture through `%Identicon{}` struct.
- `Draw`, `Color`, `EdgeTracer`, `EdgeCleaner`, `PolygonReducer` sub-modules.
- Support for sizes 4–10 with automatic hash function selection.
- Background complementarity (`:basic`, `:split1`, `:split2`).
- Padding, opacity, and optional background color.

## [0.7.0] — 2024

### Added

- Initial working prototype.
