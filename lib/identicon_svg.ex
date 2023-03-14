defmodule Identicon do
  @moduledoc """
  Defines the `%Identicon{}` struct used by the functions of the main
  module to gradually process and generate an identicon.
  """
  defstruct text: nil, size: 5, rgb: nil, grid: nil, svg: nil, bg_color: nil, opacity: 1.0
end

defmodule IdenticonSvg do
  require EEx

  @moduledoc """
  Main module of `IdenticonSvg` that contains all functions of the library.
  """

  @doc """
  Generate the SVG code of the identicon for the specified `text`.

  Without specifying any optional arguments this function generates a 5x5 identicon
  with a transparent background and colored grid squares with full opacity.

  Optionally, specify any combination of the following arguments:

  * `size`: the number of grid squares of the identicon's side; integer, 4 to 10; 5 by default.
  * `bg_color`: the color of the background grid squares; string, hex code (e.g., `#eee`); `nil` by default.
  * `opacity`: the opacity of the entire identicon (all grid squares); float, 0.0 to 1.0; 1.0 by default.

  Setting `bg_color` to `nil` (default value) generates only the foreground (colored) squares,
  with the default (1.0) or requested `opacity`.

  The color of the grid squares is always equal to the three first bytes of the
  hash of `text`, regardless of which hashing function is used automatically.

  A different hashing function is used automatically for each identicon `size`,
  so that the utilization of bits is maximized for the given size: MD5 for sizes 4 and 5, RIPEMD-160 for 6, and SHA3 for 7 to 10 with 224, 256, 384 and 512 bits, respectively.

  ## Examples

  5x5 identicon with transparent background:
  ```elixir
  generate("banana")
  ```
  ![5x5 identicon for "banana", at full opacity, with transparent background](assets/banana_5x5_nil_1p0.svg)


  6x6 identicon with transparent background:
  ```elixir
  generate("pineapple", 6)
  ```
  ![6x6 identicon for "pineapple", at full opacity, with transparent background](assets/pineapple_6x6_nil_1p0.svg)



  7x7 identicon with light gray (`#d3d3d3`) background:
  ```elixir
  generate("refrigerator", 7, "#d3d3d3")
  ```
  ![7x7 identicon for "refrigerator", at full opacity, with light gray background](assets/refrigerator_7x7_d3d3d3_1p0.svg)


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

  def generate(text, size \\ 5, bg_color \\ nil, opacity \\ 1.0) when is_bitstring(text) and size in 4..10 and (is_bitstring(bg_color) or is_nil(bg_color)) and is_float(opacity) do
    %Identicon{text: text, size: size, bg_color: bg_color, opacity: opacity}
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
      10 => :sha3_512,
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

  defp extract_color(%Identicon{grid: grid} = input) do
    rgb =
      grid
      |> Enum.chunk_every(3)
      |> hd()
      |> Enum.map(&integer_to_hex/1)
      |> List.to_string()
      |> String.downcase()

    %{input | rgb: "#" <> rgb}
  end

  defp integer_to_hex(value) when is_integer(value) and value in 0..255 do
    Integer.to_string(value, 16)
    |> String.pad_leading(2, "0")
  end

  defp square_grid(%Identicon{grid: grid, size: size} = input) do
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

  defp mirror_row(row, odd) when odd in 0..1 do
    mirror =
      row
      |> Enum.slice(0, length(row) - odd)
      |> Enum.reverse()

    row ++ mirror
  end

  defp mark_present_squares(%Identicon{grid: grid} = input) do
    grid =
      grid
      |> Enum.map(fn x -> 1 - rem(x, 2) end)

    %{input | grid: grid}
  end

  defp generate_coordinates(%Identicon{grid: grid} = input) do
    grid =
      grid
      |> Enum.with_index()

    %{input | grid: grid}
  end

  defp color_all_squares(
        %Identicon{grid: grid, size: size, rgb: fg_color, bg_color: bg_color, opacity: opacity} = input
      ) do
    svg =
      grid
      |> Enum.map(&square_to_rect(&1, fg_color, bg_color, opacity, size))

    %{input | svg: svg}
  end

  EEx.function_from_string(
    :defp,
    :svg_rectangle,
    ~s(  <rect width="20" height="20" x="<%= x_coord %>" y="<%= y_coord %>" style="stroke: <%= color %>; stroke-width: 0; stroke-opacity: <%= opacity %>; fill: <%= color %>; fill-opacity: <%= opacity %>;"/>\n),
    [:x_coord, :y_coord, :color, :opacity]
  )

  EEx.function_from_string(
    :defp,
    :svg_preamble,
    ~s(<svg version="1.1" width="20mm" height="20mm" viewBox="0 0 <%= length %> <%= length %>" preserveAspectRatio="xMidYMid meet" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg">\n),
    [:length]
  )

  defp square_to_rect(
        {presence, index},
        fg_color,
        bg_color,
        opacity,
        divisor
      ) do
    %{x: x_coord, y: y_coord} = index_to_coords(index, divisor)

    case {presence, bg_color} do
      {0, nil} ->
        ""
      {0, _} -> svg_rectangle(x_coord, y_coord, bg_color, opacity)

      {1, _} -> svg_rectangle(x_coord, y_coord, fg_color, opacity)
      end
  end

  defp index_to_coords(index, divisor) when is_integer(divisor) do
    %{
      x: rem(index, divisor) * 20,
      y: div(index, divisor) * 20
    }
  end

  defp output_svg(%Identicon{svg: svg, size: size}) do
    pre = svg_preamble(size*20)
    post = "</svg>"

    pre <> List.to_string(svg) <> post
  end
end
