defmodule LiveSlidesWeb.DeckLive.Index do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.Deck

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, stream(socket, :decks, Presentations.list_decks(%{user_id: user_id}))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Deck")
    |> assign(:deck, Presentations.get_deck!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Deck")
    |> assign(:deck, %Deck{user_id: socket.assigns.current_user.id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Decks")
    |> assign(:deck, nil)
  end

  @impl true
  def handle_info({LiveSlidesWeb.DeckLive.FormComponent, {:saved, deck}}, socket) do
    {:noreply, stream_insert(socket, :decks, deck)}
  end

  @impl true
  def handle_event("present", %{"id" => id}, socket) do
    deck = Presentations.get_deck!(id)
    {:ok, id} = Presentations.present(deck)

    {:noreply, socket |> push_navigate(to: ~p"/presentations/present/#{id}")}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    deck = Presentations.get_deck!(id)
    {:ok, _} = Presentations.delete_deck(deck)

    {:noreply, stream_delete(socket, :decks, deck)}
  end
end
