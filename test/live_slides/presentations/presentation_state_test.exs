defmodule LiveSlides.Presentations.PresentationStateTest do
  use LiveSlides.DataCase

  import LiveSlides.PresentationsFixtures
  alias LiveSlides.Presentations.PresentationState

  setup do
    deck = deck_fixture()

    %{deck: deck}
  end

  describe "new/1" do
    test "creates new PresentationState from deck", %{deck: deck} do
      id = Ecto.UUID.generate()
      %{title: title, slides: slides} = deck

      assert %PresentationState{id: ^id, title: ^title, slides: ^slides} =
               PresentationState.new(id, deck)
    end

    test "creates new PresentationState from Presentation" do
      %{id: id, title: title, slides: slides} = presentation = presentation_fixture()

      assert %PresentationState{id: ^id, title: ^title, slides: ^slides} =
               PresentationState.new(presentation)
    end
  end

  describe "title/1" do
    test "returns the title" do
      title = "Some Presentation"
      assert title == PresentationState.title(%PresentationState{title: title})
    end
  end

  describe "get_slide/1" do
    test "returns the current slide", %{deck: deck} do
      [first_slide | _rest] = deck.slides

      state = %PresentationState{
        slides: deck.slides
      }

      assert first_slide == PresentationState.get_slide(state)
    end
  end

  describe "next_slide/1" do
    test "pops head and pushes onto prev_slides", %{deck: deck} do
      state = %PresentationState{
        slides: deck.slides
      }

      [first_slide | updated_slides] = deck.slides

      assert %PresentationState{
               slides: ^updated_slides,
               prev_slides: [^first_slide]
             } = PresentationState.next_slide(state)
    end

    test "is no-op when no remaining slides", %{deck: deck} do
      slides = Enum.take(deck.slides, 1)

      state = %PresentationState{
        slides: slides
      }

      assert ^state = PresentationState.next_slide(state)
    end
  end

  describe "prev_slide/1" do
    test "restores the head", %{deck: deck} do
      [first | rest] = slides = deck.slides

      state = %PresentationState{
        slides: rest,
        prev_slides: [first]
      }

      assert %PresentationState{
               slides: ^slides,
               prev_slides: []
             } = PresentationState.prev_slide(state)
    end

    test "is no-op when no previous slides" do
      state = %PresentationState{
        prev_slides: []
      }

      assert ^state = PresentationState.prev_slide(state)
    end
  end
end
