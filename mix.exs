defmodule GenTimer.MixProject do
  use Mix.Project

  def project do
    [
      app: :gen_timer,
      version: "0.0.2",
      elixir: "~> 1.6",
      description: "A GenServer for asynchronously running a function after some duration.",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
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
      {:credo, "~> 0.9.3", only: [:dev, :test]},
      {:ex_doc, "~> 0.18.3", only: [:dev]}
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
