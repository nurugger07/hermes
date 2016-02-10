defmodule SimpleMessenger do
  use Hermes.Messenger
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
  end
end
