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
end
