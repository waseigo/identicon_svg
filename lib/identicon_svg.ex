# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg do
  alias IdenticonSvg.{Identicon, Color, Draw, PolygonHelper}

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
      bg_color: bg_color,
      opacity: opacity,
      padding: padding
    }
    |> hash_input()
    |> extract_color()
    |> square_grid()
    |> mark_present_squares()
    |> extract_both_layer_polygons()

    # |> all_edges_of_all_rectangles(layer: :fg)

    #    |> Geometry.shape_field(layer: :fg)
    #    |> Map.get(:fg)
    #    |> Enum.map(&IdenticonSvg.Draw.polygon_to_path_d(&1))
    #    |> Enum.map(&IdenticonSvg.Draw.svg_path_polygon(&1, "#f00", 1.0))
    #    |> IO.puts

    # |> Geometry.shape_field()

    # |> Geometry.edge_allocation(layer: :fg)
    # |> Geometry.edge_allocation(layer: :bg)

    # |> generate_coordinates()
    #    |> color_all_squares()
    #    |> output_svg()
  end

  def extract_both_layer_polygons(%Identicon{} = input) do
    fg_polygons = extract_polygon_edges(input, layer: :fg)

    bg_polygons =
      case input.bg_color do
        nil -> nil
        _ -> extract_polygon_edges(input, layer: :bg)
      end

    input
    |> Map.put(:fg_polygons, fg_polygons)
    |> Map.put(:bg_polygons, bg_polygons)
  end

  def extract_polygon_edges(%Identicon{} = input, layer: layer) do
    input
    |> all_edges_of_all_rectangles(layer: layer)
    |> Map.get(layer)
    |> PolygonHelper.connect()
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

  def extract_color(%Identicon{grid: grid} = input) do
    fg_color =
      grid
      |> Enum.chunk_every(3)
      |> hd()
      |> Enum.map(&Color.integer_to_hex/1)
      |> List.to_string()
      |> String.downcase()

    %{input | fg_color: "#" <> fg_color}
  end

  def square_grid(%Identicon{grid: grid, size: size, padding: padding} = input) do
    odd = rem(size, 2)
    chunks = Integer.floor_div(size, 2) + odd

    grid_max = Enum.max(grid)
    padding_list_x = List.duplicate(grid_max, padding)

    padding_list_y =
      grid_max
      |> List.duplicate(size + 2 * padding)
      |> List.duplicate(padding)

    grid =
      grid
      |> Enum.chunk_every(chunks)
      |> Enum.slice(0, size)
      |> Enum.map(&Kernel.++(padding_list_x, &1))
      |> Enum.map(&mirror_row(&1, odd))
      |> then(&Kernel.++(padding_list_y, &1))
      |> Kernel.++(padding_list_y)
      |> List.flatten()

    %{input | grid: grid}
  end

  def mark_present_squares(
        %Identicon{grid: grid, size: size, padding: padding} = input
      ) do
    grid =
      grid
      |> Enum.map(fn x -> 1 - rem(x, 2) end)
      |> Enum.with_index()
      |> Enum.map(fn {presence, index} ->
        %{
          index: index,
          presence: presence
        }
        |> Map.merge(index_to_col_row(index, size + 2 * padding))
      end)

    fg = grid |> Enum.filter(&(Map.get(&1, :presence) == 1))
    bg = grid -- fg

    %{input | fg: fg, bg: bg}
  end

  def generate_coordinates(%Identicon{grid: grid} = input) do
    grid =
      grid
      |> Enum.with_index()

    %{input | grid: grid}
  end

  def color_all_squares(
        %Identicon{
          grid: grid,
          size: size,
          fg_color: fg_color,
          bg_color: bg_color,
          opacity: opacity,
          padding: padding
        } = input
      ) do
    bg_color = determine_background_color(fg_color, bg_color)

    svg =
      grid
      |> Enum.map(
        &square_to_rect(&1, fg_color, bg_color, opacity, size + 2 * padding)
      )

    %{input | svg: svg}
  end

  defp mirror_row(row, odd) when odd in 0..1 do
    mirror =
      row
      |> Enum.slice(0, length(row) - odd)
      |> Enum.reverse()

    row ++ mirror
  end

  def index_to_coords(index, divisor)
      when is_integer(index) and is_integer(divisor) do
    %{
      x: rem(index, divisor),
      y: div(index, divisor)
    }
  end

  def square_to_rect(
        {presence, index},
        fg_color,
        bg_color,
        opacity,
        divisor
      )
      when is_bitstring(bg_color) or is_atom(bg_color) do
    %{x: x_coord, y: y_coord} = index_to_coords(index, divisor)

    case {presence, bg_color} do
      {0, nil} ->
        ""

      {0, _} ->
        Draw.svg_rectangle(x_coord, y_coord, bg_color, opacity)

      {1, _} ->
        Draw.svg_rectangle(x_coord, y_coord, fg_color, opacity)
    end
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

  def output_svg(%Identicon{svg: svg, size: size, padding: padding}) do
    pre = Draw.svg_preamble((size + padding * 2) * 20)
    post = "</svg>"

    pre <> List.to_string(svg) <> post
  end

  def module_count(%Identicon{size: size, padding: padding}) do
    size + 2 * padding
  end

  def point_equals({x1, y1}, {x2, y2}) do
    x1 == x2 and y1 == y2
  end

  def index_to_col_row(index, divisor) do
    col = rem(index, divisor)
    row = div(index, divisor)

    %{col: col, row: row}
  end

  def all_edges_of_rectangle(%{col: x0, row: y0}) do
    # %{col: x0, row: y0} = index_to_col_row(index, divisor)

    x1 = x0 + 1
    y1 = y0 + 1

    vertices = [
      {x0, y0},
      {x1, y0},
      {x1, y1},
      {x0, y1}
    ]

    (vertices ++ [List.first(vertices)])
    |> Enum.chunk_every(2, 1, :discard)

    # |> Enum.map(&MapSet.new/1)
  end

  def all_edges_of_all_rectangles(%Identicon{} = input, layer: layer) do
    edges =
      input
      |> Map.get(layer)
      |> Enum.map(&all_edges_of_rectangle/1)
      |> Enum.concat()
      |> remove_duplicate_edges()

    input
    |> Map.put(layer, edges)
  end

  def remove_duplicate_edges(edges) do
    remove_duplicate_edges(edges, [])
  end

  defp remove_duplicate_edges([], result), do: result

  defp remove_duplicate_edges([edge | rest], result) do
    case find_duplicate_edge(rest, edge) do
      {j, _} ->
        # Found a duplicate edge, remove both i and j
        new_rest = List.delete_at(rest, j)
        remove_duplicate_edges(new_rest, result)

      _ ->
        # No duplicate edge found, keep i
        remove_duplicate_edges(rest, [edge | result])
    end
  end

  defp find_duplicate_edge([], _), do: nil

  defp find_duplicate_edge([edge | rest], target) do
    if point_equals(List.first(target), List.last(edge)) &&
         point_equals(List.last(target), List.first(edge)) do
      {0, edge}
    else
      case find_duplicate_edge(rest, target) do
        {j, a} -> {j + 1, a}
        _ -> nil
      end
    end
  end
end
