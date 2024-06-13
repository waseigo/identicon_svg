# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Draw do
  require EEx

  @moduledoc """
  Module of `IdenticonSvg` that contains functions related to drawing SVG elements.
  """
  @moduledoc since: "0.9.0"

  EEx.function_from_string(
    :defp,
    :svg_template_container,
    ~s(<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="<%= viewbox %>" height="10mm" width="10mm" version="1.2"><%= content %></svg>),
    [:viewbox, :content]
  )

  EEx.function_from_string(
    :defp,
    :svg_template_fgpath,
    ~s(<path style="fill:<%= fg_color %>;fill-opacity:<%= opacity %>;" d="<%= pathd %>"/>),
    [:fg_color, :opacity, :pathd]
  )

  EEx.function_from_string(
    :defp,
    :svg_template_defsmask,
    ~s(<defs><mask maskContentUnits="userSpaceOnUse" id="a"><%= content %></mask></defs>),
    [:content]
  )

  EEx.function_from_string(
    :defp,
    :svg_template_innerpaths,
    ~s(<path style="fill-opacity:<%= opacity %>;fill:#fff;" d="<%= viewbox_pathd %>"/><path style="fill-opacity:1;" d="<%= pathd %>"/>),
    [:opacity, :viewbox_pathd, :pathd]
  )

  EEx.function_from_string(
    :defp,
    :svg_template_maskpath,
    ~s(<path mask="url\(#a\)" style="fill-opacity:1; fill:<%= bg_color %>;" d="<%= viewbox_pathd %>"/>),
    [:bg_color, :viewbox_pathd]
  )

  def gen_viewbox(size, padding)
      when is_integer(size) and is_integer(padding) do
    vbmn = -padding
    vbw = size + 2 * padding
    vbmx = size + padding

    vbs =
      [vbmn, vbmn, vbw, vbw]
    |> Enum.map(&to_string/1)
    |> Enum.intersperse(" ")
    |> to_string()

    vbpd = path_to_pathd_fragment(
      [
        [{vbmn, vbmn}, {vbmn, vbmx}],
        [{vbmn, vbmx}, {vbmx, vbmx}],
        [{vbmx, vbmx}, {vbmx, vbmn}],
        [{vbmx, vbmn}, {vbmn, vbmn}]
      ]
    )

    %{
      preamble: vbs,
      pathd: vbpd
    }
  end

  @doc """
  Compose the SVG content out of the templates.
  """
  def svg(paths, size, padding, fg_color, bg_color, opacity) do

    %{preamble: viewbox, pathd: viewbox_pathd} = gen_viewbox(size, padding)

    maskpath = svg_template_maskpath(bg_color, viewbox_pathd)

    pathd =
      paths
    |> Enum.map(&path_to_pathd_fragment/1)
    |> to_string()

    opacity = to_string(opacity)
    innerpaths = svg_template_innerpaths(opacity, viewbox_pathd, pathd)

    defsmask = svg_template_defsmask(innerpaths)

    fgpath = svg_template_fgpath(fg_color, opacity, pathd)

    if is_nil(bg_color) do
    svg_template_container(
      viewbox,
      fgpath
    )
    else
      svg_template_container(
        viewbox,
        fgpath <> defsmask <> maskpath
      )
    end

  end


  def path_to_pathd_fragment(path) when is_list(path) do
    path
    |> path_to_xyhv()
    |> xyhv_to_pathd_fragment()
  end

  def xyhv_to_pathd_fragment([x, y, h, v]) do
    s =
      Enum.map(
        [x, y, h, v, -h, ""],
        &to_string/1
      )

    ["M", " ", "h", "v", "h", "z"]
    |> Enum.zip(s)
    |> Enum.map(&Tuple.to_list/1)
    |> List.flatten()
    |> to_string
  end

  def path_to_xyhv(path) when is_list(path) do
    vertices = List.flatten(path)

    {xs, ys} =
      vertices
      |> Enum.reduce(
        {[], []},
        fn {x, y}, acc ->
          {[x | elem(acc, 0)], [y | elem(acc, 1)]}
        end
      )

    [{xmn, xmx}, {ymn, ymx}] = Enum.map([xs, ys], &mnmx/1)

    [
      xmn,
      ymn,
      xmx - xmn,
      ymx - ymn
    ]
  end

  defp mnmx(values) when is_list(values) do
    {Enum.min(values), Enum.max(values)}
  end
end
