defmodule Hermes.Mixfile do
  use Mix.Project

  def project do
    [app: :hermes,
     description: """
     Is a mailer component for sending & recieving emails. The name comes from the greek messanger of the gods.
     """,
     version: "0.1.0",
     elixir: "~> 1.1",
     deps: deps,
     package: package]
  end

  def application do
    [
      mod: {Hermes, []},
      applications: [:logger]
    ]
  end

  defp deps do
    [ { :chronos, "~> 1.5.1" } ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      contributors: ["Johnny Winn"],
      licenses: ["Apache 2.0"],
      links: %{ "Github" => "https://github.com/nurugger07/hemes" }
    ]
  end
end
