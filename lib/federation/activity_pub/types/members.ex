defmodule Mobilizon.Federation.ActivityPub.Types.Members do
  @moduledoc false
  alias Mobilizon.Actors
  alias Mobilizon.Actors.{Actor, Member}
  alias Mobilizon.Federation.ActivityPub.Actions
  alias Mobilizon.Federation.ActivityStream
  alias Mobilizon.Federation.ActivityStream.Convertible
  alias Mobilizon.Service.Activity.Member, as: MemberActivity
  alias Mobilizon.Web.Endpoint
  require Logger
  import Mobilizon.Federation.ActivityPub.Utils, only: [make_update_data: 2]

  @spec update(Member.t(), map, map) ::
          {:ok, Member.t(), ActivityStream.t()}
          | {:error, :member_not_found | :only_admin_left | Ecto.Changeset.t()}
  def update(
        %Member{
          parent: %Actor{id: group_id} = group,
          id: member_id,
          role: current_role,
          actor: %Actor{id: actor_id} = actor
        } = old_member,
        %{role: updated_role} = args,
        %{moderator: %Actor{url: moderator_url, id: moderator_id} = moderator} = additional
      ) do
    additional = Map.delete(additional, :moderator)

    case Actors.get_member(moderator_id, group_id) do
      {:error, :member_not_found} ->
        {:error, :member_not_found}

      {:ok, %Member{role: moderator_role}}
      when moderator_role in [:moderator, :administrator, :creator] ->
        if check_admins_left?(member_id, group_id, current_role, updated_role) do
          {:error, :only_admin_left}
        else
          case Actors.update_member(old_member, args) do
            {:error, %Ecto.Changeset{} = err} ->
              {:error, err}

            {:ok, %Member{} = member} ->
              MemberActivity.insert_activity(member,
                old_member: old_member,
                moderator: moderator,
                subject: "member_updated"
              )

              Absinthe.Subscription.publish(Endpoint, actor,
                group_membership_changed: [Actor.preferred_username_and_domain(group), actor_id]
              )

              Cachex.del(:activity_pub, "member_#{member_id}")
              member_as_data = Convertible.model_to_as(member)

              audience = %{
                "to" => [member.parent.members_url, member.actor.url],
                "cc" => [member.parent.url],
                "actor" => moderator_url,
                "attributedTo" => [member.parent.url]
              }

              update_data = make_update_data(member_as_data, Map.merge(audience, additional))
              {:ok, member, update_data}
          end
        end
    end
  end

  # Used only when a group is suspended
  @spec delete(Member.t(), Actor.t(), boolean(), map()) :: {:ok, Activity.t(), Member.t()}
  def delete(
        %Member{parent: %Actor{} = group, actor: %Actor{} = actor} = _member,
        %Actor{},
        local,
        _additionnal
      ) do
    Logger.debug("Deleting a member")
    Actions.Leave.leave(group, actor, local, %{force_member_removal: true})
  end

  @spec actor(Member.t()) :: Actor.t() | nil
  def actor(%Member{actor_id: actor_id}),
    do: Actors.get_actor(actor_id)

  @spec group_actor(Member.t()) :: Actor.t() | nil
  def group_actor(%Member{parent_id: parent_id}),
    do: Actors.get_actor(parent_id)

  @spec check_admins_left?(
          String.t() | integer,
          String.t() | integer,
          atom(),
          atom()
        ) :: boolean
  defp check_admins_left?(member_id, group_id, current_role, updated_role) do
    Actors.is_only_administrator?(member_id, group_id) && current_role == :administrator &&
      updated_role != :administrator
  end
end
