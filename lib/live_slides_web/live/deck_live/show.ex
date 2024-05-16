defmodule LiveSlidesWeb.DeckLive.Show do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:deck, Presentations.get_deck!(id))}
  end

  defp page_title(:show), do: "Show Deck"
  defp page_title(:edit), do: "Edit Deck"

  @impl true
  def handle_event("present", _params, socket) do
    {:ok, id} = Presentations.present(socket.assigns.deck)

    {:noreply, socket |> push_navigate(to: ~p"/presentations/present/#{id}")}
  end
end
