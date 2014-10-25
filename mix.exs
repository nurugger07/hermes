Code.ensure_loaded?(Hex) and Hex.start

defmodule Hermes.Mixfile do
  use Mix.Project

  def project do
    [app: :hermes,
     version: "0.0.1",
     elixir: "~> 0.14.3",
     deps: deps,
     package: [
        files: ["lib", "mix.exs", "README*", "LICENSE*"],
        contributors: ["Johnny Winn"],
        licenses: ["Apache 2.0"],
        links: %{"github" => "https://github.com/nurugger07/hermes"}
      ],
      description: """
      Is a mailer component for sending & recieving emails. The name comes from the greek messanger of the gods.
      """
   ]
  end

  defp deps do
    [ { :chronos, "~> 0.3.4" } ]
  end
end
