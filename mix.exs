defmodule Cart.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cart_manager,
      version: "0.1.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     mod: {Cart, []}]
  end

  defp deps do
    [
      {:excoveralls, github: "parroty/excoveralls", only: :test}
    ]
  end
end
