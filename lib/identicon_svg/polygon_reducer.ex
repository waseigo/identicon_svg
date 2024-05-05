defmodule IdenticonSvg.PolygonReducer do
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

  def doit(s) do
    Enum.reduce(s, %{allocations: %{}}, fn {index, neighbors},
                                                        polygons ->
      reducer({index, neighbors}, polygons)
    end)
  end

  def reducer({index, neighbors}, polygons) do
    IO.puts("\n")
    IO.inspect([{index, neighbors}, polygons], charlists: :as_lists)

    # if index not in polygons[:visited] do
    #    IO.inspect(polygons)
    allocated =
      polygons[:allocations]
      |> Map.values()
      |> List.flatten()
      |> Enum.uniq()
      |> disjoint?(neighbors)
      |> Kernel.not()

    if not allocated do
      IO.puts("index #{index} NOT in allocated")

      allocations =
        polygons[:allocations]
        |> Map.put(index, Enum.uniq([index | neighbors]))

      polygons
      |> Map.put(:allocations, allocations)
      #|> Map.put(:visited, polygons[:visited] ++ [index])
    else
      IO.puts("index #{index} IN allocated")

      x =
        polygons[:allocations]
        |> Map.filter(fn {_k, v} ->
          disjoint?(neighbors, v) == false
        end)
        |> IO.inspect(charlists: :as_lists)
        |> Map.keys()
        |> hd()

      xx =
        polygons[:allocations]
        |> Map.get(x)
        |> Kernel.++(neighbors)
        |> Enum.uniq()

      xxx =
        polygons[:allocations]
        |> Map.put(x, xx)

      polygons
      |> Map.put(:allocations, xxx)
      #|> Map.put(:visited, polygons[:visited] ++ [index])

      # end
    end
  end

  def disjoint?(a, b) when is_list(a) and is_list(b) do
    MapSet.disjoint?(MapSet.new(a), MapSet.new(b))
  end
end
