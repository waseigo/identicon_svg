# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg.Color do
  @moduledoc """
  Module of `IdenticonSvg` that contains functions related to handling colors.
  """
  @moduledoc since: "0.9.0"

  @doc """
  Convert an integer in the range 0..255 to a zero-padded hexacedimal string
  """
  def integer_to_hex(value) when is_integer(value) and value in 0..255 do
    Integer.to_string(value, 16)
    |> String.pad_leading(2, "0")
  end

  @doc """
  Convert a hexadecimal color string with 3 or 6 characters, with or without a `#` prefix, to
  a list of integers representing the red, green, and blue components of a color as integers in the range 0..255
  """
  def hex_to_rgb(hex) when is_bitstring(hex) and byte_size(hex) in [4, 7] do
    <<r, g, b>> =
      hex
      |> String.trim_leading("#")
      |> String.upcase()
      |> hex_to_hex6()
      |> Base.decode16!()

    [r, g, b]
  end

  @doc """
  Convert a list of integers representing the red, green, and blue components of a color as integers in the range 0..255 to a hexadecimal color string with 6 characters, prefixed by "#"
  """
  def rgb_to_hex6([r, g, b] = rgb)
      when is_integer(r) and is_integer(g) and is_integer(b) do
    rgb
    |> Enum.map(&integer_to_hex/1)
    |> List.insert_at(0, "#")
    |> List.to_string()
  end

  @doc """
  Convert a hexadecimal color string with 3 characters, with or without a `#` prefix, to
  a hexadecimal color string with 6 uppercase characters. If the input hex color has 6 characters,
  return it untouched. Otherwise, raise an `ArgumentError`.
  """
  def hex_to_hex6(hex) when is_bitstring(hex) do
    case byte_size(String.trim_leading(hex, "#")) do
      3 ->
        hex
        |> String.trim_leading("#")
        |> String.graphemes()
        |> Enum.map_join(fn c -> String.duplicate(c, 2) end)

      6 ->
        hex

      _ ->
        raise ArgumentError, "Invalid hex color format"
    end
  end

  @doc """
  Take an list of integers representing the red, green, and blue components of a color as integers in the range 0..255, and return a complementary color based on the provided value of the `:compl` keyword option.
  """
  def color_wheel([r, g, b], compl: split)
      when is_integer(r) and is_integer(g) and is_integer(b) and
             split in [:basic, :split1, :split2] do
    case split do
      :basic ->
        [255 - r, 255 - g, 255 - b]

      :split1 ->
        [r, 255 - g, 255 - b]

      :split2 ->
        [255 - r, 255 - g, b]
    end
  end
end
