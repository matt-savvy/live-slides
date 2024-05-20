defmodule LiveSlides.Presentations.PresentationServerTest do
  use LiveSlides.DataCase

  import LiveSlides.PresentationsFixtures

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.{PresentationServer, PresentationState}

  test "integration test" do
    deck = deck_fixture()
    [first_slide, second_slide, third_slide] = deck.slides
    id = Ecto.UUID.generate()

    other_deck = deck_fixture()
    other_id = Ecto.UUID.generate()

    refute PresentationServer.exists?(id)
    assert {:error, :not_found} == PresentationServer.whereis(Ecto.UUID.generate())

    pid = start_supervised!({PresentationServer, {id, deck}}, id: id)
    assert PresentationServer.exists?(id)

    assert PresentationState.new(id, deck) == PresentationServer.get_state(id)

    %{id: presentation_id} = presentation = presentation_fixture()

    start_supervised!({PresentationServer, {presentation_id, presentation}},
      id: presentation_id
    )

    assert PresentationServer.exists?(id)

    start_supervised!({PresentationServer, {other_id, other_deck}}, id: other_id)
    assert :ok = Presentations.subscribe(id)

    assert {:ok, ^pid} = PresentationServer.whereis(id)

    assert deck.title == PresentationServer.title(id)
    assert deck.user_id == PresentationServer.user_id(id)
    assert first_slide == PresentationServer.get_slide(id)
    PresentationServer.next_slide(id)
    assert second_slide == PresentationServer.get_slide(id)

    assert_receive {:slide_changed, ^second_slide}

    PresentationServer.next_slide(id)
    assert third_slide == PresentationServer.get_slide(id)
    # assert here to make sure this message is no longer in the
    # mailbox before we test the no-op case
    assert_receive {:slide_changed, ^third_slide}

    # no op
    PresentationServer.next_slide(id)
    assert third_slide == PresentationServer.get_slide(id)
    refute_receive {:slide_changed, ^third_slide}

    %{slides: [slide_1, slide_2, slide_3], title: title} = deck

    assert %PresentationState{
             id: ^id,
             title: ^title,
             slides: [^slide_3],
             prev_slides: [^slide_2, ^slide_1]
           } = PresentationServer.get_state(id)

    PresentationServer.prev_slide(id)
    assert second_slide == PresentationServer.get_slide(id)

    PresentationServer.prev_slide(id)
    assert first_slide == PresentationServer.get_slide(id)
    # assert here to make sure this message is no longer in the
    # mailbox before we test the no-op case
    assert_receive {:slide_changed, ^first_slide}

    # no op
    PresentationServer.prev_slide(id)
    assert first_slide == PresentationServer.get_slide(id)
    refute_receive {:slide_changed, ^first_slide}
  end

  test "stops after timeout and broadcasts" do
    timeout = 50
    Application.put_env(:live_slides, :timeout, timeout)
    id = Ecto.UUID.generate()
    deck = deck_fixture()
    Presentations.subscribe(id)
    pid = start_supervised!({PresentationServer, {id, deck}}, id: id)

    Process.sleep(timeout + 10)

    refute Process.alive?(pid)

    assert_receive {:finished, %PresentationState{}}
    refute PresentationServer.exists?(id)

    on_exit(fn ->
      Application.delete_env(:live_slides, :timeout)
    end)
  end
end
