defmodule Mix.Tasks.Profile do
  use Mix.Task

  @moduledoc """
  Profile identicon generation performance across sizes and options.

  Runs the profiling script at `priv/profile.exs` which measures execution
  time and SVG output size for various configurations.

  ## Usage

      mix profile
  """

  @shortdoc "Profile identicon generation performance"

  @impl true
  def run(_args) do
    Mix.Task.run("run", ["priv/profile.exs"])
  end
end
