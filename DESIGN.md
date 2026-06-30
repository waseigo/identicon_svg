# Design

IdenticonSvg generates GitHub-style identicons as SVG strings, starting from an
arbitrary text input and a few configuration options.

## Architecture

The library is centered on the `%Identicon{}` struct, which accumulates state
as the input text is transformed through a **pipeline of pure functions**. Each
pipeline step takes the struct, derives a new field, and returns the updated
struct. The final step returns the SVG string.

### The pipeline

```
text
  │ hash_input            — hash the text, produce a byte list
  │ extract_colors        — pick foreground color from the hash bytes;
  │                          resolve background color (nil, hex, or complementary)
  │ square_grid           — mirror the byte list into a 2D grid layout
  │ extract_foreground_squares — keep only indices with even bytes (foreground)
  │ find_neighboring_squares  — build adjacency map of foreground squares
  │ group_neighbors_into_polygons — merge adjacent squares into polygons
  │ convert_polygons_into_edgelists — extract external edges per polygon
  │ trace_polygon_edges_to_paths  — connect edges into contiguous SVG paths
  │ generate_svg          — compose the final SVG string (optionally squircled)
  ▼
SVG string
```

### Module responsibilities

| Module                        | Role                                                                |
| ----------------------------- | ------------------------------------------------------------------- |
| `IdenticonSvg`                | Public API, pipeline orchestration                                  |
| `IdenticonSvg.Identicon`      | The `%Identicon{}` struct definition                                |
| `IdenticonSvg.Color`          | Hex↔RGB conversion, complementary color math                        |
| `IdenticonSvg.PolygonReducer` | Neighbor detection, iterative polygon grouping                      |
| `IdenticonSvg.EdgeCleaner`    | Extract external edges, remove shared/internal edges                |
| `IdenticonSvg.EdgeTracer`     | Connect disjoint edges into ordered, directed SVG paths             |
| `IdenticonSvg.Draw`           | SVG template composition (EEx), viewbox calculation, path rendering |

### Key details

- **Hash selection** — the hashing function scales with identicon size: MD5 for
  4–5, RIPEMD-160 for 6, SHA3-224/256/384/512 for 7–10. This keeps the byte
  input dense enough to fill the grid.
- **Grid mirroring** — the byte list is chunked, sliced to `ceil(size/2)`, and
  each row is mirrored so the identicon is symmetric along the vertical axis.
- **Foreground detection** — only grid cells with even byte values become
  foreground squares. The rest are left transparent (or filled with the
  background color).
- **Polygon merging** — `PolygonReducer.group/1` iteratively merges neighboring
  foreground squares into polygons via `Enum.reduce_while`. Each iteration
  groups any squares that touch (horizontally) and repeats until no more merges
  happen.
- **Edge tracing** — `EdgeTracer` takes each polygon's external edges, finds
  connectivity via midpoint neighbors, and traces them into ordered SVG path
  strings. Donut-hole polygons (from enclaves within a polygon) are handled as
  separate sublists and traced independently.
- **Squircle cropping** — when `squircle_curvature` is set, the SVG group is
  passed through `Squircle.svg_group/4` from the sibling
  [squircle](https://github.com/waseigo/squircle) library.

## SVG output modes

1. **Transparent background (`bg_color: nil`)** — single `<path>` for
   foreground squares only.
2. **Solid background (`bg_color: "#..."`)** — foreground `<path>` + a
   `<mask>` containing white inner paths + a background `<path>`.
3. **Complementary background (`bg_color: :basic/:split1/:split2`)** —
   same as solid, but the color is computed from the foreground color.

When padding and a non-nil background are combined, the viewbox expands and the
background mask extends into the padding area.
