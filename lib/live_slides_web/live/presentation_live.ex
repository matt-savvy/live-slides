defmodule LiveSlidesWeb.PresentationLive do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations
  alias LiveSlides.Presentations.PresentationServer

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    case PresentationServer.exists?(id) do
      true -> {:ok, socket}
      false -> raise LiveSlidesWeb.PresentationLive.NotFound
    end
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    title = PresentationServer.title(id)
    :ok = Presentations.subscribe(id)

    %{body: body} = PresentationServer.get_slide(id)
    {:noreply, socket |> assign(:page_title, title) |> assign(:id, id) |> assign(:body, body)}
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
  def handle_info({:slide_changed, slide}, socket) do
    %{body: body} = slide
    {:noreply, socket |> assign(:body, body)}
  end

  @impl true
  def handle_info(:finished, socket) do
    {:noreply, socket |> put_flash(:info, "The presentation has ended.")}
  end
end
