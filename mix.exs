defmodule StoneChallenge.MixProject do
  use Mix.Project

  def project do
    [
      app: :stone_challenge,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.12"},
      {:httpoison, "~> 1.0"},
      {:excoveralls, "~> 0.8", only: :test},
      {:poison, "~> 3.1"},
      {:decimal, "~> 1.0"}
    ]
  end
end
