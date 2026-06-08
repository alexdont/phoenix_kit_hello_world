defmodule PhoenixKitHelloWorld.MixProject do
  use Mix.Project

  @version "0.1.6"
  @source_url "https://github.com/BeamLabEU/phoenix_kit_hello_world"

  def project do
    [
      app: :phoenix_kit_hello_world,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex
      description:
        "Hello World demo module for PhoenixKit — use as a template for your own plugins",
      package: package(),

      # Dialyzer
      dialyzer: [plt_add_apps: [:phoenix_kit]],

      # Docs
      name: "PhoenixKitHelloWorld",
      source_url: @source_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :phoenix_kit]
    ]
  end

  # test/support/ is compiled only in :test so DataCase and TestRepo
  # don't leak into the published package.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.ci": ["format --check-formatted", "credo --strict", "dialyzer"],
      precommit: ["compile", "quality"],
      "test.setup": [
        "ecto.create --quiet -r PhoenixKitHelloWorld.Test.Repo"
      ],
      "test.reset": [
        "ecto.drop --quiet -r PhoenixKitHelloWorld.Test.Repo",
        "test.setup"
      ]
    ]
  end

  # phoenix_kit deps resolve from Hex by default. For cross-repo work against a
  # local checkout, export <APP>_PATH — e.g. PHOENIX_KIT_PATH=../phoenix_kit or
  # PHOENIX_KIT_AI_PATH=../phoenix_kit_ai. Unset => the published pin, so
  # mix hex.publish is unaffected.
  defp pk_dep(app, requirement, opts \\ []) do
    env_var = String.upcase(Atom.to_string(app)) <> "_PATH"

    case System.get_env(env_var) do
      nil when opts == [] -> {app, requirement}
      nil -> {app, requirement, opts}
      path -> {app, [path: path, override: true] ++ opts}
    end
  end

  defp deps do
    [
      # PhoenixKit provides the Module behaviour and Settings API.
      pk_dep(:phoenix_kit, "~> 1.7"),

      # LiveView is needed for the admin page.
      {:phoenix_live_view, "~> 1.1"},

      # Optional: add ex_doc for generating documentation
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},

      # Code quality
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},

      # HTML parser for Phoenix.LiveViewTest in LiveView smoke tests
      {:lazy_html, ">= 0.1.0", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "PhoenixKitHelloWorld",
      source_ref: "v#{@version}"
    ]
  end
end
