# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.PolygonReducer do
  @moduledoc """
  Module incorporating functions that find neighboring squares and use `Enum.reduce/3` to group them into polygons.
  """
  @moduledoc since: "1.0.0"

  # def group(neighbors, divisor) when is_map(neighbors) and is_integer(divisor) do
  #   neighbors
  #   |> group_into_polygons()
  #   #|> group_into_polygons()
  #   |> Map.values()
  # end

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

  def group_into_polygons(neighbors_per_indexed_square)
      when is_map(neighbors_per_indexed_square) do
    neighbors_per_indexed_square
    |> Enum.reduce(
      %{allocations: %{}, visited: []},
      fn {index, neighbors}, polygons ->
      reducer({index, neighbors}, polygons)
    end)
    |> Map.get(:allocations)
    |> Enum.map(fn {k, v} -> {k, Enum.uniq(v)} end)
    |> Map.new()
  end

  def reducer({index, neighbors}, polygons) do
    IO.puts("\n---------------------------------------------------------------------------")


    IO.puts("\nStarting state:")
    IO.inspect(polygons, charlists: :as_chars)

    IO.puts("\nNow considering:")
    IO.inspect({index, neighbors}, charlists: :as_chars)


    no_allocations_yet = polygons.allocations == %{}

    not_already_allocated =
      polygons.allocations
      |> Map.values()
      |> List.flatten()
      |> disjoint?(neighbors)

    not_visited_before = index not in polygons.visited

    visited_new = [index | polygons.visited]

    if no_allocations_yet do
      IO.puts "Nothing allocated yet..."
      allocations_new =
        polygons.allocations
        |> Map.put(index, Enum.uniq([index | neighbors]))

      polygons
      |> Map.put(:allocations, allocations_new)
      |> Map.put(:visited, visited_new)
    else


    if not_already_allocated, do: IO.puts "Index #{index} NOT ALREADY ALLOCATED!"
    if not_visited_before, do: IO.puts "Index #{index} NOT VISITED BEFORE!"

    if not_already_allocated and not_visited_before do
      allocations_new =
        polygons.allocations
        |> Map.put(index, Enum.uniq([index | neighbors]))

      polygons
      |> Map.put(:allocations, allocations_new)
      |> Map.put(:visited, visited_new)
    else
      existing_polygon_index =
        polygons.allocations
        |> Map.filter(fn {_k, v} ->
          disjoint?(neighbors, v) == false
        end)
        |> Map.keys()
        |> hd()

      new_polygon_content =
        polygons.allocations
        |> Map.get(existing_polygon_index)
        |> Kernel.++(neighbors)

      allocations_new =
        polygons.allocations
        |> Map.put(existing_polygon_index, new_polygon_content)

      polygons
      |> Map.put(:allocations, allocations_new)
      |> Map.put(:visited, visited_new)
    end
  end
  end

  def disjoint?(a, b) when is_list(a) and is_list(b) do
    MapSet.disjoint?(MapSet.new(a), MapSet.new(b))
  end
end
