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
        IdenticonSvg.generate("test", 5, :invalid_atom)
      end
    end
  end
end
