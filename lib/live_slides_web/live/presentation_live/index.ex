defmodule LiveSlidesWeb.PresentationLive.Index do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    tagged_presentations =
      Presentations.list_presentations()
      |> Presentations.tag_live_presentations()

    {:noreply, assign(socket, :presentations, tagged_presentations)}
  end

  @impl true
  def handle_event("present", %{"id" => id}, socket) do
    presentation = Presentations.get_presentation!(id)

    case Presentations.present(presentation) do
      {:ok, ^id} ->
        {:noreply, socket |> push_navigate(to: ~p"/presentations/present/#{id}")}

      {:error, :already_started} ->
        {:noreply,
         socket
         |> put_flash(:error, "This Presentation is already Live!")
         |> push_navigate(to: ~p"/presentations/present/#{id}")}
    end
  end
end
