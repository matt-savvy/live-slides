defmodule LiveSlides.Presentations.PresentationServerTest do
  use LiveSlides.DataCase

  import LiveSlides.PresentationsFixtures

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.PresentationServer

  test "integration test" do
    deck = deck_fixture()
    [first_slide, second_slide, third_slide] = deck.slides
    id = Ecto.UUID.generate()

    other_deck = deck_fixture()
    other_id = Ecto.UUID.generate()

    refute PresentationServer.exists?(id)
    start_supervised!({PresentationServer, {id, deck}}, id: id)
    assert PresentationServer.exists?(id)
    start_supervised!({PresentationServer, {other_id, other_deck}}, id: other_id)
    assert :ok = Presentations.subscribe(id)

    assert deck.title == PresentationServer.title(id)
    assert first_slide == PresentationServer.get_slide(id)
    PresentationServer.next_slide(id)
    assert second_slide == PresentationServer.get_slide(id)

    assert_receive {:slide_changed, ^second_slide}

    PresentationServer.next_slide(id)
    assert third_slide == PresentationServer.get_slide(id)

    # no op
    PresentationServer.next_slide(id)
    assert third_slide == PresentationServer.get_slide(id)

    PresentationServer.prev_slide(id)
    assert second_slide == PresentationServer.get_slide(id)

    PresentationServer.prev_slide(id)
    assert first_slide == PresentationServer.get_slide(id)

    # no op
    PresentationServer.prev_slide(id)
    assert first_slide == PresentationServer.get_slide(id)
  end
end
