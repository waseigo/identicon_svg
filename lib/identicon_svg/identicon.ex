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
            padding: 0,
            grid: nil,
            svg: nil,
            colors: %{fg: nil, bg: nil},
            layers: %{fg: nil, bg: nil},
            squares: %{fg: nil, bg: nil},
            fg: nil,
            bg: nil,
            opacity: 1.0
end
