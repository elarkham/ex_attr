defmodule ExAttr.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_attr,
      version: "1.0.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      name: "ExAttr",
      source_url: "https://github.com/elarkham/ex_attr"
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
      {:rustler, "~> 0.33.0", runtime: false}
    ]
  end

  defp description do
    "Native extended attribute interface for Elixir using rustler + the xattr crate"
  end

  defp package do
    [
      name: "ex_attr",

      files: ~w(lib priv native .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/elarkham/ex_attr"}
    ]
  end
end
