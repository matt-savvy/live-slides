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
      %{title: title} = deck
      assert %PresentationState{title: ^title} = PresentationState.new(deck)
    end
  end

  describe "title/1" do
    test "returns the title" do
      title = "Some Presentation"
      assert title == PresentationState.title(%PresentationState{title: title})
    end
  end
end
