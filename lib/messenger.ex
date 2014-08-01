defmodule Hermes.Messenger do

  defmacro __using__(opts) do
    domain = Keyword.get(opts, :domain, "localhost") |> String.to_char_list
    port = Keyword.get(opts, :port, 2525)
    username = Keyword.get(opts, :username, "")
    password = Keyword.get(opts, :password, "")
    require_auth = Keyword.get(opts, :require_auth, false)

    quote do
      import unquote(__MODULE__)
      import Hermes.Transmitter
      import Hermes.Message

      def deliver(message) do
        message |> format |> package |> transmit
      end

      def deliver!(message) do
        { _, message } = deliver(message)
        message
      end

      def deliver(message, :async) do
        Task.async &(deliver &1)
      end

      def deliver!(message, :async) do
        Task.async &(deliver! &1)
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
