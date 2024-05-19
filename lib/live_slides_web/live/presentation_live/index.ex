defmodule LiveSlidesWeb.PresentationLive.Index do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.PresentationServer
  alias Phoenix.VerifiedRoutes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    user_id = socket.assigns.current_user.id

    tagged_presentations =
      Presentations.list_presentations(%{user_id: user_id})
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

  @impl true
  def handle_event("copy-link", %{"id" => id}, socket) do
    url =
      case PresentationServer.exists?(id) do
        true ->
          VerifiedRoutes.url(socket, ~p"/presentations/live/#{id}")

        false ->
          VerifiedRoutes.url(socket, ~p"/presentations/view/#{id}")
      end

    {:noreply, socket |> push_event("copyLink", %{url: url})}
  end
end
