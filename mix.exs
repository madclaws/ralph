defmodule Ralph.MixProject do
  use Mix.Project

  def project do
    [
      app: :ralph,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      escript: [main_module: Ralph],
      deps: deps(),
      preferred_cli_env: [
        "test.watch": :test
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:aja, "~> 0.7.4"},
      {:mix_test_watch, "~> 1.2", only: [:test]}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
