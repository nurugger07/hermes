defmodule Hermes.Transmitter do
  use GenServer

  def start_link,
    do: GenServer.start_link(__MODULE__, [])

  def transmit(pid, message, caller),
    do: GenServer.cast(pid, {:transmit, message, caller})

  @doc """
  The Hermes transmitter module is responsible for transmitting emails to the SMTP server.

  %{domain: domain, port: port, user: user, pword: password, from: email_address, to: email_address, body: body}
  """
  def handle_cast({:transmit, message, caller}, _state) do
    result = message
    |> connect
    |> initiate
    |> authorize
    |> address
    |> send_mail
    |> quit

    send(caller, result)

    {:stop, :normal, ""}
  end

  defp connect(options) do
    { :ok, socket } = :gen_tcp.connect(options.domain, options.port, [:binary, {:active, true}])
    Map.merge options, %{socket: socket}
  end

  defp initiate({:error, message}), do: { :error, message }
  defp initiate(options) do
    :gen_tcp.send(options.socket, "EHLO")
    receive do
      { :tcp, _socket, << "220", _ :: binary>> } ->
        options
    after
      500 ->
        { :error, options.socket, "Unable to establish a connection" }
    end
  end

  defp authorize({:error, message}), do: { :error, message }
  defp authorize(options) do
    user = :base64.encode(options.user) |> String.to_char_list
    password = :base64.encode options.pword |> String.to_char_list
    :gen_tcp.send(options.socket, "AUTH LOGIN\r\n")
    receive do
      { :tcp, _, << "334", _ :: binary>> } ->
        submit_credentials(options, [ user, password ])
      { :tcp, socket, << "4", _ :: binary >> } ->
        { :error, socket, "Unable to autheticate. Try again later" }
      { :tcp, _, << "500", _ :: binary >>} ->
        authorize options
    after
      12000 ->
        { :error, options.socket, "Connection timeout for authorization" }
    end
  end

  defp submit_credentials(options, [user | password]) do
    :gen_tcp.send(options.socket, user ++ "\r\n")
    receive do
      { :tcp, _socket, << "334", _ :: binary >> } ->
        submit_credentials(options, [password])
      { :tcp, _socket, << "235", _ :: binary >> } ->
        options
      { :tcp, socket, << "4", _ :: binary >> } ->
        { :error, socket, "Unable to submit credentials" }
    after
      12000 ->
        { :error, options.socket, "Connection timeout for authorization" }
    end
  end

  defp address({:error, socket, message}),
    do: { :error, socket, message }
  defp address(options),
    do: options |> sender(options.from) |> recipients(options.to)

  defp sender(options, << "<", _ :: binary >> = from) do
    :gen_tcp.send(options.socket, "MAIL FROM: #{from}\r\n")
    receive do
      { :tcp, _socket, << "250", _ :: binary >> } ->
        options
      { :tcp, socket, << "4", _ :: binary >> } ->
        { :error, socket, "Unable to set sender" }
    after
      12000 ->
        { :error, options.socket, "Connection timeout setting senders" }
    end
  end
  defp sender(options, from),
    do: sender(options, "<#{from}>")

  defp recipients(options, recipient) when is_binary(recipient),
    do: recipients(options, [recipient])
  defp recipients(options, []),
    do: options
  defp recipients(options, [ << "<", _ :: binary >> = recipient | t ]) do
    :gen_tcp.send(options.socket, "RCPT TO: #{recipient}\r\n")
    receive do
      { :tcp, _socket, << "250", _ :: binary >> } ->
        recipients(options, t)
      { :tcp, socket, << "4", _ :: binary >> } ->
        { :error, socket, "Unable to set recipients" }
    after
      12000 ->
        { :error, options.socket, "Connection timeout setting recipients" }
    end
  end
  defp recipients(options, [ recipient | t]),
    do: recipients(options, [ "<#{recipient}>" | t ])

  defp send_mail({:error, socket, message}),
    do: { :error, socket, message }
  defp send_mail(options) do
    :gen_tcp.send(options.socket, "DATA\r\n")
    receive do
      { :tcp, _socket, << "354", _ :: binary >> } ->
        transmit_data(options)
      { :tcp, socket, << "4", _ :: binary >> } ->
        { :error, socket, "Unable to prepare data transmition" }
    after
      12000 ->
        { :error, options.socket, "Connection timeout setting recipients" }
    end
  end

  defp transmit_data(options) do
    body = options.body <> "\r\n.\r\n"
    :gen_tcp.send(options.socket, body)
    receive do
      { :tcp, socket, << "250", _ :: binary >> } ->
        { :ok, socket, "Message transmitted" }
      { :tcp, socket, << "4", _ :: binary >> } ->
        { :error, socket, "Unable to transmit data" }
    after
      12000 ->
        { :error, options.socket, "Connection timeout setting recipients" }
    end
  end

  defp quit({:error, socket, message}) do
    quit socket
    { :error, message }
  end

  defp quit({:ok, socket, message}) do
    quit socket
    { :ok, message }
  end

  defp quit(socket) do
    :gen_tcp.send socket, "QUIT\r\n"
    :gen_tcp.close socket
  end
end
