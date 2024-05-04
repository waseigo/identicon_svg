defmodule IdenticonSvg.PolygonHelper do
  def connect(all_edges) when is_list(all_edges) and all_edges != [] do
    connect(all_edges, [])
  end

  def connect(candidates, []) do
    [edge | candidates_new] = candidates
    connect(candidates_new, [[edge]])
  end

  def connect(candidates, polygons) when candidates != [] do
    polygon = hd(polygons)

    edge =
      case polygon do
        [] -> hd(candidates)
        _ -> hd(polygon)
      end

    candidates2 =
      case polygon do
        [] -> tl(candidates)
        _ -> candidates
      end

    neighbors =
      candidates2
      |> Enum.filter(
        &(MapSet.disjoint?(MapSet.new(&1), MapSet.new(edge)) == false)
      )

    case neighbors do
      [] ->
        polygons_new = [[] | polygons]
        connect(candidates2, polygons_new)

      _ ->
        next_neighbor = hd(neighbors)
        polygon_new = [next_neighbor | polygon]
        candidates_new = List.delete(candidates2, next_neighbor)
        polygons_new = [polygon_new | tl(polygons)]

        connect(candidates_new, polygons_new)
    end
  end

  def connect([], polygons) do
    polygons
  end
end
