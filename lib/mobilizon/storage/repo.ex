defmodule Mobilizon.Storage.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :mobilizon,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the DATABASE_URL environment variable.
  """
  @spec init(any(), any()) :: {:ok, Keyword.t()}
  def init(_, opts) do
    {:ok, opts}
  end
end
