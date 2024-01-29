defmodule HttpJobProcessing.MixProject do
  use Mix.Project

  def project do
    [
      app: :http_job_processing,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "HttpJobProcessing",
      source_url: "https://github.com/ocraciun/http_job_processing",
      homepage_url: "localhost:4001",
      docs: [
        main: "HttpJobProcessing",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :plug_cowboy],
      mod: {HttpJobProcessing.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end
end
