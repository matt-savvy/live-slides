# LiveSlides

Build slide decks using Markdown.
Present and share them with a link so your audience can follow your slides, right in their own browser.

- Create a `Deck`, write your slides using Markdown.
- When you present a `Deck`, a `Presentation` will be created.
- When the `Presentation` is live, your audience will be able to use the public link.
Their view will update as the presenter advances and rewinds the slides.
- When the `Presentation` is finished, your audience will be able to review the slides on their own.

## Setup

```
# start nix shell
nix-shell

# start DB container
docker-compose up -d

# install deps
mix deps.get

# create, migrate, and seed DB
mix ecto.setup
```

## Running Locally

### Single Node

```
mix phx.server
```

### Clustered

In one terminal tab:
```
PORT=4000 iex --name a@127.0.0.1 --cookie lorem -S mix phx.server
```

In another terminal tab:
```
PORT=4001 iex --name b@127.0.0.1 --cookie lorem -S mix phx.server
```

Then, connect the nodes.
```elixir
iex(b@127.0.0.1)1> Node.connect(:"a@127.0.0.1")
true
iex(b@127.0.0.1)2> Node.list
[:"a@127.0.0.1"]
```

## Production

### `LiveSlides.Mailer`

For current (demo) use, the `Mailer` module is disabled.
See config/runtime.exs
