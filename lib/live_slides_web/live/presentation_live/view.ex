defmodule LiveSlidesWeb.PresentationLive.View do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.{PresentationServer, PresentationState}
  alias Phoenix.VerifiedRoutes

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    {:noreply, apply_action(socket, id, socket.assigns.live_action)}
  end

  def apply_action(socket, id, :present) do
    user_id = socket.assigns.current_user.id

    with true <- PresentationServer.exists?(id),
         ^user_id <- PresentationServer.user_id(id) do
      title = PresentationServer.title(id)

      :ok = Presentations.subscribe(id)

      %{body: body} = PresentationServer.get_slide(id)
      presence_count = Presentations.tracked_count(id)

      socket
      |> assign(:page_title, title)
      |> assign(:id, id)
      |> assign(:body, body)
      |> assign(:presence_count, presence_count)
    else
      _ ->
        raise LiveSlidesWeb.PresentationLive.NotFound
    end
  end

  def apply_action(socket, id, :live) do
    if not PresentationServer.exists?(id) do
      socket
      |> push_patch(to: ~p"/presentations/view/#{id}", replace: true)
    else
      title = PresentationServer.title(id)
      :ok = Presentations.subscribe(id)

      if connected?(socket) do
        {:ok, _ref} =
          Presentations.track(id, socket.id)
      end

      %{body: body} = PresentationServer.get_slide(id)

      socket
      |> assign(:page_title, title)
      |> assign(:id, id)
      |> assign(:body, body)
    end
  end

  def apply_action(socket, id, :view) do
    state =
      id
      |> Presentations.get_presentation!()
      |> PresentationState.new()

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

    case socket.assigns.live_action do
      :present ->
        apply(PresentationServer, action, [socket.assigns.id])
        {:noreply, socket}

      :view ->
        next_state = apply(PresentationState, action, [socket.assigns.state])
        %{body: body} = PresentationState.get_slide(next_state)
        {:noreply, socket |> assign(:state, next_state) |> assign(:body, body)}
    end
  end

  @impl true
  def handle_event("finish", _params, socket) do
    Presentations.finish(socket.assigns.id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("copy-link", _, socket) do
    url = VerifiedRoutes.url(socket, ~p"/presentations/live/#{socket.assigns.id}")

    {:noreply, socket |> push_event("copyLink", %{url: url})}
  end

  @impl true
  def handle_info({:slide_changed, slide}, socket) do
    %{body: body} = slide
    {:noreply, socket |> assign(:body, body)}
  end

  @impl true
  def handle_info({:finished, state}, socket) do
    {
      :noreply,
      socket
      |> put_flash(:info, "The presentation has ended.")
      |> assign(:live_action, :view)
      |> assign(:state, state)
    }
  end

  @impl true
  def handle_info(
        %{
          event: "presence_diff",
          payload: %{leaves: leaves, joins: joins}
        },
        socket
      ) do
    case socket.assigns do
      %{presence_count: presence_count} ->
        presence_count = presence_count + Enum.count(joins) - Enum.count(leaves)
        {:noreply, socket |> assign(:presence_count, presence_count)}

      _ ->
        {:noreply, socket}
    end
  end
end
