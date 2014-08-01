defmodule Hermes.Client do

  # %{domain: domain, port: port, user: user, pword: password, from: email_address, to: email_address, body: body}
  def send(options) do
    options |> connect |> initiate |> authorize |> address |> send_mail |> quit
  end

  def connect(options) do
    { :ok, socket } = :gen_tcp.connect(options.domain, options.port, [:binary, {:active, true}])
    Map.merge options, %{socket: socket}
  end

  def initiate({:error, message}), do: { :error, message }
  def initiate(options) do
    :gen_tcp.send(options.socket, "EHLO")
    receive do
      { :tcp, socket, << "220", _ :: binary>> } ->
        options
    after
      500 ->
        { :error, options.socket, "Unable to establish a connection" }
    end
  end

  def authorize({:error, message}), do: { :error, message }
  def authorize(options) do
    user = :base64.encode(options.user) |> String.to_char_list
    password = :base64.encode options.pword |> String.to_char_list
    :gen_tcp.send(options.socket, "AUTH LOGIN\r\n")
    receive do
      { :tcp, _, << "334", _ :: binary>> } ->
        submit_credentials(options, [ user, password ])
      { :tcp, socket, << "4", _ :: binary >> } ->
        { :error, socket, "Unable to autheticate. Trya again later" }
      { :tcp, _, << "500", _ :: binary >>} ->
        authorize options
    after
      12000 ->
        { :error, options.socket, "Connection timeout for authorization" }
    end
  end

  def submit_credentials(options, [user | password]) do
    :gen_tcp.send(options.socket, user ++ "\r\n")
    receive do
      { :tcp, socket, << "334", _ :: binary >> } ->
        submit_credentials(options, [password])
      { :tcp, socket, << "235", _ :: binary >> } ->
        options
    after
      12000 ->
        { :error, options.socket, "Connection timeout for authorization" }
    end
  end

  def address({:error, socket, message}), do: { :error, socket, message }
  def address(options) do
    options |> sender(options.from) |> recipients(options.to)
  end

  def sender(options, << "<", _ :: binary >> = from) do
    :gen_tcp.send(options.socket, "MAIL FROM: #{from}\r\n")
    receive do
      { :tcp, socket, << "250", _ :: binary >> } ->
        options
    after
      12000 ->
        { :error, options.socket, "Connection timeout setting senders" }
    end
  end
  def sender(options, from), do: sender(options, "<#{from}>")

  def recipients(options, recipient) when is_binary recipient do
    recipients(options, [recipient])
  end
  def recipients(options, []), do: options
  def recipients(options, [ << "<", _ :: binary >> = recipient | t ]) do
    :gen_tcp.send(options.socket, "RCPT TO: #{recipient}\r\n")
    receive do
      { :tcp, socket, << "250", _ :: binary >> } ->
        recipients(options, t)
      anything ->
        IO.puts inspect anything
    after
      12000 ->
        { :error, options.socket, "Connection timeout setting recipients" }
    end
  end
  def recipients(options, [ recipient | t]) do
    recipients(options, [ "<#{recipient}>" | t ])
  end

  def send_mail({:error, socket, message}), do: { :error, socket, message }
  def send_mail(options) do

  end

  def quit({:error, socket, message}) do
    quit socket
    { :error, message }
  end

  def quit({:ok, socket, message}) do
    quit socket
    { :ok, message }
  end

  def quit(options) do
    :gen_tcp.send options.socket, "QUIT\r\n"
    :gen_tcp.close options.socket
  end
end
