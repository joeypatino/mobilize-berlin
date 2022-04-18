defmodule Mobilizon.Events.Participant do
  @moduledoc """
  Represents a participant, an actor participating to an event.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.{Event, ParticipantRole}
  alias Mobilizon.Events.Participant.Metadata

  alias Mobilizon.Web.Endpoint

  @type t :: %__MODULE__{
          id: String.t(),
          role: atom(),
          code: String.t(),
          url: String.t(),
          event: Event.t(),
          actor: Actor.t(),
          metadata: map()
        }

  @required_attrs [:url, :role, :event_id, :actor_id]
  @optional_attrs [:code]
  @attrs @required_attrs ++ @optional_attrs

  @timestamps_opts [type: :utc_datetime]

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "participants" do
    field(:role, ParticipantRole, default: :participant)
    field(:url, :string)
    field(:code, :string)

    embeds_one(:metadata, Metadata, on_replace: :delete)

    belongs_to(:event, Event, primary_key: true)
    belongs_to(:actor, Actor, primary_key: true)

    timestamps()
  end

  @doc """
  We check that the actor asking to leave the event is not it's only organizer.
  We start by fetching the list of organizers and if there's only one of them
  and that it's the actor requesting leaving the event we return true.
  """
  @spec is_not_only_organizer(integer | String.t(), integer | String.t()) :: boolean
  def is_not_only_organizer(event_id, actor_id) do
    case Events.list_organizers_participants_for_event(event_id) do
      [%__MODULE__{actor: %Actor{id: participant_actor_id}}] ->
        participant_actor_id == actor_id

      _ ->
        false
    end
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = participant, attrs) do
    participant
    |> cast(attrs, @attrs)
    |> cast_embed(:metadata)
    |> ensure_url()
    |> add_code()
    |> validate_required(@required_attrs)
    |> unique_constraint(:actor_id, name: :participants_event_id_actor_id_index)
  end

  # If there's a blank URL that's because we're doing the first insert
  @spec ensure_url(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp ensure_url(%Ecto.Changeset{data: %__MODULE__{url: nil}} = changeset) do
    case fetch_change(changeset, :url) do
      {:ok, _url} ->
        changeset

      :error ->
        update_url(changeset)
    end
  end

  defp ensure_url(%Ecto.Changeset{} = changeset), do: changeset

  defp update_url(%Ecto.Changeset{} = changeset) do
    uuid = Ecto.UUID.generate()
    url = generate_url(uuid)

    changeset
    |> put_change(:id, uuid)
    |> put_change(:url, url)
  end

  @spec generate_url(String.t()) :: String.t()
  defp generate_url(uuid), do: "#{Endpoint.url()}/join/event/#{uuid}"

  @spec add_code(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp add_code(%Ecto.Changeset{} = changeset) do
    case fetch_field(changeset, :code) do
      {:data, nil} -> put_change(changeset, :code, generate_code())
      {_, _code} -> changeset
      :error -> put_change(changeset, :code, generate_code())
    end
  end

  # No lookalike symbols
  @symbols '6789BCDFGHJKLMNPQRTW'
  @symbol_count Enum.count(@symbols) - 1
  @code_length 6

  @spec generate_code :: String.t()
  defp generate_code do
    for _ <- 1..@code_length,
        into: "",
        do: <<Enum.at(@symbols, :rand.uniform(@symbol_count))>>
  end
end
