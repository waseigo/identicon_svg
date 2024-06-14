defmodule IdenticonSvg.MixProject do
  use Mix.Project

  def project do
    [
      app: :identicon_svg,
      version: "0.9.1",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),

      # Docs
      name: "IdenticonSvg",
      source_url: "https://github.com/waseigo/identicon_svg",
      homepage_url: "https://blog.waseigo.com/tags/identicon_svg/",
      docs: [
        # The main page in the docs
        main: "IdenticonSvg",
        logo: "./assets/logo.png",
        assets: "etc/assets",
        extras: ["README.md"]
      ]
    ]
  end

  defp description do
    """
    An Elixir library to generate Github-style identicons in SVG format with a small file size, so that they can be inlined in HTML.
    """
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Isaak Tsalicoglou"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/waseigo/identicon_svg"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto, :eex]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end
end
