defmodule Identicon do
  @moduledoc """
  Documentation for `Identicon`.
  """
  defstruct text: nil, rgb: nil, grid: nil, svg: nil, opacity: 1.0
end

defmodule IdenticonSvg do
  require EEx

  @moduledoc """
  Documentation for `IdenticonSvg`.
  """

  def generate(text) do
    %Identicon{text: text}
    |> hash_input()
    |> extract_color()
    |> square_grid()
    |> mark_present_squares()
    |> generate_coordinates()
    |> color_all_squares()
    |> output_svg()
  end

  def hash_input(%Identicon{text: text} = input) do
    grid =
      :crypto.hash(:md5, text)
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

  def square_grid(%Identicon{grid: grid} = input) do
    grid =
      grid
      |> Enum.chunk_every(3)
      |> Enum.filter(fn x -> length(x) == 3 end)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()

    %{input | grid: grid}
  end

  def mirror_row(row) do
    [a, b, _] = row
    row ++ [b, a]
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
        %Identicon{rgb: rgb, grid: grid, opacity: opacity} = input
      ) do
    svg =
      grid
      |> Enum.map(&square_to_rect(&1, rgb, "#fff", opacity))

    %{input | svg: svg}
  end

  @doc """
  Generate an SVG rectangle from the `lib/rect.xml.eex` template and the parameters
  for the foreground color, the overall opacity, and the rectangle's coordinates.  """
  EEx.function_from_file(
    :def,
    :svg_rectangle,
    "lib/rect.xml.eex",
    [:color, :opacity, :x_coord, :y_coord]
  )

  def square_to_rect(
        {presence, index},
        fg_color,
        bg_color \\ "#ffffff",
        opacity \\ 1.0
      ) do
    %{x: x_coord, y: y_coord} = index_to_coords(index)

    if presence == 0 do
      svg_rectangle(bg_color, opacity, x_coord, y_coord)
    else
      svg_rectangle(fg_color, opacity, x_coord, y_coord)
    end
  end

  def index_to_coords(index) when index in 0..24 do
    %{
      x: rem(index, 5) * 20,
      y: div(index, 5) * 20
    }
  end

  def output_svg(%Identicon{svg: svg}) do
    pre =
      ~s(<svg width="100mm" height="100mm" viewBox="0 0 100 100" version="1.1" xmlns="http://www.w3.org/2000/svg">)

    post = "</svg>"

    pre <> List.to_string(svg) <> post
  end
end
