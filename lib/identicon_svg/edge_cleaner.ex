# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.EdgeCleaner do
  @moduledoc """
  Module incorporating functions that remove internal edges shared between squares grouped into a polygon.
  """
  @moduledoc since: "1.0.0"

  alias IdenticonSvg.{EdgeTracer, PolygonReducer}

  def polygon_external_edges(polygon, divisor) do
    polygon
    |> Enum.map(&edges_of_rectangle_with_index(&1, divisor))
    |> Enum.concat()
    |> remove_duplicate_edges()
    |> EdgeTracer.connect()
  end

  def edges_of_rectangle_with_index(index, divisor) do
    [x0, y0] = PolygonReducer.index_to_col_row(index, divisor)
    all_edges_of_rectangle({x0, y0})
  end

  def all_edges_of_rectangle({x0, y0}) do
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
  end

  def remove_duplicate_edges(edges) do
    edges
    |> Enum.map(&MapSet.new/1)
    |> Enum.frequencies()
    |> Map.filter(fn {_k, v} -> v == 1 end)
    |> Map.keys()
    |> Enum.map(&MapSet.to_list/1)
    |> Enum.sort()
  end
end
