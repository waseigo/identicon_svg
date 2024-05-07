# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Pathfinder do
  # pathset is an element of an %Identicon{}'s :paths list and represents a set of paths
  # of a traced polygon. When an incoming pathset (prior to any processing by Pathfinder)
  # only has a single list element, that element represents the convex hull of a traced
  # polygon. When an incoming pathset has more than one list element, then these list
  # elements represent disjoint paths (no common edges after the EdgeCleaner cleanup),
  # one of which is the convex hull of the polygon and the others are the outlines of
  # "holes" within the polygon. The Pathfinder module contains functions that bridge
  # the paths of a pathset so that the polygon can be traced with a single uninterrupted
  # line that will get turned into an SVG <path> element.

  def doit(pathset) when is_list(pathset) do
  end

  def connect(polygon_edges)
      when is_list(polygon_edges) and polygon_edges != [] do
    connect(polygon_edges, [])
  end

  def connect(candidates, []) do
    [edge | candidates_new] = candidates
    connect(candidates_new, [edge])
  end

  def connect(candidates, connected) when candidates != [] do
    # IO.inspect([connected, candidates])
    # IO.puts("\n")
    previous_edge = hd(connected)
    neighbors = find_neighbors(previous_edge, candidates)

    case neighbors do
      [] ->
        # IO.inspect([connected, candidates])
        IO.puts("Handling disjointed boundaries")
        handle_disjointed_boundaries(connected, previous_edge, candidates)

      _ ->
        IO.puts("Neighbors found")
        next_neighbor = choose_neighbor(previous_edge, neighbors)

        connected_new = [direct(next_neighbor, previous_edge)] ++ connected
        candidates_new = List.delete(candidates, next_neighbor)

        connect(candidates_new, connected_new)
    end
  end

  def connect([], fully_connected) do
    fully_connected
  end

  def direct([c, _d] = current, [_a, b] = _previous) do
    if b == c do
      current
    else
      Enum.reverse(current)
    end
  end

  def orient(current_edge, reference_edge) do
    reference_vector = edge_to_vector(reference_edge)
    current_vector = edge_to_vector(current_edge)

    if reference_vector == current_vector do
      current_edge
    else
      Enum.reverse(current_edge)
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

  def choose_neighbor(previous_edge, neighbors) do
    neighbors_with_same_orientation =
      neighbors
      |> Enum.filter(&same_orientation?(&1, previous_edge))

    case neighbors_with_same_orientation do
      [] -> hd(neighbors)
      _ -> hd(neighbors_with_same_orientation)
    end
  end

  def handle_disjointed_boundaries(connected, previous_edge, candidates)
      when candidates != [] do
    # `e_cand` is the edge of the disjointed `candidates` set of edges that is closest to `previous_edge`
    {e_cand, _d} = find_closest_parallel_edge(previous_edge, candidates)

    # `e_conn` is the edge of the `connected` set of edges that is closest to the `e_cand` edge
    {e_conn, _d} = find_closest_parallel_edge(e_cand, connected)

    rotated_connected = rotate(connected, e_conn)
    bridge_edgelist = bridge(e_conn, e_cand)

    bridge_way_back =
      bridge_edgelist
      |> Enum.map(&Enum.reverse/1)

    candidates_new = candidates ++ bridge_edgelist ++ bridge_way_back

    # candidates_new

    connect(candidates_new, rotated_connected)
  end

  def bridge(source_edge, target_edge) do
    target_edge_oriented = orient(target_edge, source_edge)
    [_, from_vertex] = source_edge
    [_, to_vertex] = target_edge_oriented

    b = [from_vertex, to_vertex]
    b_vec = edge_to_vector(b)
    b_mag = cardinal_vector_magnitude(b_vec)
    dir_vec = normalize_vector(b_vec)

    Enum.reduce_while(
      0..b_mag,
      [from_vertex],
      fn _, acc ->
        if hd(acc) != to_vertex do
          {:cont, [point_plus_vector(hd(acc), dir_vec) | acc]}
        else
          {:halt, Enum.reverse(acc)}
        end
      end
    )
    |> points_to_edgelist()
  end

  # rotate `list` so that the element with value `target_head` is at its head
  def rotate([h | t], target_head) when h != target_head do
    rotate(t ++ [h], target_head)
  end

  def rotate([h | _t] = list, target_head) when h == target_head do
    list
  end

  def orientation([{x1, y1}, {x2, y2}] = _edge) do
    case [x2 - x1, y2 - y1] do
      [0, 0] -> :none
      [0, _] -> :vertical
      [_, 0] -> :horizontal
      [_, _] -> :diagonal
    end
  end

  def same_orientation?(edge1, edge2) when is_list(edge1) and is_list(edge2) do
    orientation(edge1) == orientation(edge2)
  end

  def perpendicular?(edge1, edge2) when is_list(edge1) and is_list(edge2) do
    [edge1, edge2]
    |> Enum.map(&orientation/1)
    |> MapSet.new()
    |> Kernel.==(MapSet.new([:horizontal, :vertical]))
  end

  def find_closest_parallel_edge(edge, candidates) do
    candidates
    |> Enum.filter(&same_orientation?(&1, edge))
    |> Enum.map(fn e -> {e, distance_in_blocks_over(e, edge)} end)
    |> Enum.sort_by(fn {_k, v} -> v end, :asc)
    |> hd()
  end

  def distance_in_blocks_over(edge1, edge2)
      when is_list(edge1) and is_list(edge2) do
    [mp1, mp2] =
      [edge1, edge2]
      |> Enum.map(&midpoint/1)

    d = coords_abs_diff(mp1, mp2) |> Enum.sum()

    if perpendicular?(edge1, edge2) do
      d - 1
    else
      d
    end
  end

  def midpoint([{x1, y1}, {x2, y2}] = _edge) do
    {(x2 + x1) / 2, (y2 + y1) / 2}
  end

  def edge_to_vector([{x1, y1}, {x2, y2}]) do
    [x2 - x1, y2 - y1]
  end

  def coords_abs_diff({x1, y1} = _point1, {x2, y2} = _point2) do
    [abs(x1 - x2), abs(y1 - y2)]
  end

  def cardinal_vector_magnitude(vector) when is_list(vector) do
    vector
    |> Enum.map(&abs/1)
    |> Enum.max()
  end

  def normalize_vector(vector) when is_list(vector) do
    magnitude = cardinal_vector_magnitude(vector)
    Enum.map(vector, &div(&1, magnitude))
  end

  def point_plus_vector({xp, yp} = _point, [xv, yv] = _vector) do
    {xp + xv, yp + yv}
  end

  def points_to_edgelist(points) when is_list(points) do
    points_rot1 = rotate(points, Enum.at(points, 1))

    Enum.zip(points, points_rot1)
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
  end

  def sum_of_edge_points(path) when is_list(path) do
    path
    |> Enum.map(&(hd(&1) |> Tuple.to_list()))
    |> Enum.reduce([0, 0], fn [x, y], [sx, sy] = _acc -> [sx + x, sy + y] end)
  end
end
