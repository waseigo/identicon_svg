defmodule IdenticonSvg.AnimalTest do
  use ExUnit.Case, async: true
  import IdenticonSvg.Animal
  import IdenticonSvg.Color

  doctest IdenticonSvg.Animal

  describe "avatar/2" do
    test "generates an avatar with default options" do
      svg = generate("test")
      assert String.starts_with?(svg, "<svg")
      assert String.contains?(svg, "width='150'")
      assert String.contains?(svg, "height='150'")
      assert String.contains?(svg, "viewBox='0 0 500 500'")
    end

    test "generates consistent avatars for the same seed" do
      svg1 = generate("consistent_seed")
      svg2 = generate("different_seed")
      svg3 = generate("consistent_seed")
      assert svg1 == svg3
      refute svg2 == svg3
    end

    test "generates different avatars for different seeds" do
      svg1 = generate("seed1")
      svg2 = generate("seed2")
      svg3 = generate("seed1")
      refute svg1 == svg2
      assert svg1 == svg3
    end

    test "respects custom size option" do
      svg = generate("test", size: 300)
      assert String.contains?(svg, "width='300'")
      assert String.contains?(svg, "height='300'")
    end

    test "respects round option" do
      svg = generate("test", round: false)
      assert String.contains?(svg, "rx='0'")

      svg = generate("test", round: true)
      assert String.contains?(svg, "rx='250'")
    end

    test "respects blackout option" do
      svg = generate("test", blackout: false)
      refute String.contains?(svg, "fill-opacity='0.08'")

      svg = generate("test", blackout: true)
      assert String.contains?(svg, "fill-opacity='0.08'")
    end

    test "respects custom colors" do
      svg = generate("test", background_colors: ["#aabbcc"])
      assert String.contains?(svg, "fill='#aabbcc'")
    end

    test "respects background_class option" do
      svg = generate("test", background_class: "custom-bg")
      assert String.contains?(svg, "class='custom-bg'")
    end
  end

  describe "avatar_face/2" do
    test "generates just the face without background" do
      face = avatar_face("test")
      assert is_binary(face)
      assert String.contains?(face, "path")
      refute String.contains?(face, "<svg")
    end

    test "generates consistent faces for the same seed" do
      face1 = avatar_face("consistent_face")
      _ = avatar_face("different_face")
      face2 = avatar_face("consistent_face")
      assert face1 == face2
    end

    test "respects custom avatar colors" do
      face = avatar_face("test", ["#112233"])
      assert String.contains?(face, "#112233")
    end
  end

  describe "darken/2" do
    test "darkens a color by the specified amount" do
      assert darken("#ff0000", 30) == "#00E100"
      assert darken("#00ff00", 50) == "#0000CD"
      assert darken("#0000ff", 100) == "#9B0000"
    end

    test "lightens a color when given negative amount" do
      assert darken("#550000", -30) == "#1E731E"
      assert darken("#005500", -100) == "#6464B9"
    end

    test "clamps at boundaries" do
      assert darken("#ffffff", 300) == "#000000"
      assert darken("#000000", -300) == "#FFFFFF"
    end
  end

  describe "create_svg/2" do
    test "creates an SVG with given size and children" do
      svg = create_svg(200, ["<rect width='100' height='100' fill='red'/>"])
      assert String.starts_with?(svg, "<svg")
      assert String.contains?(svg, "width='200'")
      assert String.contains?(svg, "height='200'")

      assert String.contains?(
               svg,
               "<rect width='100' height='100' fill='red'/>"
             )
    end
  end

  describe "seed_randomiser/1" do
    test "produces consistent random numbers for the same seed" do
      # First seed and get a random number
      seed_randomiser("test_seed")
      first = :rand.uniform_real()

      # Get another random number after the first one
      second = :rand.uniform_real()

      # Reseed with the same seed and get a new random number
      seed_randomiser("test_seed")
      third = :rand.uniform_real()

      # The first and third should be the same (same seed, first call)
      # The first and second should be different (different calls to uniform_real)
      assert first == third
      refute first == second

      # Different seed should produce different random numbers
      seed_randomiser("different_seed")
      different = :rand.uniform_real()
      refute first == different
    end
  end
end
