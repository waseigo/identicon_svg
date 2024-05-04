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
            fg_color: nil,
            grid: nil,
            svg: nil,
            bg_color: nil,
            fg: nil,
            fg_edges: nil,
            bg: nil,
            bg_edges: nil,
            opacity: 1.0,
            padding: 0
end