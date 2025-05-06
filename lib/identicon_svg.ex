# SPDX-FileCopyrightText: 2024 Isaak Tsalicoglou <isaak@overbring.com>
# SPDX-License-Identifier: Apache-2.0

defmodule IdenticonSvg do
  @moduledoc """
  IdenticonSvg generates SVG identicons or animal avatars using a text seed.
  """
  @moduledoc since: "0.1.0"

  @doc """
  Creates either an identicon or animal avatar based on the specified style.

  ## Parameters

  * `seed` - A binary string used to generate the avatar
  * `style` - The style of avatar to generate (currently `:identicon` or `:animal`)
  * `opts` - Optional keyword list of customization options

  ## Options

  See `IdenticonSvg.Identicon.generate/2` and `IdenticonSvg.Animal.generate/2` for the available options for each style.

  ## Examples

  ```elixir
  # Generate an identicon-style avatar
  generate_svg("example@email.com", :identicon)

  # Generate an animal-style avatar with options
  generate_svg("username", :animal, size: 128)
  """
  def generate_svg(
        seed,
        style,
        opts \\ []
      )

  def generate_svg(
        seed,
        :identicon,
        opts
      )
      when is_binary(seed) do
    IdenticonSvg.Identicon.generate(
      seed,
      opts
    )
  end

  def generate_svg(
        seed,
        :animal,
        opts
      )
      when is_binary(seed) do
    IdenticonSvg.Animal.generate(
      seed,
      opts
    )
  end

  defdelegate identicon_svg(
                seed,
                opts \\ []
              ),
              to: IdenticonSvg.Identicon,
              as: :generate

  defdelegate animal_svg(
                seed,
                opts \\ []
              ),
              to: IdenticonSvg.Animal,
              as: :generate

  # for backwards-compatibility
  @doc false
  @deprecated "Use `generate_svg/3` or `identicon/2` instead"
  def generate(
        seed,
        size \\ 5,
        bg_color \\ nil,
        opacity \\ 1.0,
        padding \\ 0,
        opts \\ []
      ),
      do:
        IdenticonSvg.Identicon.generate(
          seed,
          Keyword.merge(opts,
            size: size,
            bg_color: bg_color,
            opacity: opacity,
            padding: padding
          )
        )
end
