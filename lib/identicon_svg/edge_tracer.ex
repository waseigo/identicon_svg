defmodule IdenticonSvg.EdgeTracer do
  def connect(polygon_edges)
      when is_list(polygon_edges) and polygon_edges != [] do
    connect(polygon_edges, [])
  end

  def connect(candidates, []) do
    [edge | candidates_new] = candidates
    connect(candidates_new, [edge])
  end

  def connect(candidates, connected) when candidates != [] do
    IO.inspect([connected, candidates])
    IO.puts("\n")
    previous_edge = hd(connected)
    neighbors = find_neighbors(previous_edge, candidates)

    next_neighbor = hd(neighbors)

    connected_new = [direct(next_neighbor, previous_edge) | connected]
    candidates_new = List.delete(candidates, next_neighbor)

    connect(candidates_new, connected_new)
  end

  def connect([], fully_connected) do
    fully_connected
  end

  def direct([_a, b] = current, [c, _d] = _previous) do
    if b == c do
      current
    else
      Enum.reverse(current)
    end
  end

  def find_neighbors([], _candidates) do
    []
  end

  def find_neighbors(edge, candidates) do
    candidates
    |> Enum.filter(
      &(MapSet.disjoint?(MapSet.new(&1), MapSet.new(edge)) == false)
    )
  end
end
