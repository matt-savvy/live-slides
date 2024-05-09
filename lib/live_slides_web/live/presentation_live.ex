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
    {:noreply, socket |> assign(:page_title, title) |> assign(:body, body)}
  end

  @impl true
  def handle_info({:slide_changed, slide}, socket) do
    %{body: body} = slide
    {:noreply, socket |> assign(:body, body)}
  end
end
