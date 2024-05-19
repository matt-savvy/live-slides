defmodule LiveSlidesWeb.DeckLive.FormComponent do
  use LiveSlidesWeb, :live_component

  alias LiveSlides.Presentations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage deck records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="deck-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.inputs_for :let={f_nested} field={@form[:slides]}>
          <div>
            <label class="block cursor-pointer">
              <input
                type="checkbox"
                name="deck[slide_delete][]"
                value={f_nested.index}
                class="hidden"
              />
              <.icon name="hero-x-mark" /> Delete
            </label>

            <input type="hidden" name="deck[slide_order][]" value={f_nested.index} />
            <.input type="textarea" rows={12} field={f_nested[:body]} />
          </div>
        </.inputs_for>

        <label class="block cursor-pointer">
          <input type="checkbox" name="deck[slide_order][]" class="hidden" />
          <.icon name="hero-plus-circle" /> Add more
        </label>

        <:actions>
          <.button phx-disable-with="Saving...">Save Deck</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{deck: deck} = assigns, socket) do
    changeset = Presentations.change_deck(deck)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"deck" => deck_params}, socket) do
    changeset =
      socket.assigns.deck
      |> Presentations.change_deck(deck_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"deck" => deck_params}, socket) do
    save_deck(socket, socket.assigns.action, deck_params)
  end

  defp save_deck(socket, :edit, deck_params) do
    case Presentations.update_deck(socket.assigns.deck, deck_params) do
      {:ok, deck} ->
        notify_parent({:saved, deck})

        {:noreply,
         socket
         |> put_flash(:info, "Deck updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_deck(socket, :new, deck_params) do
    deck_params = Map.put(deck_params, "user_id", socket.assigns.deck.user_id)

    case Presentations.create_deck(deck_params) do
      {:ok, deck} ->
        notify_parent({:saved, deck})

        {:noreply,
         socket
         |> put_flash(:info, "Deck created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
