defmodule Hermes.Supervisor do
  use Supervisor

  def start_link(_type, _args),
    do: Supervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_opts) do
    children = [
      worker(Hermes.Transmitter, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  def start_transmitter,
    do: Supervisor.start_child(__MODULE__, [])
end
