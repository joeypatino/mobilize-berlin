defmodule Mobilizon.Service.Workers.ActivityBuilder do
  @moduledoc """
  Worker to insert activity items in users feeds
  """

  alias Mobilizon.{Activities, Actors, Users}
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Service.Notifier
  alias Mobilizon.Users.User

  use Mobilizon.Service.Workers.Helper, queue: "activity"

  @impl Oban.Worker
  @spec perform(Job.t()) :: {:ok, Activity.t()} | {:error, Ecto.Changeset.t()}
  def perform(%Job{args: args}) do
    {"build_activity", args} = Map.pop(args, "op")

    case build_activity(args) do
      {:ok, %Activity{} = activity} ->
        activity
        |> Activities.preload_activity()
        |> notify_activity()

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @spec build_activity(map()) :: {:ok, Activity.t()} | {:error, Ecto.Changeset.t()}
  def build_activity(args) do
    Activities.create_activity(args)
  end

  @spec notify_activity(Activity.t()) :: :ok
  def notify_activity(%Activity{} = activity) do
    activity
    |> users_to_notify()
    |> Enum.each(&Notifier.notify(&1, activity, single_activity: true))
  end

  @spec users_to_notify(Activity.t()) :: list(User.t())
  defp users_to_notify(%Activity{group: %Actor{type: :Group} = group, author_id: author_id}) do
    group
    |> Actors.list_internal_actors_members_for_group([
      :creator,
      :administrator,
      :moderator,
      :member
    ])
    |> Enum.filter(&(&1.id != author_id))
    |> Enum.map(& &1.user_id)
    |> Enum.filter(& &1)
    |> Enum.uniq()
    |> Enum.map(&Users.get_user_with_activity_settings!/1)
  end

  defp users_to_notify(_), do: []
end
