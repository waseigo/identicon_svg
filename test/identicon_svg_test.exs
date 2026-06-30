defmodule IdenticonSvgTest do
  use ExUnit.Case
  doctest IdenticonSvg

  describe "svg version" do
    test "outputs version 1.1" do
      svg = IdenticonSvg.generate("banana")
      assert svg =~ ~s{version="1.1"}
      refute svg =~ ~s{version="1.2"}
    end
  end

  describe "opacity guard" do
    test "accepts integer 1 as opacity" do
      assert is_binary(IdenticonSvg.generate("test", 5, nil, 1))
    end

    test "accepts float opacity" do
      assert is_binary(IdenticonSvg.generate("test", 5, nil, 0.5))
    end

    test "rejects opacity > 1" do
      assert_raise FunctionClauseError, fn ->
        IdenticonSvg.generate("test", 5, nil, 1.5)
      end
    end

    test "rejects opacity < 0" do
      assert_raise FunctionClauseError, fn ->
        IdenticonSvg.generate("test", 5, nil, -0.1)
      end
    end
  end

  describe "bg_color guard" do
    test "accepts :basic" do
      assert is_binary(IdenticonSvg.generate("test", 5, :basic))
    end

    test "accepts :split1" do
      assert is_binary(IdenticonSvg.generate("test", 5, :split1))
    end

    test "accepts :split2" do
      assert is_binary(IdenticonSvg.generate("test", 5, :split2))
    end

    test "accepts nil background" do
      assert is_binary(IdenticonSvg.generate("test", 5, nil))
    end

    test "accepts hex string background" do
      assert is_binary(IdenticonSvg.generate("test", 5, "#f00"))
    end

    test "rejects invalid atom" do
      assert_raise FunctionClauseError, fn ->
        apply(IdenticonSvg, :generate, ["test", 5, :invalid_atom])
      end
    end
  end

  describe "identicon output structure" do
    test "returns valid SVG document" do
      svg = IdenticonSvg.generate("banana")
      assert String.starts_with?(svg, "<svg")
      assert String.ends_with?(svg, "</svg>")
    end

    test "no defs when bg_color is nil" do
      svg = IdenticonSvg.generate("banana")
      refute svg =~ ~r{<defs>}
    end

    test "defs mask present when bg_color is set" do
      svg = IdenticonSvg.generate("banana", 5, :basic)
      assert svg =~ ~r{<defs><mask}
    end

    test "viewbox matches size 5" do
      svg = IdenticonSvg.generate("banana", 5)
      assert svg =~ ~s{viewBox="0 0 5 5"}
    end

    test "viewbox matches size 4" do
      svg = IdenticonSvg.generate("banana", 4)
      assert svg =~ ~s{viewBox="0 0 4 4"}
    end

    test "viewbox includes padding" do
      svg = IdenticonSvg.generate("banana", 5, nil, 1.0, 2)
      assert svg =~ ~s{viewBox="-2 -2 9 9"}
    end

    test "deterministic output" do
      assert IdenticonSvg.generate("banana") == IdenticonSvg.generate("banana")
    end

    test "different texts produce different identicons" do
      refute IdenticonSvg.generate("banana") == IdenticonSvg.generate("apple")
    end

    test "squircle with curvature produces valid SVG" do
      svg = IdenticonSvg.generate("banana", 5, nil, 1.0, 2, squircle_curvature: 0.8)
      assert String.starts_with?(svg, "<svg")
      assert String.ends_with?(svg, "</svg>")
      assert svg =~ ~r{<pattern}
      assert svg =~ ~r{<path d=}
    end
  end
end
