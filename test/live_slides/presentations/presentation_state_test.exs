defmodule LiveSlides.Presentations.PresentationStateTest do
  use LiveSlides.DataCase

  import LiveSlides.PresentationsFixtures
  alias LiveSlides.Presentations.PresentationState

  setup do
    deck = deck_fixture()

    %{deck: deck}
  end

  describe "new/1" do
    test "creates new PresentationState", %{deck: deck} do
      %{title: title, slides: slides} = deck
      assert %PresentationState{title: ^title, slides: ^slides} = PresentationState.new(deck)
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
    test "moves the head", %{deck: deck} do
      state = %PresentationState{
        slides: deck.slides
      }

      updated_slides = Enum.drop(deck.slides, 1)

      assert %PresentationState{
               slides: ^updated_slides
             } = PresentationState.next_slide(state)
    end

    test "is no-op when no remaining slides" do
      state = %PresentationState{
        slides: []
      }

      assert ^state = PresentationState.next_slide(state)
    end
  end
end
