defmodule Nham.Repo do
  use Ecto.Repo,
    otp_app: :nham,
    adapter: Ecto.Adapters.Postgres
end
