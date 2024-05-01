defmodule LiveSlides.Repo do
  use Ecto.Repo,
    otp_app: :live_slides,
    adapter: Ecto.Adapters.Postgres
end
