defmodule Hermes.Client do

  # %{domain: domain, port: port, user: user, pword: password, from: email_address, to: email_address, body: body}
  def send(options) do
    options |> connect |> handshake |> authorize
      # address |>
      # send_mail |>
      # quit
  end

  def connect(options) do
    { :ok, socket } = :gen_tcp.connect(options.domain, options.port, [:binary, {:active, true}])
    Map.merge options, %{socket: socket}
  end

  def handshake({:error, message}), do: { :error, message }
  def handshake(options) do
    :gen_tcp.send(options.socket, "EHLO")
    receive do
      { :tcp, socket, << "220", _ :: binary>> } ->
        options
    after
      500 ->
        { :error, "Unable to establish a connection" }
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
      { :tcp, _, << "4", _ :: binary >> } ->
        { :error, "Unable to autheticate. Trya again later" }
      { :tcp, _, << "500", _ :: binary >>} ->
        authorize options
    after
      12000 ->
        { :error, "Connection timeout for authorization" }
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
        { :error, "Connection timeout for authorization" }
    end
  end

  def address({:error, message}), do: { :error, message }
  def address(options) do

  end

  def send_mail() do

  end

  def quit do

  end
end
