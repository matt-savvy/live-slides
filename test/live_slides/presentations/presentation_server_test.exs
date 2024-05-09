defmodule LiveSlides.Presentations.PresentationServerTest do
  use LiveSlides.DataCase

  import LiveSlides.PresentationsFixtures

  alias LiveSlides.Presentations.PresentationServer

  test "integration test" do
    deck = deck_fixture()
    id = Ecto.UUID.generate()

    other_deck = deck_fixture()
    other_id = Ecto.UUID.generate()

    refute PresentationServer.exists?(id)
    start_supervised!({PresentationServer, {id, deck}}, id: id)
    assert PresentationServer.exists?(id)
    start_supervised!({PresentationServer, {other_id, other_deck}}, id: other_id)

    assert deck.title == PresentationServer.title(id)
  end
end
