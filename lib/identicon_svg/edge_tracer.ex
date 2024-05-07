# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.EdgeTracer do
  alias IdenticonSvg.PolygonReducer

  # identicon_edges is the :edges field of an %Identicon{}, and represents
  # a list of polygon edgelists already extracted by PolygonReducer.group/1
  def doit(identicon_edges) do
    Enum.map(identicon_edges, &doit_one/1)
  end

  # polygon_edges is a list element of identicon_edges (the argument to doit/1)
  def doit_one(polygon_edges) do
    # first, get the midpoints
    midpoints = Enum.map(polygon_edges, &midpoint/1)

    # then, generate all theoretical neighbors per midpoint;
    # not all of them actually exist in the polygon
    theoretical_neighbors =
      midpoints
      |> Enum.map(&{&1, edge_neighbors_by_midpoint(&1)})
      |> Map.new()

    # next, filter the theoretical neighbors of each present edge's midpoint and keep only
    # those that actually exist in the polygon
    actual_neighbors_per_edge =
      theoretical_neighbors
      |> Enum.map(fn {midpoint, neighbors} ->
        {
          midpoint,
          MapSet.intersection(MapSet.new(midpoints), MapSet.new(neighbors))
          |> MapSet.to_list()
        }
      end)
      |> Map.new()

    # use PolygonReducer's core function to group edges together, thus identifying any
    # disjointed edgelists, such as those representing "donut holes" and the exterior
    # hull of the polygon; we will need to bridge these later
    edge_sublists = PolygonReducer.group(actual_neighbors_per_edge)

    # For each of the edge sublists, generate a connectivity map; the result is a list
    # of those sublists' connectivity maps
    connectivity_maps =
      edge_sublists
      |> Enum.map(fn edge_sublist ->
        Enum.map(
          edge_sublist,
          fn midpoint ->
            {midpoint, Map.get(actual_neighbors_per_edge, midpoint)}
          end
        )
        |> Map.new()
      end)

    # For each connectivity map:
    # 1. Connect its edges (in the form of edge midpoints)
    # 2. Convert each midpoint to an unoriented edge in [{a, b}, {c, d}] notation
    # 3. Trace them in a consistent direction using direct/1
    # 4. The result is one list of traced and directed edges per connectivity map

    # directed_traced_edgelists =
    connectivity_maps
    |> Enum.map(fn cm when is_map(cm) ->
      cm
      |> connect_edges()
      |> Enum.map(fn mp -> midpoint_to_unoriented_edge(mp) end)
      |> trace_edges()
    end)
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
  def rotate([h | t], target_head)
      when not is_list(target_head) and h != target_head do
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

  def edge_orientation_by_midpoint({mpx, mpy} = _midpoint) when mpx != mpy do
    rmpx = round(mpx) == mpx
    rmpy = round(mpy) == mpy

    case [rmpx, rmpy] do
      [true, false] -> :vertical
      [false, true] -> :horizontal
      [_, _] -> :undefined
    end
  end

  def edge_neighbors_by_midpoint({mpx, mpy} = midpoint) when mpx != mpy do
    case edge_orientation_by_midpoint(midpoint) do
      :horizontal ->
        [
          [1.0, 0.0],
          [0.5, -0.5],
          [-1.0, 0.0],
          [-0.5, -0.5],
          [-0.5, 0.5],
          [0.5, 0.5]
        ]
        |> Enum.map(&point_plus_vector(midpoint, &1))

      :vertical ->
        [
          [-0.5, 0.5],
          [0.0, 1.0],
          [0.5, 0.5],
          [0.5, -0.5],
          [0.0, -1.0],
          [-0.5, -0.5]
        ]
        |> Enum.map(&point_plus_vector(midpoint, &1))
    end
  end

  def midpoint_to_unoriented_edge({mpx, mpy} = midpoint) when mpx != mpy do
    case edge_orientation_by_midpoint(midpoint) do
      :horizontal ->
        [
          [mpx - 0.5, mpy],
          [mpx + 0.5, mpy]
        ]

      :vertical ->
        [
          [mpx, mpy + 0.5],
          [mpx, mpy - 0.5]
        ]
    end
    |> Enum.map(fn mp_edge ->
      Enum.map(
        mp_edge,
        fn coord -> floor(coord) end
      )
      |> List.to_tuple()
    end)
  end

  def connect_edges(s) when is_map(s) and s != %{} do
    acc0 = %{routed: [], candidates: s}

    Enum.reduce_while(
      0..length(Map.keys(s)),
      acc0,
      fn _iteration, acc ->
        %{candidates: candidates} = acc

        if candidates != %{} do
          {:cont, edge_connector(acc)}
        else
          {:halt, acc}
        end
      end
    )
    |> Map.get(:routed)

    # |> perhaps_close_loop()
  end

  def edge_connector(%{routed: [], candidates: candidates} = _acc)
      when candidates != %{} do
    next_edge = candidates |> Map.keys() |> hd()
    routed = [next_edge]
    candidates_new = candidates |> Map.delete(next_edge)

    %{
      routed: routed,
      candidates: candidates_new
    }
  end

  def edge_connector(%{routed: routed, candidates: candidates} = _acc) do
    next_edge =
      candidates
      |> Map.filter(fn {_k, v} -> hd(routed) in v end)
      |> Map.keys()
      |> hd()

    routed_new = [next_edge | routed]
    candidates_new = Map.delete(candidates, next_edge)

    %{
      routed: routed_new,
      candidates: candidates_new
    }
  end

  def edge_connector(%{candidates: []} = acc) do
    acc
  end

  def perhaps_close_loop(routed) when is_list(routed) do
    last_point = routed |> tl() |> Enum.reverse() |> hd()

    if last_point != hd(routed) do
      [last_point | routed]
    else
      routed
    end
  end

  def trace_edges(routed) when is_list(routed) do
    Enum.reduce(
      tl(routed),
      [hd(routed)],
      fn edge, traces ->
        IO.inspect(traces)
        IO.puts("\n")
        [direct(edge, hd(traces)) | traces]
      end
    )
    |> Enum.reverse()
  end
end
