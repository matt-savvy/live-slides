defmodule LiveSlidesWeb.PresentationLive do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.{PresentationServer, PresentationState}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, apply_action(socket, id, socket.assigns.live_action)}
  end

  def apply_action(socket, id, action) when action in [:present, :view] do
    if not PresentationServer.exists?(id) do
      raise LiveSlidesWeb.PresentationLive.NotFound
    end

    title = PresentationServer.title(id)
    :ok = Presentations.subscribe(id)

    %{body: body} = PresentationServer.get_slide(id)
    socket |> assign(:page_title, title) |> assign(:id, id) |> assign(:body, body)
  end

  def apply_action(socket, id, :view_solo) do
    deck = Presentations.list_decks() |> List.first()
    state = PresentationState.new(id, deck)
    title = PresentationState.title(state)
    %{body: body} = PresentationState.get_slide(state)

    socket
    |> assign(:page_title, title)
    |> assign(:id, id)
    |> assign(:body, body)
    |> assign(:state, state)
  end

  @impl true
  def handle_event("change-slide", %{"direction" => direction}, socket) do
    action =
      case direction do
        "next" -> :next_slide
        "prev" -> :prev_slide
      end

    apply(PresentationServer, action, [socket.assigns.id])
    {:noreply, socket}
  end

  @impl true
  def handle_event("finish", _params, socket) do
    Presentations.finish(socket.assigns.id)

    {:noreply, socket}
  end

  @impl true
  def handle_info({:slide_changed, slide}, socket) do
    %{body: body} = slide
    {:noreply, socket |> assign(:body, body)}
  end

  @impl true
  def handle_info(:finished, socket) do
    {:noreply, socket |> put_flash(:info, "The presentation has ended.")}
  end
end
