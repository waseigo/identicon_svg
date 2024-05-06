# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.PolygonReducer do
  @moduledoc """
  Module incorporating functions that find neighboring squares and use `Enum.reduce/3` to group them into polygons.
  """
  @moduledoc since: "1.0.0"

  def group(neighbors_per_indexed_square) do
    g = fn x -> group_into_polygons(x) end
    Enum.reduce_while(
      1..100,
      neighbors_per_indexed_square,
      fn _iteration, acc ->
        new_grouping = g.(acc)
        if new_grouping != acc do
          {:cont, new_grouping}
        else
          {:halt, acc}
        end
      end
    )
  end

  def group_into_polygons(neighbors_per_indexed_square)
      when is_map(neighbors_per_indexed_square) do
    neighbors_per_indexed_square
    |> Enum.reduce(
      %{},
      fn {index, neighbors}, polygons ->
      reducer({index, neighbors}, polygons)
    end)
    |> Enum.map(fn {k, v} -> {k, Enum.uniq(v)} end)
    |> Map.new()
  end

  def reducer({index, neighbors}, polygons) do
    # IO.puts("\n---------------------------------------------------------------------------")


    # IO.puts("\nStarting state:")
    # IO.inspect(polygons, charlists: :as_chars)

    # IO.puts("\nNow considering:")
    # IO.inspect({index, neighbors}, charlists: :as_chars)

    not_seen_before =
      polygons
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()
      |> disjoint?(neighbors)

    if not_seen_before do
      polygons
      |> Map.put(index, Enum.uniq([index | neighbors]))
    else
      existing_polygon_index =
        polygons
        |> Map.filter(fn {_k, v} ->
          disjoint?(neighbors, v) == false
        end)
        |> Map.keys()
        |> hd()

      new_polygon_content =
        polygons
        |> Map.get(existing_polygon_index)
        |> Kernel.++(neighbors)

      polygons
      |> Map.put(existing_polygon_index, new_polygon_content)
    end
  end

  def disjoint?(a, b) when is_list(a) and is_list(b) do
    MapSet.disjoint?(MapSet.new(a), MapSet.new(b))
  end



  def index_to_col_row(index, divisor) do
    col = rem(index, divisor)
    row = div(index, divisor)

    [col, row]
  end

  def col_row_neighbors([col, row], divisor) do
    [
      [col, row - 1],
      [col + 1, row],
      [col, row + 1],
      [col - 1, row]
    ]
    |> Enum.filter(&within_bounds(&1, divisor))
  end

  def within_bounds([col, row], divisor) do
    col >= 0 and row >= 0 and col < divisor and row < divisor
  end

  def index_neighbors(index, divisor) do
    index_to_col_row(index, divisor)
    |> col_row_neighbors(divisor)
    |> Enum.map(&col_row_to_index(&1, divisor))
  end

  def col_row_to_index([col, row], divisor) do
    col + row * divisor
  end

  def neighbors_per_index(indexes, divisor) do
    indexes
    |> Enum.map(fn index ->
      {index,
       indexes
       |> MapSet.new()
       |> MapSet.intersection(MapSet.new(index_neighbors(index, divisor)))
       |> MapSet.to_list()}
    end)
    |> Map.new()
  end
end
