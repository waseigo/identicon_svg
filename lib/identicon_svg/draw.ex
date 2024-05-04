# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Draw do
  require EEx

  alias IdenticonSvg.Geometry
  alias IdenticonSvg.Geometry.{ShapeField, Polygon}

  @moduledoc """
  Module of `IdenticonSvg` that contains functions related to drawing SVG elements.
  """
  @moduledoc since: "0.9.0"

  EEx.function_from_string(
    :defp,
    :svg_rectangle_template,
    ~s(  <rect width="20" height="20" x="<%= x_coord %>" y="<%= y_coord %>" style="stroke: <%= color %>; stroke-width: 0; stroke-opacity: <%= opacity %>; fill: <%= color %>; fill-opacity: <%= opacity %>;"/>\n),
    [:x_coord, :y_coord, :color, :opacity]
  )

  @doc """
  Generate an SVG rectangle.
  """
  def svg_rectangle(x_coord, y_coord, color, opacity) do
    svg_rectangle_template(x_coord, y_coord, color, opacity)
  end

  EEx.function_from_string(
    :defp,
    :svg_preamble_template,
    ~s(<svg version="1.1" width="20mm" height="20mm" viewBox="0 0 <%= length %> <%= length %>" preserveAspectRatio="xMidYMid meet" shape-rendering="crispEdges" xmlns="http://www.w3.org/2000/svg">\n),
    [:length]
  )

  @doc """
  Generate the preamble (opening `<svg>` tag with arguments) of the identicon SVG content.
  """
  def svg_preamble(length) do
    svg_preamble_template(length)
  end

  EEx.function_from_string(
    :defp,
    :svg_path_template,
    ~s(  <path d="<%= path_d %>" style="stroke: <%= color %>; stroke-width: 0; stroke-opacity: <%= opacity %>; fill: <%= color %>; fill-opacity: <%= opacity %>;"/>\n),
    [:path_d, :color, :opacity]
  )

  @doc """
  Convert a list of path coordinates to an SVG path attribute `d`.
  """

  def path_coords_to_string([moveto | linetos] = coords) when is_list(coords) do
    moveto = ["M" | moveto]

    linetos =
      linetos
      |> Enum.map(fn lineto ->
        ["L" | lineto]
      end)

    [moveto, linetos, "z"]
    |> List.flatten()
    |> Enum.join(" ")
  end

  @doc """
  Generate an SVG path.
  """
  def svg_path_polygon(path_d, color, opacity) do
    svg_path_template(path_d, color, opacity)
  end

  @doc """
  Convert an %IdenticonSvg.Polygon{} to the `d` attribute string of an SVG path.
  """
  def polygon_to_path_d(%Polygon{} = input, scale \\ 20)
      when is_integer(scale) do
    input
    |> Geometry.polygon_to_edgelist()
    |> scale_coords(scale)
    |> path_coords_to_string()
  end

  def scale_coords(coords, scale \\ 20)
      when is_list(coords) and is_integer(scale) do
    coords
    |> List.flatten()
    |> Enum.map(&Kernel.*(&1, scale))
    |> Enum.chunk_every(2)
  end
end
