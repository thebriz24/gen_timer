defmodule GenTimer.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_timer,
      version: "0.1.0",
      elixir: "~> 1.10",
      description: "A GenServer for asynchronously running a function after some duration.",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: [main: GenTimer]
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
      {:credo, "~> 1.4", only: [:dev, :test]},
      {:ex_doc, "~> 0.21", only: [:dev]}
    ]
  end

  defp package do
    [
      maintainers: ["thebriz24"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/thebriz24/gen_timer"}
    ]
  end
end
