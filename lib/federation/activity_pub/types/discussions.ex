defmodule Mobilizon.Federation.ActivityPub.Types.Discussions do
  @moduledoc false

  alias Mobilizon.{Actors, Discussions}
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.{Comment, Discussion}
  alias Mobilizon.Federation.ActivityPub.{Audience, Permission}
  alias Mobilizon.Federation.ActivityPub.Types.Entity
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.GraphQL.API.Utils, as: APIUtils
  alias Mobilizon.Service.Activity.Discussion, as: DiscussionActivity
  alias Mobilizon.Web.Endpoint
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_create_data: 2, make_update_data: 2]
  require Logger

  @behaviour Entity

  @impl Entity
  @spec create(map(), map()) ::
          {:ok, Discussion.t(), ActivityStream.t()}
          | {:error, :discussion_not_found | :last_comment_not_found | Ecto.Changeset.t()}
  def create(%{discussion_id: discussion_id} = args, additional) when not is_nil(discussion_id) do
    args = prepare_args(args)

    case Discussions.get_discussion(discussion_id) do
      %Discussion{} = discussion ->
        case Discussions.reply_to_discussion(discussion, args) do
          {:ok, %Discussion{last_comment_id: last_comment_id} = discussion} ->
            DiscussionActivity.insert_activity(discussion,
              subject: "discussion_replied",
              actor_id: Map.get(args, :creator_id, args.actor_id)
            )

            case Discussions.get_comment_with_preload(last_comment_id) do
              %Comment{} = last_comment ->
                maybe_publish_graphql_subscription(discussion)
                comment_as_data = Convertible.model_to_as(last_comment)
                audience = Audience.get_audience(discussion)
                create_data = make_create_data(comment_as_data, Map.merge(audience, additional))
                {:ok, discussion, create_data}

              nil ->
                {:error, :last_comment_not_found}
            end

          {:error, _, %Ecto.Changeset{} = err, _} ->
            {:error, err}
        end

      nil ->
        {:error, :discussion_not_found}
    end
  end

  @impl Entity
  def create(args, additional) do
    args = prepare_args(args)

    case Discussions.create_discussion(args) do
      {:ok, %Discussion{} = discussion} ->
        DiscussionActivity.insert_activity(discussion, subject: "discussion_created")
        discussion_as_data = Convertible.model_to_as(discussion)
        audience = Audience.get_audience(discussion)
        create_data = make_create_data(discussion_as_data, Map.merge(audience, additional))
        {:ok, discussion, create_data}

      {:error, _, %Ecto.Changeset{} = err, _} ->
        {:error, err}
    end
  end

  @impl Entity
  @spec update(Discussion.t(), map(), map()) ::
          {:ok, Discussion.t(), ActivityStream.t()} | {:error, Ecto.Changeset.t()}
  def update(%Discussion{} = old_discussion, args, additional) do
    case Discussions.update_discussion(old_discussion, args) do
      {:ok, %Discussion{} = new_discussion} ->
        DiscussionActivity.insert_activity(new_discussion,
          subject: "discussion_renamed",
          old_discussion: old_discussion
        )

        Cachex.del(:activity_pub, "discussion_#{new_discussion.slug}")
        discussion_as_data = Convertible.model_to_as(new_discussion)
        audience = Audience.get_audience(new_discussion)
        update_data = make_update_data(discussion_as_data, Map.merge(audience, additional))
        {:ok, new_discussion, update_data}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @impl Entity
  @spec delete(Discussion.t(), Actor.t(), boolean, map()) ::
          {:error, Ecto.Changeset.t()} | {:ok, ActivityStream.t(), Actor.t(), Discussion.t()}
  def delete(
        %Discussion{actor: group, url: url} = discussion,
        %Actor{} = actor,
        _local,
        _additionnal
      ) do
    case Discussions.delete_discussion(discussion) do
      {:error, _, %Ecto.Changeset{} = err, _} ->
        {:error, err}

      {:ok, %{comments: {_, _}}} ->
        DiscussionActivity.insert_activity(discussion,
          subject: "discussion_deleted",
          moderator: actor
        )

        # This is just fake
        activity_data = %{
          "type" => "Delete",
          "actor" => actor.url,
          "object" => %{
            "type" => "Tombstone",
            "url" => url
          },
          "id" => url <> "/delete",
          "to" => [group.members_url]
        }

        {:ok, activity_data, actor, discussion}
    end
  end

  @spec actor(Discussion.t()) :: Actor.t() | nil
  def actor(%Discussion{creator_id: creator_id}), do: Actors.get_actor(creator_id)

  @spec group_actor(Discussion.t()) :: Actor.t() | nil
  def group_actor(%Discussion{actor_id: actor_id}), do: Actors.get_actor(actor_id)

  @spec permissions(Discussion.t()) :: Permission.t()
  def permissions(%Discussion{}) do
    %Permission{access: :member, create: :member, update: :moderator, delete: :moderator}
  end

  @spec maybe_publish_graphql_subscription(Discussion.t()) :: :ok
  defp maybe_publish_graphql_subscription(%Discussion{} = discussion) do
    Absinthe.Subscription.publish(Endpoint, discussion,
      discussion_comment_changed: discussion.slug
    )

    :ok
  end

  @spec prepare_args(map) :: map
  defp prepare_args(args) do
    {text, _mentions, _tags} =
      APIUtils.make_content_html(
        args |> Map.get(:text, "") |> String.trim(),
        # Can't put additional tags on a comment
        [],
        "text/html"
      )

    args
    # title might be nil
    |> Map.update(:title, "", fn title -> String.trim(title || "") end)
    |> Map.put(:text, text)
  end
end
