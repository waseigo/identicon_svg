# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg do
  alias IdenticonSvg.EdgeTracer

  alias IdenticonSvg.{
    Identicon,
    Color,
    Draw,
    EdgeCleaner,
    PolygonReducer
  }

  @moduledoc """
  Generate GitHub-style identicons as complete SVG documents.

  The central entry point is `generate/6`. It hashes the input `text`,
  derives a grid and foreground color from the hash, mirrors the grid
  for symmetry, merges neighboring foreground squares into polygons,
  traces their edges, and composes the final SVG string.

  ## Quick-start

      iex> svg = IdenticonSvg.generate("banana")
      iex> String.starts_with?(svg, "<svg")
      true
      iex> String.ends_with?(svg, "</svg>")
      true

  See `generate/6` for all available options (size, background color,
  opacity, padding, and squircle cropping).
  """
  @moduledoc since: "0.1.0"

  defguardp valid_generate_args?(text, size, bg_color, opacity, padding)
            when is_binary(text) and size in 4..10 and
                   (is_binary(bg_color) or is_nil(bg_color) or
                      bg_color in [:basic, :split1, :split2]) and
                   is_number(opacity) and opacity >= 0 and opacity <= 1 and
                   is_integer(padding) and padding >= 0

  @doc """
  Generate the SVG code of the identicon for the specified `text`.

  Without specifying any optional arguments this function generates a 5x5 identicon
  with a transparent background and colored grid squares with full opacity.

  A different hashing function is used automatically for each identicon `size`,
  so that the utilization of bits is maximized for the given size:
  * MD5 for sizes 4 and 5,
  * RIPEMD-160 for 6, and
  * SHA3 for 7 to 10 with 224, 256, 384 and 512 bits, respectively.

  ## Doctests

      iex> svg = IdenticonSvg.generate("banana")
      iex> String.starts_with?(svg, "<svg")
      true
      iex> String.ends_with?(svg, "</svg>")
      true
      iex> String.contains?(svg, ~s(version="1.1"))
      true

  The output is deterministic — the same text always produces the same identicon:

      iex> IdenticonSvg.generate("banana") == IdenticonSvg.generate("banana")
      true

  Different texts produce different identicons:

      iex> IdenticonSvg.generate("banana") != IdenticonSvg.generate("apple")
      true

  ## Arguments

  Optionally, specify any combination of the following arguments:

  * `size`: the number of grid squares of the identicon's side; integer, 4 to 10; 5 by default.
  * `bg_color`: the color of the background grid squares as a hex code string (e.g., `#eee`)
    _or_ an atom specifying the color complementarity (see below); `nil` by default.
  * `opacity`: the opacity of the entire identicon (all grid squares); float, 0.0 to 1.0;
    1.0 by default.

  The color of the foreground grid squares is always equal to the three first bytes of the
  hash of `text`, regardless of which hashing function is used automatically.

  Setting `bg_color` to `nil` (default value) generates only the foreground (colored) squares,
  with the default (1.0) or requested `opacity`.

  Setting `padding` to a positive integer adds padding around the identicon. If `bg_color` is
  non-nil, the padding area inherits the background color at the requested `opacity`. The
  resulting SVG file size is greatly reduced compared to generating a larger grid.

  The `:squircle_curvature` keyword option crops the identicon to a squircle. Pass a float
  between 0.0 (sharp corners) and 1.0 (circle). Requires the `squircle` dependency.

  ### Background complementarity

  Setting `bg_color` to one of the following atom values sets the color of the background
  squares to the corresponding RGB-complementary color of the automatically-defined foreground
  color:

  * `:basic` — the complementary color, i.e. the opposite color of `fg_color` on the color
    wheel.
  * `:split1` — the first adjacent tertiary color of the complement of `fg_color` on the
    color wheel.
  * `:split2` — the second adjacent tertiary color of the complement of `fg_color` on the
    color wheel.

  ## Gallery

  5x5 identicon with transparent background:
  ```elixir
  generate("banana")
  ```
  ![5x5 identicon for "banana", at full opacity, with transparent background](assets/banana_5x5_nil_1p0.svg)

  5x5 identicon with complementary background color:
  ```elixir
  generate("banana", 5, :basic)
  ```
  ![5x5 identicon for "banana", at full opacity, with complementary background](assets/banana_5x5_basic_1p0.svg)

  5x5 identicon with first split-complementary background color:
  ```elixir
  generate("banana", 5, :split1)
  ```
  ![5x5 identicon for "banana", at full opacity, with first split-complementary background](assets/banana_5x5_split1_1p0.svg)

  5x5 identicon with second split-complementary background color:
  ```elixir
  generate("banana", 5, :split2)
  ```
  ![5x5 identicon for "banana", at full opacity, with second split-complementary background](assets/banana_5x5_split2_1p0.svg)

  6x6 identicon with transparent background:
  ```elixir
  generate("pineapple", 6)
  ```
  ![6x6 identicon for "pineapple", at full opacity, with transparent background](assets/pineapple_6x6_nil_1p0.svg)

  7x7 identicon with padding 1, complementary background color, and 70% opacity:
  ```elixir
  generate("overbring.com", 7, :basic, 0.7, 1)
  ```
  ![7x7 identicon for "overbring.com" with padding 1, complementary background color, and 70% opacity](assets/overbring.com_7x7_basic_0p7_pad1.svg)

  7x7 identicon with blue (`#33f`) background:
  ```elixir
  generate("refrigerator", 7, "#33f")
  ```
  ![7x7 identicon for "refrigerator", at full opacity, with blue background](assets/refrigerator_7x7_33f_1p0.svg)

  9x9 identicon with transparent background and 50% opacity:
  ```elixir
  generate("2023-03-14", 9, nil, 0.5)
  ```
  ![9x9 identicon for "2023-03-14", at 50% opacity, with transparent background](assets/2023-03-14_9x9_nil_0p5.svg)


  10x10 identicon with yellow (`#ff0`) background and 80% opacity:
  ```elixir
  generate("banana", 10, "#ff0", 0.8)
  ```
  ![10x10 identicon for "banana", at 80% opacity, with yellow background](assets/banana_10x10_ff0_0p8.svg)

  10x10 identicon with split-1 background complementary color, with 3 squares of padding, at full opacity, cropped to a squircle with curvature factor 0.9:
  ```elixir
  generate("squircles!!", 10, :split2, 1.0, 3, squircle_curvature: 0.9)
  ```
  <img src="assets/squircles!!!_10x10_split2_1p0_pad3_squircle0p9.svg" width="100" />

  5x5 identicon with basic background complementary color, with 2 squares of padding, at 40% opacity, cropped to a squircle with curvature factor 0.82:
  ```elixir
  generate("elixir", 5, :basic, 0.4, 2, squircle_curvature: 0.82)
  ```
  <img src="assets/elixir_5x5_basic_0p4_pad2_squircle0p82.svg" width="100" />
  """

  def generate(
        text,
        size \\ 5,
        bg_color \\ nil,
        opacity \\ 1.0,
        padding \\ 0,
        opts \\ [squircle_curvature: nil]
      )
    when valid_generate_args?(text, size, bg_color, opacity, padding) do
    %Identicon{
      text: text,
      size: size,
      opacity: opacity,
      padding: padding,
      bg_color: bg_color
    }
    |> hash_input()
    |> extract_colors()
    |> square_grid()
    |> extract_foreground_squares()
    |> find_neighboring_squares()
    |> group_neighbors_into_polygons()
    |> convert_polygons_into_edgelists()
    |> trace_polygon_edges_to_paths()
    |> generate_svg(opts)
    |> return_svg()
  end

  defp return_svg(%Identicon{svg: svg}) when is_binary(svg) do
    svg
  end

  defp generate_svg(
        %Identicon{
          paths: paths,
          size: size,
          padding: padding,
          fg_color: fg_color,
          bg_color: bg_color,
          opacity: opacity
        } = input,
        opts
      ) do
    squircle_curvature = Keyword.get(opts, :squircle_curvature)
    only_group? = is_number(squircle_curvature)

    svg =
      Draw.svg(paths, size, padding, fg_color, bg_color, opacity,
        only_group: only_group?,
        curvature: squircle_curvature
      )

    %{input | svg: svg}
  end

  defp trace_polygon_edges_to_paths(%Identicon{edges: edges} = input) do
    paths =
      edges
      |> EdgeTracer.doit()
      |> Enum.map(&hd/1)

    %{input | paths: paths}
  end

  defp convert_polygons_into_edgelists(
        %Identicon{polygons: polygons, size: size} = input
      ) do
    edges =
      polygons
      |> Enum.map(&EdgeCleaner.polygon_external_edges(&1, size))

    %{input | edges: edges}
  end

  defp find_neighboring_squares(%Identicon{squares: squares, size: size} = input) do
    neighbors =
      squares
      |> PolygonReducer.neighbors_per_index(size)

    %{input | neighbors: neighbors}
  end

  defp group_neighbors_into_polygons(%Identicon{neighbors: neighbors} = input) do
    polygons = PolygonReducer.group(neighbors)

    %{input | polygons: polygons}
  end

  defp appropriate_hash(size) when size in 4..10 do
    hashes = %{
      4 => :md5,
      5 => :md5,
      6 => :ripemd160,
      7 => :sha3_224,
      8 => :sha3_256,
      9 => :sha3_384,
      10 => :sha3_512
    }

    hashes[size]
  end

  defp hash_input(%Identicon{text: text, size: size} = input) do
    grid =
      appropriate_hash(size)
      |> :crypto.hash(text)
      |> :binary.bin_to_list()

    %{input | grid: grid}
  end

  defp extract_colors(%Identicon{grid: grid, bg_color: bg_color} = input) do
    fg_color =
      grid
      |> Enum.chunk_every(3)
      |> hd()
      |> Enum.map(&Color.integer_to_hex/1)
      |> List.to_string()
      |> String.downcase()
      |> String.pad_leading(7, "#")

    bg_color = determine_background_color(fg_color, bg_color)

    input
    |> Map.put(:fg_color, fg_color)
    |> Map.put(:bg_color, bg_color)
  end

  defp square_grid(%Identicon{grid: grid, size: size} = input) do
    odd = rem(size, 2)
    chunks = Integer.floor_div(size, 2) + odd

    grid =
      grid
      |> Enum.chunk_every(chunks)
      |> Enum.slice(0, size)
      |> Enum.flat_map(&mirror_row(&1, odd))

    %{input | grid: grid}
  end

  defp extract_foreground_squares(%Identicon{grid: grid} = input) do
    squares =
      grid
      |> Enum.with_index()
      |> Enum.filter(fn {x, _i} -> rem(x, 2) == 0 end)
      |> Enum.map(fn {_x, i} -> i end)

    %{input | squares: squares}
  end

  defp mirror_row(row, odd) when odd in 0..1 do
    mirror =
      row
      |> Enum.slice(0, length(row) - odd)
      |> Enum.reverse()

    row ++ mirror
  end

  defp determine_background_color(fg_color, bg_color)
       when is_binary(fg_color) and is_atom(bg_color) and
              bg_color in [:basic, :split1, :split2] do
    fg_color
    |> Color.hex_to_rgb()
    |> Color.color_wheel(compl: bg_color)
    |> Color.rgb_to_hex6()
  end

  defp determine_background_color(_fg_color, bg_color)
       when is_binary(bg_color) or is_nil(bg_color) do
    bg_color
  end
end
