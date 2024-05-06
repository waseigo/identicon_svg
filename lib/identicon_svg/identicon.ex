# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Identicon do
  @moduledoc """
  Defines the `%Identicon{}` struct used by the functions of the main
  module to gradually process and generate an identicon.
  """
  @moduledoc since: "0.1.0"
  defstruct text: nil,
            size: 5,
            bg_color: nil,
            padding: 0,
            opacity: 1.0,
            grid: nil,
            fg_color: nil,
            squares: nil,
            polygons: nil,
            edges: nil,
            layer: nil,
            svg: nil
end
