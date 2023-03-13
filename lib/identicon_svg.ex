defmodule Identicon do
  @moduledoc """
  Documentation for `Identicon`.
  """
  defstruct text: nil, size: 5, rgb: nil, grid: nil, svg: nil, bg_color: nil, opacity: 1.0
end

defmodule IdenticonSvg do
  require EEx

  @moduledoc """
  Documentation for `IdenticonSvg`.
  """

  def generate(text, size \\ 5, bg_color \\ nil, opacity \\ 1.0) do
    %Identicon{text: text, size: size, bg_color: bg_color, opacity: opacity}
    |> hash_input()
    |> extract_color()
    |> square_grid()
    |> mark_present_squares()
    |> generate_coordinates()
    |> color_all_squares()
    |> output_svg()
  end

  def appropriate_hash(size) when size in 4..10 do
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

  def hash_input(%Identicon{text: text, size: size} = input) do
    grid =
      appropriate_hash(size)
      |> :crypto.hash(text)
      |> :binary.bin_to_list()

    %{input | grid: grid}
  end

  def extract_color(%Identicon{grid: grid} = input) do
    rgb =
      grid
      |> Enum.chunk_every(3)
      |> hd()
      |> Enum.map(&integer_to_hex/1)
      |> List.to_string()
      |> String.downcase()

    %{input | rgb: "#" <> rgb}
  end

  def integer_to_hex(value) when is_integer(value) and value in 0..255 do
    Integer.to_string(value, 16)
    |> String.pad_leading(2, "0")
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

  def mirror_row(row, odd \\ 1) when odd in 0..1 do
    mirror =
      row
      |> Enum.slice(0, length(row) - odd)
      |> Enum.reverse()

    row ++ mirror
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
        %Identicon{rgb: rgb, grid: grid, opacity: opacity, size: size, bg_color: bg_color} = input
      ) do
    svg =
      grid
      |> Enum.map(&square_to_rect(&1, rgb, bg_color, opacity, size))

    %{input | svg: svg}
  end

  @doc """
  Generate an SVG rectangle from the `lib/rect.xml.eex` template and the parameters
  for the foreground color, the overall opacity, and the rectangle's coordinates.
  """
  EEx.function_from_string(
    :def,
    :svg_rectangle,
    ~s(<rect style="fill:<%= color %>;fill-opacity:<%= opacity %>;stroke:none" width="20" height="20" x="<%= x_coord %>" y="<%= y_coord %>"/>),
    [:color, :opacity, :x_coord, :y_coord]
  )

  EEx.function_from_string(
    :def,
    :svg_preamble,
    ~s(<svg version="1.1" width="20mm" height="20mm" viewBox="0 0 <%= length %> <%= length %>" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg">),
    [:length]
  )

  def square_to_rect(
        {presence, index},
        fg_color,
        bg_color \\ nil,
        opacity \\ 1.0,
        divisor \\ 5
      ) do
    %{x: x_coord, y: y_coord} = index_to_coords(index, divisor)


    case {presence, bg_color} do
      {0, nil} ->
        ""
      {0, bg_color} -> svg_rectangle(bg_color, opacity, x_coord, y_coord)

      {1, _} -> svg_rectangle(fg_color, opacity, x_coord, y_coord)
      end
  end

  def index_to_coords(index, divisor \\ 5) when is_integer(divisor) do
    %{
      x: rem(index, divisor) * 20,
      y: div(index, divisor) * 20
    }
  end

  def output_svg(%Identicon{svg: svg, size: size}) do
    pre = svg_preamble(size*20)
    post = "</svg>"

    pre <> List.to_string(svg) <> post
  end
end
