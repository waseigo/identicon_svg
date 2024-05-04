# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Geometry.ShapeField do
  @moduledoc """
  Defines the struct used by the functions of the Geometry module to model a field of shapes (polygons).
  """
  @moduledoc since: "0.9.0"
  defstruct grid_squares: [],
            polygons: [],
            allocated_edges: %{},
            mergeable_polygons: []
end

defmodule IdenticonSvg.Geometry.Polygon do
  @moduledoc """
  Defines the struct used by the functions of the Geometry module to model a polygon.
  """
  @moduledoc since: "0.9.0"
  defstruct index: nil,
            edges: []
end

defmodule IdenticonSvg.Geometry do
  alias IdenticonSvg.Identicon
  alias IdenticonSvg.Geometry.ShapeField
  alias IdenticonSvg.Geometry.Polygon

  @moduledoc """
  Module of `IdenticonSvg` that contains functions related to simplifying geometry from rectangles to paths.
  """
  @moduledoc since: "0.9.0"

  def shape_field(%Identicon{} = input, layer: layer)
      when layer in [:fg, :bg] do
    sf =
      %ShapeField{
        grid_squares: Map.get(input, layer)
      }
      |> to_polygon_field()
      |> edge_allocation()
      #|> mergeable_polygons()
      #|> merge_all_polygons()
      #|> all_rects_to_paths()

    input
    |> Map.put(layer, sf.polygons)
  end

  def all_rects_to_paths(%ShapeField{polygons: polygons} = input) do
    rects =
      polygons
      |> Enum.filter(fn p -> length(p.edges) == 4 end)

    rects_to_polys =
      rects
      |> Enum.map(&rect_to_poly/1)

    new_polygons =
      polygons
      |> Enum.reject(&(&1 in rects))
      |> Enum.concat(rects_to_polys)

    %{input | polygons: new_polygons}
  end

  def rect_to_poly(%Polygon{} = rect) do
    edges =
      rect.edges
      # |> Enum.map(&MapSet.to_list/1)
      |> connect([])

    [h | t] = Enum.reverse(edges)
    h = Enum.reverse(h)

    # FIXME ugly hack because orient/1 should actually be a reduce
    edges = [h | t] |> Enum.reverse()

    %{rect | edges: edges}
  end

  def to_polygon_field(%ShapeField{grid_squares: indexed} = input)
      when is_list(indexed) do
    polygons =
      indexed
      |> Enum.map(fn r ->
        %Polygon{
          index: Map.get(r, :index),
          edges: all_edges_of_rectangle_at(r.col, r.row)
        }
      end)

    %{input | polygons: polygons}
  end

  def edge_allocation(%ShapeField{polygons: polygons} = input)
      when is_list(polygons) do
    rectsmap =
      polygons
      |> Enum.map(fn r -> {r.index, r.edges} end)
      |> Map.new()

    allocated_edges =
      rectsmap
      |> Enum.reduce(%{}, fn {key, values}, acc ->
        Enum.reduce(values, acc, fn value, acc ->
          Map.update(acc, value, [key], &(&1 ++ [key]))
        end)
      end)

    %{input | allocated_edges: allocated_edges}
  end

  def mergeable_polygons(%ShapeField{allocated_edges: allocated_edges} = input)
      when is_map(allocated_edges) do
    mergeable =
      allocated_edges
      |> Map.filter(fn {_k, v} -> length(v) > 1 end)

    %{input | mergeable_polygons: mergeable}
  end

  def merge_all_polygons(%ShapeField{mergeable_polygons: mergeable} = input)
      when mergeable != [] do
    mergeable
    |> Enum.reduce(input, fn {_k, m}, acc -> merge_polygons(acc, m) end)
  end

  def merge_polygons(%ShapeField{} = input, indices) when is_list(indices) do
    polygons_to_merge =
      input
      |> Map.get(:polygons)
      |> Enum.filter(&(Map.get(&1, :index) in indices))

    edges_to_merge =
      polygons_to_merge
      |> Enum.map(&Map.get(&1, :edges))
      |> List.flatten()
      |> non_overlapping_edges()

    merged_polygon_edges =
      edges_to_merge
      |> connect([])

    new_polygon = %Polygon{
      index: new_index(indices),
      edges: merged_polygon_edges
    }

    polygons =
      input.polygons
      |> Enum.reject(&(&1 in polygons_to_merge))
      |> Enum.concat([new_polygon])

    mergeable =
      input.mergeable_polygons
      |> Map.filter(fn {_k, v} -> v != indices end)

    allocated =
      input.allocated_edges
      |> Map.filter(fn {_k, v} -> v != indices end)

    %{
      input
      | polygons: polygons,
        allocated_edges: allocated,
        mergeable_polygons: mergeable
    }
  end

  def new_index([idx1, idx2] = indices) when is_list(indices) do
    idx1 * 13 + idx2 * 17
  end

  def edges_to_coordinates(edges) when is_list(edges) do
    edges
    |> Stream.map(&Enum.at(&1, 0))
    |> Stream.map(&Tuple.to_list(&1))
    |> Enum.to_list()
  end

  def all_edges_of_rectangle_at(x0, y0) do
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
    |> Enum.map(&MapSet.new/1)
  end

  def non_overlapping_edges(edges) when is_list(edges) do
    edges
    |> Enum.frequencies()
    |> Map.filter(fn {_k, v} -> v == 1 end)
    |> Map.keys()
  end

  def share_an_edge?(%Polygon{} = rect_this, %Polygon{} = rect_ref) do
    rect_this.edges
    |> MapSet.new()
    |> MapSet.disjoint?(MapSet.new(rect_ref.edges))
    |> Kernel.not()
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

    IO.inspect(next_neighbor)

    edges_new = [next_neighbor | edges]
    candidates_new = List.delete(candidates_new, MapSet.new(next_neighbor))

    connect(candidates_new, edges_new)
  end

  def connect([], edges) do
    edges
  end

  # def orient([_a, b] = new_neighbor, [c, _d] = _previous) do
  #   if b == c do
  #     new_neighbor
  #   else
  #     Enum.reverse(new_neighbor)
  #   end
  # end

  def polygon_to_edgelist(%Polygon{edges: edges}) do
    edges
    |> Enum.map(&List.first/1)
    |> Enum.map(&Tuple.to_list/1)
  end
end
