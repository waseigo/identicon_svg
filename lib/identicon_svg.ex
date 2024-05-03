# SPDX-FileCopyrightText: 2023 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule Identicon do
  @moduledoc """
  Defines the `%Identicon{}` struct used by the functions of the main
  module to gradually process and generate an identicon.
  """
  @moduledoc since: "0.1.0"
  defstruct text: nil,
            size: 5,
            fg_color: nil,
            grid: nil,
            svg: nil,
            bg_color: nil,
            opacity: 1.0,
            padding: 0
end

defmodule IdenticonSvg do
  require EEx

  alias IdenticonSvg.{Color, Draw}

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
    |> generate_coordinates()
    |> color_all_squares()
    |> output_svg()
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

  def mark_present_squares(%Identicon{grid: grid} = input) do
    grid =
      grid
      |> Enum.map(fn x -> 1 - rem(x, 2) end)

    %{input | grid: grid}
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
        &square_to_rect(&1, fg_color, bg_color, opacity, size, padding)
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

  def index_to_coords(index, divisor, padding \\ 0)
      when is_integer(index) and is_integer(divisor) and is_integer(padding) and
             padding >= 0 do
    %{
      x: (rem(index, divisor) + padding) * 20,
      y: (div(index, divisor) + padding) * 20
    }
  end

  def square_to_rect(
        {presence, index},
        fg_color,
        bg_color,
        opacity,
        divisor,
        padding
      )
      when is_bitstring(bg_color) or is_atom(bg_color) do
    %{x: x_coord, y: y_coord} = index_to_coords(index, divisor, padding)

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

  defp output_svg(%Identicon{svg: svg, size: size, padding: padding}) do
    pre = Draw.svg_preamble((size + padding * 2) * 20)
    post = "</svg>"

    pre <> List.to_string(svg) <> post
  end
end
