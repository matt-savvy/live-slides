defmodule LiveSlidesWeb.PresentationLive do
  use LiveSlidesWeb, :live_view

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
    {:noreply, socket |> assign(:page_title, title)}
  end
end
