defmodule Mobilizon.GraphQL.Resolvers.Event.Utils do
  @moduledoc """
  Tools to test permission on events
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Events
  alias Mobilizon.Events.Event
  alias Mobilizon.Federation.ActivityPub.{Permission, Relay}
  import Mobilizon.Service.Guards, only: [is_valid_string: 1]

  @spec can_event_be_updated_by?(Event.t(), Actor.t()) ::
          boolean
  def can_event_be_updated_by?(
        %Event{attributed_to: %Actor{type: :Group}} = event,
        %Actor{} = actor_member
      ) do
    Permission.can_update_group_object?(actor_member, event)
  end

  def can_event_be_updated_by?(
        %Event{} = event,
        %Actor{id: actor_member_id}
      ) do
    Event.can_be_managed_by?(event, actor_member_id)
  end

  @spec can_event_be_deleted_by?(Event.t(), Actor.t()) ::
          boolean
  def can_event_be_deleted_by?(
        %Event{attributed_to: %Actor{type: :Group}, id: event_id, url: event_url} = event,
        %Actor{} = actor_member
      )
      when is_valid_string(event_id) and is_valid_string(event_url) do
    Permission.can_delete_group_object?(actor_member, event)
  end

  def can_event_be_deleted_by?(%Event{} = event, %Actor{id: actor_member_id}) do
    Event.can_be_managed_by?(event, actor_member_id)
  end

  @spec check_event_access?(Event.t()) :: boolean()
  def check_event_access?(%Event{local: true}), do: true

  def check_event_access?(%Event{url: url}) do
    relay_actor = Relay.get_actor()
    Events.check_if_event_has_instance_follow(url, relay_actor.id)
  end
end
