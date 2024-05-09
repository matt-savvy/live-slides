defmodule LiveSlidesWeb.PresentationLive do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations.PresentationServer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    title = PresentationServer.title(id)
    {:noreply, socket |> assign(:page_title, title)}
  end
end
