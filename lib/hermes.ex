defmodule Hermes do
  use Application

  def start, do: start(:normal, [])
  def start(type, args),
    do: Hermes.Supervisor.start_link(type, args)

end
