Hermes - An Elixir Mailer
=========================

Is a mailer component for sending emails using SMTP. The name comes from the greek messanger of the gods.


## Using

Hermes is simple to add to any project. If you are using the hex package manager, just add the following to your mix file:

``` elixir
def deps do
  [ { :hermes, '~> 0.1.0' } ]
end
```

If you aren't using hex, add the a reference to the github repo.

``` elixir
def deps do
  [ { :hermes, github: "nurugger07/hermes" } ]
end
```

Ensure that Hermes is started in the your mix file:

``` elixir
def application do
  [applications: [:hermes]]
end
```

Then run `mix deps.get` in the shell to fetch and compile the dependencies. Next setup the config. There are default values but you most likely will need to add your own settings:

``` elixir

config :hermes,
  [domain: "your-smtp-server",
   username: "your-username",
   password: "your-password"]

```

## Simple Example

Add a module to work as the messenger:

``` elixir
defmodule SimpleMessenger do
  use Hermes.Messenger
end
```

Then create a message struct and call deliver:

``` elixir
%Hermes.Message{
  from: "johnny+from@example.com",
  to: "johnny+to@example.com",
  subject: "Hello, World!",
  body: """
  Hello!

  This is my first email sent through hermes.

  Thanks,
  Johnny
  """} |> SimpleMessenger.deliver
```

## Next Steps

This library is starting out but has the basic building blocks to send emails over SMTP. More features to come soon! If you are interested in contributing, please feel welcome to submit a pull request.
