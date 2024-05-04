# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Draw do
  require EEx

  @moduledoc """
  Module of `IdenticonSvg` that contains functions related to drawing SVG elements.
  """
  @moduledoc since: "0.9.0"

  EEx.function_from_string(
    :defp,
    :svg_g_template,
    ~s(  <g style="stroke: <%= color %>; stroke-width: 0; stroke-opacity: <%= opacity %>; fill: <%= color %>; fill-opacity: <%= opacity %>;">\n<%= content %>  </g>\n),
    [:content, :color, :opacity]
  )

  @doc """
  Generate an SVG group with styling.
  """
  def svg_g(content, color, opacity) do
    svg_g_template(content, color, opacity)
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
    ~s(    <path d="<%= path_d %>"/>\n),
    [:path_d]
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
  def svg_path_polygon(path_d) do
    svg_path_template(path_d)
  end

  @doc """
  Convert an polygon (list of edges in sequence) to the `d` attribute string of an SVG path.
  """
  def polygon_to_path_d(polygon, scale \\ 20)
      when is_integer(scale) and is_list(polygon) do
    polygon
    |> List.flatten()
    |> Enum.uniq()
    |> scale_coords(scale)
    |> path_coords_to_string()
  end

  def scale_coords(coords, scale \\ 20)
      when is_list(coords) and is_integer(scale) do
    coords
    |> Enum.map(&Tuple.to_list/1)
    |> List.flatten()
    |> Enum.map(&Kernel.*(&1, scale))
    |> Enum.chunk_every(2)
  end
end
