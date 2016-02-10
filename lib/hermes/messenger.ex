defmodule Hermes.Messenger do

  defmacro __using__(opts) do
    domain = Keyword.get(opts, :domain, Application.get_env(:hermes, :domain, "localhost")) |> String.to_char_list
    port = Keyword.get(opts, :port, Application.get_env(:hermes, :port, 2525))
    username = Keyword.get(opts, :username, Application.get_env(:hermes, :username, ""))
    password = Keyword.get(opts, :password, Application.get_env(:hermes, :password, ""))
    require_auth = Keyword.get(opts, :require_auth, Application.get_env(:hermes, :require_auth, false))

    quote do
      import unquote(__MODULE__)
      import Hermes.Message

      alias Hermes.Transmitter

      def deliver(message),
        do: message |> format |> package |> transmit

      def deliver(message, :async) do
        Task.async fn() ->
          deliver message
        end
      end

      defp transmit(message) do
        {:ok, pid} = Hermes.Supervisor.start_transmitter
        Transmitter.transmit(pid, message, self)
        receive do
          notification ->
            notification
        end
      end

      def package(message) do
        %{
           domain: unquote(domain),
           port: unquote(port),
           user: unquote(username),
           pword: unquote(password),
           from: message.from,
           to: [message.to],
           body: message.body
         }
      end
    end
  end
end
