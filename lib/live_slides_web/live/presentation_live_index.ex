defmodule LiveSlidesWeb.PresentationLive.Index do
  use LiveSlidesWeb, :live_view

  alias LiveSlides.Presentations

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    presentations = Presentations.list_presentations()

    {:noreply, assign(socket, :presentations, presentations)}
  end
end
