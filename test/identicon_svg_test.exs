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
end
