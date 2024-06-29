# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Draw do
  require EEx

  @moduledoc """
  Module of `IdenticonSvg` that contains functions related to drawing SVG elements and composing the SVG output of the requested identicon.
  """
  @moduledoc since: "0.9.0"

  # EEx templating functions for string interpolation and for composing the SVG content.

  EEx.function_from_string(
    :defp,
    :svg_template_container,
    ~s(<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="auto" viewBox="<%= viewbox %>" height="100%" width="100%" version="1.2"><%= content %></svg>),
    [:viewbox, :content]
  )

  EEx.function_from_string(
    :defp,
    :g_template_container,
    ~s|<g transform="translate(<%= padding %>,<%= padding %>)"><%= content %></g>|,
    [:padding, :content]
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
    ~s(<defs><mask maskContentUnits="userSpaceOnUse" id="<%= mask_id %>"><%= content %></mask></defs>),
    [:content, :mask_id]
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
    ~s(<path mask="url\(#<%= mask_id %>\)" style="fill-opacity:1; fill:<%= bg_color %>;" d="<%= viewbox_pathd %>"/>),
    [:bg_color, :viewbox_pathd, :mask_id]
  )

  # Generate the SVG attributes for the viewbox in the preamble and the background mask.

  defp gen_viewbox(size, padding)
       when is_integer(size) and is_integer(padding) do
    vbmn = -padding
    vbw = size + 2 * padding
    vbmx = size + padding

    vbs =
      [vbmn, vbmn, vbw, vbw]
      |> Enum.map(&to_string/1)
      |> Enum.intersperse(" ")
      |> to_string()

    vbpd =
      path_to_pathd_fragment([
        [{vbmn, vbmn}, {vbmn, vbmx}],
        [{vbmn, vbmx}, {vbmx, vbmx}],
        [{vbmx, vbmx}, {vbmx, vbmn}],
        [{vbmx, vbmn}, {vbmn, vbmn}]
      ])

    %{
      preamble: vbs,
      pathd: vbpd
    }
  end

  @doc """
  Compose the SVG content out of the templates and return a string.

  Arguments (all mandatory):
  * `paths`: the `:paths` field of the `%Identicon{}` struct, i.e. single-height polygon "strips" across the mirroring axis after neighbor detection.
  * `size`: the size of the identicon without padding.
  * `padding`: the requested padding (positive or zero integer).
  * `fg_color` and `bg_color`: foreground and background color hex strings.
  * `opacity`: requested opacity (0.0 to 1.0).
  """
  def svg(
        paths,
        size,
        padding,
        fg_color,
        bg_color,
        opacity,
        opts \\ [only_group: false, curvature: 0.8]
      ) do
    %{preamble: viewbox, pathd: viewbox_pathd} = gen_viewbox(size, padding)

    mask_id = gen_random_string()
    maskpath = svg_template_maskpath(bg_color, viewbox_pathd, mask_id)

    pathd =
      paths
      |> Enum.map(&path_to_pathd_fragment/1)
      |> to_string()

    opacity = to_string(opacity)
    innerpaths = svg_template_innerpaths(opacity, viewbox_pathd, pathd)
    defsmask = svg_template_defsmask(innerpaths, mask_id)
    fgpath = svg_template_fgpath(fg_color, opacity, pathd)

    only_group? = Keyword.get(opts, :only_group)

    content = (is_nil(bg_color) && fgpath) || fgpath <> defsmask <> maskpath

    if only_group? do
      curvature = Keyword.get(opts, :curvature)

      g_template_container(padding, content)
      |> Squircle.svg_group(size + 2 * padding, 0, curvature)
    else
      svg_template_container(viewbox, content)
    end
  end

  defp gen_random_string(len \\ 10) when is_integer(len) and len > 0 do
    for _ <- 1..len,
        into: "",
        do: <<Enum.random('0123456789abcdefghijklmnopqrstuvwxyz')>>
  end

  # Convert a path (of the `%Identicon{}` struct's `:paths` field) to a path fragment that ends up being part of the `d` attribute of an SVG `<path>`.
  defp path_to_pathd_fragment(path) when is_list(path) do
    path
    |> path_to_xyhv()
    |> xyhv_to_pathd_fragment()
  end

  # Convert a rectangle defined by its reference corner coordinates (`x` and `y`) and its horizontal and vertical span (`h` and `v`) into a path fragment that ends up being part of the `d` attribute of an SVG `<path>`.
  defp xyhv_to_pathd_fragment([x, y, h, v]) do
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

  # Convert a path (of the `%Identicon{}` struct's `:paths` field) to a rectangle defined by its reference corner coordinates (`x` and `y`) and its horizontal and vertical span (`h` and `v`).
  defp path_to_xyhv(path) when is_list(path) do
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
