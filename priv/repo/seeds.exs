# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LiveSlides.Repo.insert!(%LiveSlides.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias LiveSlides.Accounts
alias LiveSlides.Presentations

{:ok, user} =
  Accounts.register_user(%{email: "matt@1-800-rad-dude.com", password: "KS4E8zTH64283v"})

{:ok, _deck} =
  Presentations.create_deck(%{
    title: "Test Deck 1",
    user_id: user.id,
    slides: [
      %{body: "first slide"},
      %{body: "second slide"},
      %{body: "third slide"},
      %{body: "fourth slide"},
      %{body: "fifth slide"}
    ]
  })
