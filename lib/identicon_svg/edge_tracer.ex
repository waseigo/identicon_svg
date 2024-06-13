# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.EdgeTracer do
  alias IdenticonSvg.PolygonReducer

  @moduledoc """
  Module that contains functions for tracing edges around merged squares of the identicon's grid.
  """
  @moduledoc since: "0.9.0"

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

  def direct([c, _d] = current, [_a, b] = _previous) do
    if b == c do
      current
    else
      Enum.reverse(current)
    end
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

  def midpoint([{x1, y1}, {x2, y2}] = _edge) do
    {(x2 + x1) / 2, (y2 + y1) / 2}
  end

  def point_plus_vector({xp, yp} = _point, [xv, yv] = _vector) do
    {xp + xv, yp + yv}
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

  def trace_edges(routed) when is_list(routed) do
    Enum.reduce(
      tl(routed),
      [hd(routed)],
      fn edge, traces ->
        [direct(edge, hd(traces)) | traces]
      end
    )
    |> Enum.reverse()
  end
end
