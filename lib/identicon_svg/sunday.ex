defmodule IdenticonSvg.Sunday do
  # Source: https://web.archive.org/web/20130126163405/http://geomalgorithms.com/a03-_inclusion.html

  # Tests if a point is Left|On|Right of an infinite line.
  #    Input:  three points P0, P1, and P2
  #    Return: >0 for P2 left of the line through P0 and P1
  #            =0 for P2  on the line
  #            <0 for P2  right of the line
  def is_left(p0, p1, p2) when is_tuple(p0) and is_tuple(p1) and is_tuple(p2) do
    [p0m, p1m, p2m] =
      [p0, p1, p2]
      |> Enum.map(&coords_to_pointmap/1)

    is_left(p0m, p1m, p2m)
  end

  def is_left(p0, p1, p2) when is_map(p0) and is_map(p1) and is_map(p2) do
    (p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y)
  end

  # Crossing number test for a point in a polygon
  #      Input:   P = a point,
  #               V[] = vertex points of a polygon V[n+1] with V[n]=V[0]
  #      Return:  0 = outside, 1 = inside
  def wn_pnpoly(point, vertices) when is_tuple(point) and is_list(vertices) do
    p = coords_to_pointmap(point)

    vertices_pm =
      vertices
      |> perhaps_close_loop()
      |> Enum.map(&coords_to_pointmap/1)

    vertices_rot1 = tl(vertices_pm) ++ [hd(vertices_pm)]

    winding_number =
      Enum.zip(vertices_pm, vertices_rot1)
      |> Enum.reduce(
        0,
        fn {v_i, v_next}, wn ->
          wn_pnpoly_reducer(p, {v_i, v_next}, wn)
        end
      )

    case winding_number do
      0 -> :outside
      _ -> :inside
    end
  end

  def wn_pnpoly_reducer(p, {v_i, v_next}, wn)
      when is_map(p) and is_map(v_i) and is_map(v_next) and is_integer(wn) do
    if check_a(v_i, p) do
      if check_b(v_i, v_next, p), do: wn + 1, else: wn
    else
      if check_c(v_i, v_next, p), do: wn - 1, else: wn
    end
  end

  defp check_a(v_i, p), do: v_i.y <= p.y

  defp check_b(v_i, v_next, p),
    do: v_next.y > p.y and is_left(v_i, v_next, p) > 0

  defp check_c(v_i, v_next, p),
    do: v_next.y <= p.y and is_left(v_i, v_next, p) < 0

  def coords_to_pointmap({px, py} = _point) do
    %{x: px, y: py}
  end

  def perhaps_close_loop(routed) when is_list(routed) do
    last_point = routed |> tl() |> Enum.reverse() |> hd()

    if last_point != hd(routed) do
      [last_point | routed]
    else
      routed
    end
  end
end
