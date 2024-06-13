<img src="./assets/logo.png" width="100" height="100">

# IdenticonSvg

An Elixir library to generate identicons in SVG format, so they can be inlined in HTML.

## Features

* Github-style square identicon sizes from 4x4 to 10x10. The hashing function is automatically chosen based on the requested size. The foreground color choice is automatic based on the hash.
* Optional (integer) padding.
* Optional background color, manually defined or automatically set as basic or split complementary.
* Transparent background (also on the padding) if no background color specified.
* Optionally non-100% opacity.
* Small SVG file size makes it great for inlining in HTML.
* No external dependencies.

## Installation

The package is [available in Hex](https://hex.pm/packages/identicon_svg) and can be installed by adding `identicon_svg` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:identicon_svg, "~> 0.9.0"}
  ]
end
```

## Recent changes

### New since v0.9.0

* Setting `padding` to a positive integer sets the padding to the identicon to that value. If `bg_color` is non-nil, it will also be applied to the padding area with the with the default (1.0) or requested `opacity`, which is also applied on the foreground and the background. 
* The size of the generated SVG code is greatly reduced.

### New since v0.8.0

Setting `bg_color` to one of the following 3 atom values sets the color of the background squares to the corresponding RGB-complementary color of the automatically-defined foreground color, with the default (1.0) or requested `opacity`:
* `:basic`: the complementary color, i.e. the opposite color of `fg_color` on the color wheel.
* `:split1`: the first adjacent tertiary color of the complement of `fg_color` on the color wheel.
* `:split2`: the second adjacent tertiary color of the complement of `fg_color` on the color wheel.

## Configuration

No configuration required.

## Documentation

The docs can be found at <https://hexdocs.pm/identicon_svg>.

There's also a [discussion thread on elixirforum.com](https://elixirforum.com/t/identiconsvg-generates-identicons-in-svg-format-so-they-can-be-inlined-in-html/54557/1).

## TODO (maybe, one day)

- [x] Implement core functionality
- [x] Publish on hex.pm
- [x] Add background color functionality (split-complementary for automatic color-matching)
- [x] Add padding
- [x] Reduce generated SVG file size
- [ ] Implement testing functions
- [ ] Set up CI

