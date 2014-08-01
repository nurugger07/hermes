defmodule SimpleMessenger do
  use Hermes.Messenger, [
    domain: "mailtrap.io",
    port: 2525,
    username: "your_user_here",
    password: "your_password_here",
  ]
end

defmodule HermesTest do
  use ExUnit.Case

  import SimpleMessenger

  @message %Hermes.Message{
    from: "johnny+from@elixir-fountain.com",
    to: "johnny+to@elixir-fountain.com",
    subject: "Hello, World!",
    body: """
    Hello!

    This is the first email sent through hermes.

    Thanks,
    Johnny
    """
  }

  test "send emails" do
    assert { :ok, "Message transmitted" } == deliver @message
    assert "Message transmitted" == deliver! @message
  end
end
