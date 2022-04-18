defmodule Mobilizon.Activities.Activity do
  @moduledoc """
  Any activity for users
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Mobilizon.Activities.{ObjectType, Priority, Subject, Type}
  alias Mobilizon.Actors.Actor

  @required_attrs [:type, :subject, :author_id, :group_id, :inserted_at]
  @optional_attrs [
    :priority,
    :subject_params,
    :message,
    :message_params,
    :object_type,
    :object_id,
    :object
  ]
  @attrs @required_attrs ++ @optional_attrs

  @type t :: %__MODULE__{
          priority: pos_integer(),
          type: String.t(),
          subject: String.t(),
          subject_params: map(),
          message: String.t(),
          message_params: map(),
          object_type: String.t(),
          object_id: String.t(),
          object: map(),
          author: Actor.t(),
          group: Actor.t()
        }

  schema "activities" do
    field(:priority, Priority, default: :medium)
    field(:type, Type)
    field(:subject, Subject)
    field(:subject_params, :map, default: %{})
    field(:message, :string)
    field(:message_params, :map, default: %{})
    field(:object_type, ObjectType)
    field(:object_id, :string)
    field(:object, :map, virtual: true)
    field(:inserted_at, :utc_datetime)
    belongs_to(:author, Actor)
    belongs_to(:group, Actor)
  end

  @doc false
  @spec changeset(t | Ecto.Schema.t(), map) :: Ecto.Changeset.t()
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, @attrs)
    |> validate_required(@required_attrs)
    |> stringify_params(:subject_params)
    |> stringify_params(:message_params)
  end

  defp stringify_params(changeset, attr) do
    stringified_params =
      changeset
      |> get_change(attr, %{})
      |> Enum.map(fn {key, value} -> {key, stringify_struct(value)} end)
      |> Map.new()

    put_change(changeset, attr, stringified_params)
  end

  defp stringify_struct(%_{} = struct) do
    association_fields = struct.__struct__.__schema__(:associations)

    struct
    |> Map.from_struct()
    |> Map.drop(association_fields ++ [:__meta__])
  end

  defp stringify_struct(smth), do: smth
end
