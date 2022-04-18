defmodule Mobilizon.Activities do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false
  import EctoEnum
  alias Mobilizon.Activities.Activity
  alias Mobilizon.Actors.Member
  alias Mobilizon.Storage.{Page, Repo}

  defenum(Priority,
    very_low: 10,
    low: 20,
    medium: 30,
    high: 40,
    very_high: 50
  )

  @activity_types ["event", "post", "discussion", "resource", "group", "member", "comment"]
  @event_activity_subjects ["event_created", "event_updated", "event_deleted", "comment_posted"]
  @post_activity_subjects ["post_created", "post_updated", "post_deleted"]
  @discussion_activity_subjects [
    "discussion_created",
    "discussion_replied",
    "discussion_renamed",
    "discussion_archived",
    "discussion_deleted"
  ]
  @resource_activity_subjects [
    "resource_created",
    "resource_renamed",
    "resource_moved",
    "resource_deleted"
  ]
  @member_activity_subjects [
    "member_request",
    "member_invited",
    "member_accepted_invitation",
    "member_rejected_invitation",
    "member_added",
    "member_joined",
    "member_approved",
    "member_updated",
    "member_removed",
    "member_quit"
  ]
  @settings_activity_subjects ["group_created", "group_updated"]

  @subjects @event_activity_subjects ++
              @post_activity_subjects ++
              @discussion_activity_subjects ++
              @resource_activity_subjects ++
              @member_activity_subjects ++ @settings_activity_subjects

  @object_type ["event", "actor", "post", "discussion", "resource", "member", "group", "comment"]

  defenum(Type, @activity_types)
  defenum(Subject, @subjects)
  defenum(ObjectType, @object_type)

  @activity_preloads [:author, :group]

  @doc """
  Returns the list of activities.

  ## Examples

      iex> list_activities()
      [%Activity{}, ...]

  """
  @spec list_activities :: list(Activity.t())
  def list_activities do
    Repo.all(Activity)
  end

  @spec list_group_activities_for_member(
          integer() | String.t(),
          integer() | String.t(),
          Keyword.t(),
          integer() | nil,
          integer() | nil
        ) :: Page.t(Activity.t())
  def list_group_activities_for_member(
        group_id,
        actor_asking_id,
        filters \\ [],
        page \\ nil,
        limit \\ nil
      ) do
    Activity
    |> where([a], a.group_id == ^group_id)
    |> join(:inner, [a], m in Member,
      on: m.parent_id == a.group_id and m.actor_id == ^actor_asking_id
    )
    |> where([a, m], a.inserted_at >= m.member_since)
    |> filter_object_type(Keyword.get(filters, :type))
    |> filter_author(Keyword.get(filters, :author), actor_asking_id)
    |> order_by(desc: :inserted_at)
    |> preload([:author, :group])
    |> Page.build_page(page, limit)
  end

  @spec list_group_activities(
          integer() | String.t(),
          Keyword.t(),
          integer() | nil,
          integer() | nil
        ) :: Page.t(Activity.t())
  def list_group_activities(
        group_id,
        filters \\ [],
        page \\ nil,
        limit \\ nil
      ) do
    Activity
    |> where([a], a.group_id == ^group_id)
    |> filter_object_type(Keyword.get(filters, :type))
    |> order_by(desc: :inserted_at)
    |> preload([:author, :group])
    |> Page.build_page(page, limit)
  end

  @spec list_group_activities_for_recap(
          integer() | String.t(),
          integer() | String.t(),
          DateTime.t() | nil
        ) :: [Activity.t()]
  def list_group_activities_for_recap(
        group_id,
        actor_asking_id,
        last_sent_at \\ nil
      ) do
    query =
      Activity
      |> where([a], a.group_id == ^group_id)
      |> join(:inner, [a], m in Member,
        on: m.parent_id == a.group_id and m.actor_id == ^actor_asking_id
      )
      |> where([a, m], a.inserted_at >= m.member_since)
      |> order_by(desc: :inserted_at)
      |> preload([:author, :group])

    query =
      if is_nil(last_sent_at), do: query, else: where(query, [a], a.inserted_at >= ^last_sent_at)

    Repo.all(query)
  end

  @doc """
  Gets a single activity.

  Raises `Ecto.NoResultsError` if the Activity does not exist.

  ## Examples

      iex> get_activity!(123)
      %Activity{}

      iex> get_activity!(456)
      ** (Ecto.NoResultsError)

  """
  @spec get_activity!(integer()) :: Activity.t()
  def get_activity!(id), do: Repo.get!(Activity, id)

  @doc """
  Creates a activity.

  ## Examples

      iex> create_activity(%{field: value})
      {:ok, %Activity{}}

      iex> create_activity(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_activity(map()) :: {:ok, Activity.t()} | {:error, Ecto.Changeset.t()}
  def create_activity(attrs \\ %{}) do
    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert()
  end

  @spec preload_activity(Activity.t()) :: Activity.t()
  def preload_activity(%Activity{} = activity) do
    Repo.preload(activity, @activity_preloads)
  end

  @spec activity_types :: list(String.t())
  def activity_types, do: @activity_types

  @spec filter_object_type(Query.t(), atom() | nil) :: Query.t()
  defp filter_object_type(query, nil), do: query

  defp filter_object_type(query, type) do
    where(query, [q], q.type == ^type)
  end

  @spec filter_author(Query.t(), atom() | nil, integer() | String.t()) :: Query.t()
  defp filter_author(query, nil, _), do: query

  defp filter_author(query, :self, actor_asking_id) do
    where(query, [q], q.author_id == ^actor_asking_id)
  end

  defp filter_author(query, :by, actor_asking_id) do
    where(query, [q], q.author_id != ^actor_asking_id)
  end
end
