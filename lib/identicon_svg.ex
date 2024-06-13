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
  Main module of `IdenticonSvg` that contains all functions of the library.
  """
  @moduledoc since: "0.1.0"

  @doc """
  Generate the SVG code of the identicon for the specified `text`.

  Without specifying any optional arguments this function generates a 5x5 identicon
  with a transparent background and colored grid squares with full opacity.

  A different hashing function is used automatically for each identicon `size`,
  so that the utilization of bits is maximized for the given size:
  * MD5 for sizes 4 and 5,
  * RIPEMD-160 for 6, and
  * SHA3 for 7 to 10 with 224, 256, 384 and 512 bits, respectively.

  Optionally, specify any combination of the following arguments:

  * `size`: the number of grid squares of the identicon's side; integer, 4 to 10; 5 by default.
  * `bg_color`: the color of the background grid squares as a hex code string (e.g., `#eee`) _or_ an atom specifying the color complementarity (se below); `nil` by default.
  * `opacity`: the opacity of the entire identicon (all grid squares); float, 0.0 to 1.0; 1.0 by default.

  The color of the foreground grid squares is always equal to the three first bytes of the
  hash of `text`, regardless of which hashing function is used automatically.

  Setting `bg_color` to `nil` (default value) generates only the foreground (colored) squares,
  with the default (1.0) or requested `opacity`.

  _New since v0.9.0:_ Setting `padding` to a positive integer sets the padding to the identicon to that value. If `bg_color` is non-nil, it will also be applied to the padding area with the with the default (1.0) or requested `opacity`, which is applied the same on the foreground and the background. The file size is greatly reduced.

  _New since v0.8.0:_ Setting `bg_color` to one of the following 3 atom values sets the color of the background squares to the corresponding RGB-complementary color of the automatically-defined foreground color, with the default (1.0) or requested `opacity`:
  * `:basic`: the complementary color, i.e. the opposite color of `fg_color` on the color wheel.
  * `:split1`: the first adjacent tertiary color of the complement of `fg_color` on the color wheel.
  * `:split2`: the second adjacent tertiary color of the complement of `fg_color` on the color wheel.

  ## Examples

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


  """

  def generate(text, size \\ 5, bg_color \\ nil, opacity \\ 1.0, padding \\ 0)
      when is_bitstring(text) and size in 4..10 and
             (is_bitstring(bg_color) or is_nil(bg_color) or is_atom(bg_color)) and
             is_float(opacity) and is_integer(padding) and padding >= 0 do
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
    |> generate_svg()
    |> return_svg()
  end

  def return_svg(%Identicon{svg: svg}) when is_bitstring(svg) do
    svg
  end

  def generate_svg(
        %Identicon{
          paths: paths,
          size: size,
          padding: padding,
          fg_color: fg_color,
          bg_color: bg_color,
          opacity: opacity
        } = input
      ) do
    svg = Draw.svg(paths, size, padding, fg_color, bg_color, opacity)

    %{input | svg: svg}
  end

  def trace_polygon_edges_to_paths(%Identicon{edges: edges} = input) do
    paths =
      edges
      |> EdgeTracer.doit()
      |> Enum.map(&hd/1)

    %{input | paths: paths}
  end

  def convert_polygons_into_edgelists(
        %Identicon{polygons: polygons, size: size} = input
      ) do
    edges =
      polygons
      |> Enum.map(&EdgeCleaner.polygon_external_edges(&1, size))

    %{input | edges: edges}
  end

  def find_neighboring_squares(%Identicon{squares: squares, size: size} = input) do
    neighbors =
      squares
      |> PolygonReducer.neighbors_per_index(size)

    %{input | neighbors: neighbors}
  end

  def group_neighbors_into_polygons(%Identicon{neighbors: neighbors} = input) do
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

  def hash_input(%Identicon{text: text, size: size} = input) do
    grid =
      appropriate_hash(size)
      |> :crypto.hash(text)
      |> :binary.bin_to_list()

    %{input | grid: grid}
  end

  def extract_colors(%Identicon{grid: grid, bg_color: bg_color} = input) do
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

  def square_grid(%Identicon{grid: grid, size: size} = input) do
    odd = rem(size, 2)
    chunks = Integer.floor_div(size, 2) + odd

    grid =
      grid
      |> Enum.chunk_every(chunks)
      |> Enum.slice(0, size)
      |> Enum.map(&mirror_row(&1, odd))
      |> List.flatten()

    %{input | grid: grid}
  end

  def extract_foreground_squares(%Identicon{grid: grid} = input) do
    presence =
      grid
      |> Stream.map(fn x -> 1 - rem(x, 2) end)
      |> Stream.with_index()
      |> Stream.map(&Tuple.to_list/1)
      |> Stream.map(&Enum.reverse/1)
      |> Stream.map(&List.to_tuple/1)
      |> Map.new()

    fg =
      presence
      |> Enum.filter(fn {_k, v} -> v == 1 end)
      |> Map.new()
      |> Map.keys()

    input
    |> Map.put(
      :squares,
      fg
    )
  end

  def keys_by_value(m, value) when is_map(m) do
    m
    |> Enum.filter(fn {_k, v} -> v == value end)
    |> Map.new()
    |> Map.keys()
  end

  def generate_coordinates(%Identicon{grid: grid} = input) do
    grid =
      grid
      |> Enum.with_index()

    %{input | grid: grid}
  end

  defp mirror_row(row, odd) when odd in 0..1 do
    mirror =
      row
      |> Enum.slice(0, length(row) - odd)
      |> Enum.reverse()

    row ++ mirror
  end

  defp determine_background_color(fg_color, bg_color)
       when is_bitstring(fg_color) and is_atom(bg_color) and
              bg_color in [:basic, :split1, :split2] do
    fg_color
    |> Color.hex_to_rgb()
    |> Color.color_wheel(compl: bg_color)
    |> Color.rgb_to_hex6()
  end

  defp determine_background_color(_fg_color, bg_color)
       when is_bitstring(bg_color) or is_nil(bg_color) do
    bg_color
  end

  defp determine_background_color(_fg_color, bg_color) when is_nil(bg_color) do
    nil
  end
end
