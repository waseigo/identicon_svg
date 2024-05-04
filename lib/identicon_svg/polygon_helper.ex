defmodule IdenticonSvg.PolygonHelper do
  def connect(all_edges) when is_list(all_edges) and all_edges != [] do
    connect(all_edges, [])
  end

  def connect(candidates, []) do
    [edge | candidates_new] = candidates
    connect(candidates_new, [edge])
  end

  def connect(candidates, edges) when candidates != [] do
    [edge | candidates_new] = candidates

    next_neighbor =
      candidates
      |> Enum.filter(
        &(MapSet.disjoint?(MapSet.new(&1), MapSet.new(edge)) == false)
      )
      |> hd()

    edges_new = [next_neighbor | edges]
    candidates_new = List.delete(candidates_new, MapSet.new(next_neighbor))

    connect(candidates_new, edges_new)
  end

  def connect([], edges) do
    edges
  end
end
