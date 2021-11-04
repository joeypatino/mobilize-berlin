defmodule Mobilizon.Actors do
  @moduledoc """
  The Actors context.
  """

  import Ecto.Query
  import EctoEnum
  import Geo.PostGIS, only: [st_dwithin_in_meters: 3]
  import Mobilizon.Service.Guards

  alias Ecto.Multi

  alias Mobilizon.Actors.{Actor, Bot, Follower, Member}
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Crypto
  alias Mobilizon.Events.FeedToken
  alias Mobilizon.Service.Workers
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users
  alias Mobilizon.Users.User
  alias Mobilizon.Web.Upload

  require Logger

  defenum(ActorType, :actor_type, [
    :Person,
    :Application,
    :Group,
    :Organization,
    :Service
  ])

  defenum(ActorOpenness, :actor_openness, [
    :invite_only,
    :moderated,
    :open
  ])

  defenum(ActorVisibility, :actor_visibility, [
    :public,
    :unlisted,
    # Probably unused
    :restricted,
    :private
  ])

  defenum(MemberRole, :member_role, [
    :invited,
    :not_approved,
    :member,
    :moderator,
    :administrator,
    :creator,
    :rejected
  ])

  @administrator_roles [:creator, :administrator]
  @moderator_roles [:moderator] ++ @administrator_roles
  @member_roles [:member] ++ @moderator_roles

  @doc """
  Gets a single actor.
  """
  @spec get_actor(integer | String.t()) :: Actor.t() | nil
  def get_actor(nil), do: nil
  def get_actor(id), do: Repo.get(Actor, id)

  @doc """
  Gets a single actor.
  Raises `Ecto.NoResultsError` if the actor does not exist.
  """
  @spec get_actor!(integer | String.t()) :: Actor.t()
  def get_actor!(id), do: Repo.get!(Actor, id)

  @doc """
  Gets an actor with preloaded relations.
  """
  @spec get_actor_with_preload(integer | String.t(), boolean) :: Actor.t() | nil
  def get_actor_with_preload(id, include_suspended \\ false) do
    id
    |> actor_with_preload_query(include_suspended)
    |> Repo.one()
  end

  @spec get_actor_with_preload!(integer | String.t()) :: Actor.t()
  def get_actor_with_preload!(id) do
    id
    |> actor_with_preload_query(false)
    |> Repo.one!()
  end

  @doc """
  Gets a local actor with preloaded relations.
  """
  @spec get_local_actor_with_preload(integer | String.t()) :: Actor.t() | nil
  def get_local_actor_with_preload(id) do
    id
    |> actor_with_preload_query()
    |> filter_local()
    |> Repo.one()
  end

  @doc """
  Gets an actor by its URL (ActivityPub ID). The `:preload` option allows to
  preload the followers relation.
  """
  @spec get_actor_by_url(String.t(), boolean) ::
          {:ok, Actor.t()} | {:error, :actor_not_found}
  def get_actor_by_url(url, preload \\ false)
  def get_actor_by_url(nil, _preload), do: {:error, :actor_not_found}

  def get_actor_by_url(url, preload) do
    case Repo.get_by(Actor, url: url) do
      nil ->
        {:error, :actor_not_found}

      actor ->
        {:ok, preload_followers(actor, preload)}
    end
  end

  @doc """
  New function to replace `Mobilizon.Actors.get_actor_by_url/1` with
  better signature
  """
  @spec get_actor_by_url_2(String.t()) :: Actor.t() | nil
  def get_actor_by_url_2(url) do
    Repo.get_by(Actor, url: url)
  end

  @doc """
  Gets an actor by its URL (ActivityPub ID). The `:preload` option allows to
  preload the followers relation.
  Raises `Ecto.NoResultsError` if the actor does not exist.
  """
  @spec get_actor_by_url!(String.t(), boolean) :: Actor.t()
  def get_actor_by_url!(url, preload \\ false) do
    Actor
    |> Repo.get_by!(url: url)
    |> preload_followers(preload)
  end

  @doc """
  Gets an actor by name.
  """
  @spec get_actor_by_name(String.t(), ActorType.t() | nil) :: Actor.t() | nil
  def get_actor_by_name(name, type \\ nil) do
    Actor
    |> filter_by_type(type)
    |> filter_by_name(name |> String.trim() |> String.trim_leading("@") |> String.split("@"))
    |> Repo.one()
  end

  @doc """
  Gets a local actor by its preferred username.
  """
  @spec get_local_actor_by_name(String.t()) :: Actor.t() | nil
  def get_local_actor_by_name(name) do
    Actor
    |> filter_by_name([name])
    |> Repo.one()
  end

  @doc """
  Gets a local actor by its preferred username and preloaded relations
  (organized events, followers and followings).
  """
  @spec get_local_actor_by_name_with_preload(String.t()) :: Actor.t() | nil
  def get_local_actor_by_name_with_preload(name) do
    name
    |> get_local_actor_by_name()
    |> Repo.preload([:organized_events, :followers, :followings])
  end

  @doc """
  Gets an actor by name and preloads the organized events.
  """
  @spec get_actor_by_name_with_preload(String.t(), atom() | nil) :: Actor.t() | nil
  def get_actor_by_name_with_preload(name, type \\ nil) do
    name
    |> get_actor_by_name(type)
    |> Repo.preload([:organized_events, :user, :physical_address])
  end

  @doc """
  Creates an actor.
  """
  @spec create_actor(map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def create_actor(attrs \\ %{}) do
    type = Map.get(attrs, :type, :Person)

    case type do
      :Person ->
        %Actor{}
        |> Actor.changeset(attrs)
        |> Repo.insert()

      :Group ->
        create_group(attrs)
    end
  end

  @doc """
  Creates a new person actor.
  """
  @spec new_person(map, default_actor :: boolean()) ::
          {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def new_person(args, default_actor \\ false) do
    args = Map.put(args, :keys, Crypto.generate_rsa_2048_private_key())

    multi =
      Multi.new()
      |> Multi.insert(:person, Actor.registration_changeset(%Actor{}, args))
      |> Multi.insert(:token, fn %{person: person} ->
        FeedToken.changeset(%FeedToken{}, %{
          user_id: args.user_id,
          actor_id: person.id,
          token: Ecto.UUID.generate()
        })
      end)

    multi =
      if default_actor do
        user = Users.get_user!(args.user_id)

        Multi.update(multi, :user, fn %{person: person} ->
          User.changeset(user, %{default_actor_id: person.id})
        end)
      else
        multi
      end

    case Repo.transaction(multi) do
      {:ok, %{person: %Actor{} = person}} ->
        {:ok, person}

      {:error, _step, err, _} ->
        Logger.error("Error while creating a new person")
        {:error, err}
    end
  end

  @doc """
  Updates an actor.
  """
  @spec update_actor(Actor.t(), map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def update_actor(%Actor{} = actor, attrs) do
    actor
    |> Repo.preload([:physical_address])
    |> Actor.update_changeset(attrs)
    |> delete_files_if_media_changed()
    |> Repo.update()
  end

  @doc """
  Upserts an actor.
  Conflicts on actor's URL/AP ID, replaces keys, avatar and banner, name and summary.
  """
  @spec upsert_actor(map, boolean) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def upsert_actor(
        data,
        preload \\ false
      ) do
    # data =
    #   data
    #   |> Map.put(:avatar, transform_media_file(data.avatar))
    #   |> Map.put(:banner, transform_media_file(data.banner))

    insert =
      data
      |> Actor.remote_actor_creation_changeset()
      |> Repo.insert(
        on_conflict: {:replace_all_except, [:id, :url, :preferred_username, :domain]},
        conflict_target: [:url]
      )

    case insert do
      {:ok, actor} ->
        actor = if preload, do: Repo.preload(actor, [:followers]), else: actor

        {:ok, actor}

      error ->
        Logger.debug(inspect(error))

        {:error, error}
    end
  end

  @delete_actor_default_options [reserve_username: true, suspension: false]

  @spec delete_actor(Actor.t(), Keyword.t()) :: {:error, Ecto.Changeset.t()} | {:ok, Oban.Job.t()}
  def delete_actor(%Actor{} = actor, options \\ @delete_actor_default_options) do
    delete_actor_options = Keyword.merge(@delete_actor_default_options, options)

    Workers.Background.enqueue("delete_actor", %{
      "actor_id" => actor.id,
      "author_id" => Keyword.get(delete_actor_options, :author_id),
      "reserve_username" => Keyword.get(delete_actor_options, :reserve_username, true),
      "suspension" => Keyword.get(delete_actor_options, :suspension, false)
    })
  end

  @spec actor_key_rotation(Actor.t()) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def actor_key_rotation(%Actor{} = actor) do
    actor
    |> Actor.changeset(%{keys: Crypto.generate_rsa_2048_private_key()})
    |> Repo.update()
  end

  @doc """
  Returns the list of actors.
  """
  @spec list_actors(
          atom(),
          String.t(),
          String.t(),
          String.t(),
          boolean,
          boolean,
          integer | nil,
          integer | nil
        ) :: Page.t()
  def list_actors(
        type \\ :Person,
        preferred_username \\ "",
        name \\ "",
        domain \\ "",
        local \\ true,
        suspended \\ false,
        page \\ nil,
        limit \\ nil
      )

  def list_actors(
        :Person,
        preferred_username,
        name,
        domain,
        local,
        suspended,
        page,
        limit
      ) do
    person_query()
    |> filter_actors(preferred_username, name, domain, local, suspended)
    |> Page.build_page(page, limit)
  end

  def list_actors(
        :Group,
        preferred_username,
        name,
        domain,
        local,
        suspended,
        page,
        limit
      ) do
    group_query()
    |> filter_actors(preferred_username, name, domain, local, suspended)
    |> Page.build_page(page, limit)
  end

  @spec list_suspended_actors_to_purge(Keyword.t()) :: list(Actors.t())
  def list_suspended_actors_to_purge(options) do
    suspension_days = Keyword.get(options, :suspension, 30)

    Actor
    |> filter_suspended_days(suspension_days)
    |> Repo.all()
  end

  @spec filter_actors(
          Ecto.Queryable.t(),
          String.t(),
          String.t(),
          String.t(),
          boolean(),
          boolean()
        ) ::
          Ecto.Query.t()
  defp filter_actors(
         query,
         preferred_username,
         name,
         domain,
         local,
         suspended
       ) do
    query
    |> filter_suspended(suspended)
    |> filter_preferred_username(preferred_username)
    |> filter_name(name)
    |> filter_domain(domain)
    |> filter_remote(local)
  end

  defp filter_preferred_username(query, ""), do: query

  defp filter_preferred_username(query, preferred_username),
    do: where(query, [a], ilike(a.preferred_username, ^"%#{preferred_username}%"))

  defp filter_name(query, ""), do: query

  defp filter_name(query, name),
    do: where(query, [a], ilike(a.name, ^"%#{name}%"))

  defp filter_domain(query, ""), do: query

  defp filter_domain(query, domain),
    do: where(query, [a], ilike(a.domain, ^"%#{domain}%"))

  defp filter_remote(query, true), do: filter_local(query)
  defp filter_remote(query, false), do: filter_external(query)

  @spec filter_suspended(Ecto.Queryable.t(), boolean()) :: Ecto.Query.t()
  defp filter_suspended(query, true), do: where(query, [a], a.suspended)
  defp filter_suspended(query, false), do: where(query, [a], not a.suspended)

  @spec filter_out_anonymous_actor_id(Ecto.Queryable.t(), integer() | String.t()) ::
          Ecto.Query.t()
  defp filter_out_anonymous_actor_id(query, anonymous_actor_id),
    do: where(query, [a], a.id != ^anonymous_actor_id)

  @spec filter_suspended_days(Ecto.Queryable.t(), integer()) :: Ecto.Query.t()
  defp filter_suspended_days(query, suspended_days) do
    expiration_date = DateTime.add(DateTime.utc_now(), suspended_days * 24 * -3600)

    where(
      query,
      [a],
      a.suspended and
        a.updated_at > ^expiration_date
    )
  end

  @doc """
  Returns the list of local actors by their username.
  """
  @spec list_local_actor_by_username(String.t()) :: [Actor.t()]
  def list_local_actor_by_username(username) do
    username
    |> actor_by_username_query()
    |> filter_local()
    |> Repo.all()
    |> Repo.preload(:organized_events)
  end

  @doc """
  Builds a page struct for actors by their name or displayed name.
  """
  @spec build_actors_by_username_or_name_page(
          String.t(),
          Keyword.t(),
          integer | nil,
          integer | nil
        ) :: Page.t()
  def build_actors_by_username_or_name_page(
        term,
        options \\ [],
        page \\ nil,
        limit \\ nil
      ) do
    anonymous_actor_id = Mobilizon.Config.anonymous_actor_id()
    query = from(a in Actor)

    query
    |> actor_by_username_or_name_query(term)
    |> actors_for_location(Keyword.get(options, :location), Keyword.get(options, :radius))
    |> filter_by_types(Keyword.get(options, :actor_type, :Group))
    |> filter_by_minimum_visibility(Keyword.get(options, :minimum_visibility, :public))
    |> filter_suspended(false)
    |> filter_out_anonymous_actor_id(anonymous_actor_id)
    |> Page.build_page(page, limit)
  end

  @doc """
  Gets a group by its title.
  """
  @spec get_group_by_title(String.t()) :: Actor.t() | nil
  def get_group_by_title(title) do
    group_query()
    |> filter_by_name(String.split(title, "@"))
    |> Repo.one()
  end

  @doc """
  Gets a group by its actor id.
  """
  @spec get_group_by_actor_id(integer | String.t()) ::
          {:ok, Actor.t()} | {:error, :group_not_found}
  def get_group_by_actor_id(actor_id) do
    case Repo.get_by(Actor, id: actor_id, type: :Group) do
      nil ->
        {:error, :group_not_found}

      actor ->
        {:ok, actor}
    end
  end

  @spec get_local_group_by_url(String.t()) :: Actor.t() | nil
  def get_local_group_by_url(group_url) do
    group_query()
    |> where([q], q.url == ^group_url and is_nil(q.domain))
    |> Repo.one()
  end

  @spec get_group_by_members_url(String.t()) :: Actor.t() | nil
  def get_group_by_members_url(members_url) do
    group_query()
    |> where([q], q.members_url == ^members_url)
    |> Repo.one()
  end

  @spec get_actor_by_followers_url(String.t()) :: Actor.t() | nil
  def get_actor_by_followers_url(followers_url) do
    Actor
    |> where([q], q.followers_url == ^followers_url)
    |> Repo.one()
  end

  @doc """
  Creates a group.

  If the group is local, creates an admin actor as well from `creator_actor_id`.
  """
  @spec create_group(map) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def create_group(attrs \\ %{}) do
    if Map.get(attrs, :local, true) do
      multi =
        Multi.new()
        |> Multi.insert(:insert_group, Actor.group_creation_changeset(%Actor{}, attrs))
        |> Multi.insert(:add_admin_member, fn %{insert_group: group} ->
          Member.changeset(%Member{}, %{
            parent_id: group.id,
            actor_id: attrs.creator_actor_id,
            role: :administrator
          })
        end)
        |> Repo.transaction()

      case multi do
        {:ok, %{insert_group: %Actor{} = group, add_admin_member: %Member{} = _admin_member}} ->
          {:ok, group}

        {:error, _err, %Ecto.Changeset{} = err, _} ->
          {:error, err}
      end
    else
      %Actor{}
      |> Actor.group_creation_changeset(attrs)
      |> Repo.insert()
    end
  end

  @doc """
  Counts the local groups
  """
  @spec count_local_groups :: integer()
  def count_local_groups do
    groups_query()
    |> filter_local()
    |> Repo.aggregate(:count)
  end

  @doc """
  Counts all the groups
  """
  @spec count_groups :: integer()
  def count_groups do
    groups_query()
    |> Repo.aggregate(:count)
  end

  @doc """
  Lists the groups.
  """
  @spec list_groups_for_stream :: Enum.t()
  def list_groups_for_stream do
    groups_query()
    |> Repo.stream()
  end

  @doc """
  Lists the groups.
  """
  @spec list_external_groups :: list(Actor.t())
  def list_external_groups do
    external_groups_query()
    |> limit(100)
    |> Repo.all()
  end

  @doc """
  Returns the list of groups an actor is member of.
  """
  @spec list_groups_member_of(Actor.t()) :: [Actor.t()]
  def list_groups_member_of(%Actor{id: actor_id}) do
    actor_id
    |> groups_member_of_query()
    |> Repo.all()
  end

  @doc """
  Gets a single member.
  """
  @spec get_member(integer | String.t()) :: Member.t() | nil
  def get_member(id) do
    Member
    |> Repo.get(id)
    |> Repo.preload([:actor, :parent, :invited_by])
  end

  @doc """
  Gets a single member.
  Raises `Ecto.NoResultsError` if the member does not exist.
  """
  @spec get_member!(integer | String.t()) :: Member.t()
  def get_member!(id), do: Repo.get!(Member, id)

  @doc """
  Gets a single member of an actor (for example a group).
  """
  @spec get_member(actor_id :: integer | String.t(), parent_id :: integer | String.t()) ::
          {:ok, Member.t()} | {:error, :member_not_found}
  def get_member(actor_id, parent_id) do
    case Repo.get_by(Member, actor_id: actor_id, parent_id: parent_id) do
      nil ->
        {:error, :member_not_found}

      member ->
        {:ok, member}
    end
  end

  @spec get_member(integer | String.t(), integer | String.t(), list()) ::
          {:ok, Member.t()} | {:error, :member_not_found}
  def get_member(actor_id, parent_id, roles) do
    case Member
         |> where([m], m.actor_id == ^actor_id and m.parent_id == ^parent_id and m.role in ^roles)
         |> Repo.one() do
      nil ->
        {:error, :member_not_found}

      member ->
        {:ok, member}
    end
  end

  @doc """
  Returns whether the `actor_id` is a confirmed member for the group `parent_id`
  """
  @spec is_member?(integer | String.t(), integer | String.t()) :: boolean()
  def is_member?(actor_id, parent_id) do
    match?(
      {:ok, %Member{}},
      get_member(actor_id, parent_id, @member_roles)
    )
  end

  @doc """
  Returns whether the `actor_id` is a moderator for the group `parent_id`
  """
  @spec is_moderator?(integer | String.t(), integer | String.t()) :: boolean()
  def is_moderator?(actor_id, parent_id) do
    match?(
      {:ok, %Member{}},
      get_member(actor_id, parent_id, @moderator_roles)
    )
  end

  @doc """
  Returns whether the `actor_id` is an administrator for the group `parent_id`
  """
  @spec is_administrator?(integer | String.t(), integer | String.t()) :: boolean()
  def is_administrator?(actor_id, parent_id) do
    match?(
      {:ok, %Member{}},
      get_member(actor_id, parent_id, @administrator_roles)
    )
  end

  @doc """
  Gets the default member role depending on the event join options.
  """
  @spec get_default_member_role(Actor.t()) :: :member | :not_approved
  def get_default_member_role(%Actor{openness: :open}), do: :member
  def get_default_member_role(%Actor{openness: _}), do: :not_approved

  @doc """
  Gets a single member of an actor (for example a group).
  """
  @spec get_member_by_url(String.t()) :: Member.t() | nil
  def get_member_by_url(url) do
    Member
    |> where(url: ^url)
    |> preload([:actor, :parent, :invited_by])
    |> Repo.one()
  end

  @spec get_single_group_member_actor(integer() | String.t()) :: Actor.t() | nil
  def get_single_group_member_actor(group_id) do
    do_get_single_group_member_actor(group_id, [:member, :moderator, :administrator, :creator])
  end

  @spec get_single_group_moderator_actor(integer() | String.t()) :: Actor.t() | nil
  def get_single_group_moderator_actor(group_id) do
    do_get_single_group_member_actor(group_id, [:moderator, :administrator, :creator])
  end

  @spec do_get_single_group_member_actor(integer() | String.t(), list(atom())) :: Actor.t() | nil
  defp do_get_single_group_member_actor(group_id, roles) do
    Member
    |> where([m], m.parent_id == ^group_id and m.role in ^roles)
    |> join(:inner, [m], a in Actor, on: m.actor_id == a.id)
    |> where([_m, a], is_nil(a.domain))
    |> limit(1)
    |> select([_m, a], a)
    |> Repo.one()
  end

  @doc """
  Creates a member.
  """
  @spec create_member(map) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def create_member(attrs \\ %{}) do
    case %Member{}
         |> Member.changeset(attrs)
         |> Repo.insert(
           on_conflict: {:replace_all_except, [:id, :url, :actor_id, :parent_id]},
           conflict_target: [:actor_id, :parent_id],
           # See https://hexdocs.pm/ecto/Ecto.Repo.html#c:insert/2-upserts,
           # when doing an upsert with on_conflict, PG doesn't return whether it's an insert or upsert
           # so we need to refresh the fields
           returning: true
         ) do
      {:ok, %Member{} = member} ->
        {:ok, Repo.preload(member, [:actor, :parent, :invited_by])}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @doc """
  Updates a member.
  """
  @spec update_member(Member.t(), map) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def update_member(%Member{} = member, attrs) do
    member
    |> Member.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a member.
  """
  @spec delete_member(Member.t()) :: {:ok, Member.t()} | {:error, Ecto.Changeset.t()}
  def delete_member(%Member{} = member), do: Repo.delete(member)

  @doc """
  Returns the list of memberships for an user.

  Default behaviour is to not return :not_approved memberships

  ## Examples

      iex> list_event_participations_for_user(5)
      %Page{total: 3, elements: [%Participant{}, ...]}

  """
  @spec list_memberships_for_user(
          integer,
          integer | nil,
          integer | nil
        ) :: Page.t()
  def list_memberships_for_user(user_id, page, limit) do
    user_id
    |> list_members_for_user_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of members for an actor.
  """
  @spec list_members_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t(Member.t())
  def list_members_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> members_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @spec list_all_local_members_for_group(Actor.t()) :: list(Member.t())
  def list_all_local_members_for_group(%Actor{id: group_id, type: :Group} = _group) do
    group_id
    |> group_internal_member_query()
    |> Repo.all()
  end

  @doc """
  Returns a paginated list of members for a group.
  """
  @spec list_members_for_group(Actor.t(), list(atom()), integer | nil, integer | nil) ::
          Page.t(Member.t())
  def list_members_for_group(
        %Actor{id: group_id, type: :Group},
        roles \\ [],
        page \\ nil,
        limit \\ nil
      ) do
    group_id
    |> members_for_group_query()
    |> filter_member_role(roles)
    |> Page.build_page(page, limit)
  end

  @spec list_external_actors_members_for_group(Actor.t()) :: list(Actor.t())
  def list_external_actors_members_for_group(%Actor{id: group_id, type: :Group}) do
    group_id
    |> group_external_member_actor_query()
    |> Repo.all()
  end

  @spec list_internal_actors_members_for_group(Actor.t(), list()) :: list(Actor.t())
  def list_internal_actors_members_for_group(%Actor{id: group_id, type: :Group}, roles \\ []) do
    group_id
    |> group_internal_member_actor_query(roles)
    |> Repo.all()
  end

  @doc """
  Returns the complete list of administrator members for a group.
  """
  @spec list_all_administrator_members_for_group(integer | String.t()) :: [Member.t()]
  def list_all_administrator_members_for_group(id) do
    id
    |> administrator_members_for_group_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of all group ids where the actor_id is the last administrator.
  """
  @spec list_group_ids_where_last_administrator(integer | String.t()) :: [integer]
  def list_group_ids_where_last_administrator(actor_id) do
    actor_id
    |> group_ids_where_last_administrator_query()
    |> Repo.all()
  end

  @doc """
  Returns whether the member is the last administrator for a group
  """
  @spec is_only_administrator?(integer | String.t(), integer | String.t()) :: boolean()
  def is_only_administrator?(member_id, group_id) do
    Member
    |> where(
      [m],
      m.parent_id == ^group_id and m.id != ^member_id and m.role in ^@administrator_roles
    )
    |> Repo.aggregate(:count)
    |> (&(&1 == 0)).()
  end

  @doc """
  Gets a single bot.
  Raises `Ecto.NoResultsError` if the bot does not exist.
  """
  def get_bot!(id), do: Repo.get!(Bot, id)

  @doc """
  Gets the bot associated to an actor.
  """
  @spec get_bot_for_actor(Actor.t()) :: Bot.t()
  def get_bot_for_actor(%Actor{id: actor_id}) do
    Repo.get_by!(Bot, actor_id: actor_id)
  end

  @doc """
  Creates a bot.
  """
  @spec create_bot(attrs :: map) :: {:ok, Bot.t()} | {:error, Ecto.Changeset.t()}
  def create_bot(attrs \\ %{}) do
    %Bot{}
    |> Bot.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Registers a new bot.
  """
  @spec register_bot(%{name: String.t(), summary: String.t()}) ::
          {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def register_bot(%{name: name, summary: summary}) do
    attrs = %{
      preferred_username: name,
      domain: nil,
      keys: Crypto.generate_rsa_2048_private_key(),
      summary: summary,
      type: :Service
    }

    %Actor{}
    |> Actor.registration_changeset(attrs)
    |> Repo.insert()
  end

  @spec get_or_create_internal_actor(String.t()) ::
          {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_internal_actor(username) do
    case username |> Actor.build_url(:page) |> get_actor_by_url() do
      {:ok, %Actor{} = actor} ->
        {:ok, actor}

      _ ->
        case username do
          "anonymous" ->
            Actor.build_anonymous_actor_creation_attrs()
            |> Repo.insert()

          "relay" ->
            Actor.build_relay_creation_attrs()
            |> Repo.insert()
        end
    end
  end

  @doc """
  Updates a bot.
  """
  @spec update_bot(Bot.t(), map) :: {:ok, Bot.t()} | {:error, Ecto.Changeset.t()}
  def update_bot(%Bot{} = bot, attrs) do
    bot
    |> Bot.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a bot.
  """
  @spec delete_bot(Bot.t()) :: {:ok, Bot.t()} | {:error, Ecto.Changeset.t()}
  def delete_bot(%Bot{} = bot), do: Repo.delete(bot)

  @doc """
  Gets a single follower.
  """
  @spec get_follower(integer | String.t()) :: Follower.t() | nil
  def get_follower(id) do
    Follower
    |> Repo.get(id)
    |> Repo.preload([:actor, :target_actor])
  end

  @doc """
  Gets a single follower.
  Raises `Ecto.NoResultsError` if the follower does not exist.
  """
  @spec get_follower!(integer | String.t()) :: Follower.t()
  def get_follower!(id) do
    Follower
    |> Repo.get!(id)
    |> Repo.preload([:actor, :target_actor])
  end

  @doc """
  Get a follower by the url.
  """
  @spec get_follower_by_url(String.t()) :: Follower.t()
  def get_follower_by_url(url) do
    url
    |> follower_by_url()
    |> Repo.one()
  end

  @doc """
  Gets a follower by the followed actor and following actor
  """
  @spec get_follower_by_followed_and_following(Actor.t(), Actor.t()) :: Follower.t() | nil
  def get_follower_by_followed_and_following(%Actor{id: followed_id}, %Actor{id: following_id}) do
    followed_id
    |> follower_by_followed_and_following_query(following_id)
    |> Repo.one()
  end

  @doc """
  Creates a follower.
  """
  @spec create_follower(attrs :: map) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def create_follower(attrs \\ %{}) do
    case %Follower{}
         |> Follower.changeset(attrs)
         |> Repo.insert() do
      {:ok, %Follower{} = follower} ->
        {:ok, Repo.preload(follower, [:actor, :target_actor])}

      {:error, %Ecto.Changeset{} = err} ->
        {:error, err}
    end
  end

  @doc """
  Updates a follower.
  """
  @spec update_follower(Follower.t(), map) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def update_follower(%Follower{} = follower, attrs) do
    with {:ok, %Follower{} = follower} <-
           follower
           |> Follower.changeset(attrs)
           |> Repo.update() do
      {:ok, Repo.preload(follower, [:actor, :target_actor])}
    end
  end

  @doc """
  Deletes a follower.
  """
  @spec delete_follower(Follower.t()) :: {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def delete_follower(%Follower{} = follower), do: Repo.delete(follower)

  @doc """
  Deletes a follower by followed and following actors.
  """
  @spec delete_follower_by_followed_and_following(Actor.t(), Actor.t()) ::
          {:ok, Follower.t()} | {:error, Ecto.Changeset.t()}
  def delete_follower_by_followed_and_following(%Actor{} = followed, %Actor{} = following) do
    followed
    |> get_follower_by_followed_and_following(following)
    |> Repo.delete()
  end

  @spec list_paginated_follows_for_actor(Actor.t(), integer | nil, integer | nil) ::
          Page.t(Follower.t())
  def list_paginated_follows_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> followings_for_actor_query
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the list of external followers for an actor.
  """
  @spec list_external_followers_for_actor(Actor.t()) :: [Follower.t()]
  def list_external_followers_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> list_external_follower_actors_for_actor_query()
    |> Repo.all()
  end

  @doc """
  Returns the paginated list of external followers for an actor.
  """
  @spec list_external_followers_for_actor_paginated(Actor.t(), integer | nil, integer | nil) ::
          Page.t()
  def list_external_followers_for_actor_paginated(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> list_external_followers_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Build a page struct for followers of an actor.
  """
  @spec build_followers_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def build_followers_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> follower_actors_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the number of followers for an actor
  """
  @spec count_followers_for_actor(Actor.t()) :: integer()
  def count_followers_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> follower_for_actor_query()
    |> where(approved: true)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns a paginated list of followers for an actor.
  """
  @spec list_paginated_followers_for_actor(Actor.t(), boolean | nil, integer | nil, integer | nil) ::
          Page.t()
  def list_paginated_followers_for_actor(
        %Actor{id: actor_id},
        approved \\ nil,
        page \\ nil,
        limit \\ nil
      ) do
    actor_id
    |> follower_for_actor_query()
    |> filter_followed_by_approved_status(approved)
    |> order_by(desc: :updated_at)
    |> preload([:actor, :target_actor])
    |> Page.build_page(page, limit)
  end

  @doc """
  Returns the number of followings for an actor
  """
  @spec count_followings_for_actor(Actor.t()) :: integer()
  def count_followings_for_actor(%Actor{id: actor_id}) do
    actor_id
    |> followings_for_actor_query()
    |> where(approved: true)
    |> Repo.aggregate(:count)
  end

  @doc """
  Returns the list of external followings for an actor.
  """
  @spec list_external_followings_for_actor_paginated(Actor.t(), integer | nil, integer | nil) ::
          Page.t()
  def list_external_followings_for_actor_paginated(
        %Actor{id: actor_id},
        page \\ nil,
        limit \\ nil
      ) do
    actor_id
    |> list_external_followings_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Build a page struct for followings of an actor.
  """
  @spec build_followings_for_actor(Actor.t(), integer | nil, integer | nil) :: Page.t()
  def build_followings_for_actor(%Actor{id: actor_id}, page \\ nil, limit \\ nil) do
    actor_id
    |> followings_actors_for_actor_query()
    |> Page.build_page(page, limit)
  end

  @doc """
  Makes an actor following another actor.
  """
  @spec follow(
          followed :: Actor.t(),
          follower :: Actor.t(),
          url :: String.t() | nil,
          approved :: boolean | nil
        ) ::
          {:ok, Follower.t()}
          | {:error, :already_following | :followed_suspended | Ecto.Changeset.t()}
  def follow(%Actor{} = followed, %Actor{} = follower, url \\ nil, approved \\ true) do
    if followed.suspended do
      {:error, :followed_suspended}
    else
      case is_following(follower, followed) do
        %Follower{} ->
          {:error, :already_following}

        nil ->
          Logger.info(
            "Making #{Actor.preferred_username_and_domain(follower)} follow #{Actor.preferred_username_and_domain(followed)} " <>
              "(approved: #{approved})"
          )

          create_follower(%{
            "actor_id" => follower.id,
            "target_actor_id" => followed.id,
            "approved" => approved,
            "url" => url
          })
      end
    end
  end

  @doc """
  Unfollows an actor (removes a Follower record).
  """
  @spec unfollow(Actor.t(), Actor.t()) ::
          {:ok, Follower.t()} | {:error, Ecto.Changeset.t() | String.t()}
  def unfollow(%Actor{} = followed, %Actor{} = follower) do
    case {:already_following, is_following(follower, followed)} do
      {:already_following, %Follower{} = follow} ->
        delete_follower(follow)

      {:already_following, nil} ->
        {:error, "Could not unfollow actor: you are not following #{followed.preferred_username}"}
    end
  end

  @doc """
  Checks whether an actor is following another actor.
  """
  @spec is_following(Actor.t(), Actor.t()) :: Follower.t() | nil
  def is_following(%Actor{} = follower_actor, %Actor{} = followed_actor) do
    get_follower_by_followed_and_following(followed_actor, follower_actor)
  end

  @doc """
  Whether the actor needs to be updated.

  Local actors obviously don't need to be updated, neither do suspended ones
  """
  @spec needs_update?(Actor.t()) :: boolean
  def needs_update?(%Actor{domain: nil}), do: false

  def needs_update?(%Actor{suspended: true}), do: false

  def needs_update?(%Actor{last_refreshed_at: nil, domain: domain}) when not is_nil(domain),
    do: true

  def needs_update?(%Actor{domain: domain} = actor) when not is_nil(domain) do
    DateTime.diff(DateTime.utc_now(), actor.last_refreshed_at) >=
      Application.get_env(:mobilizon, :activitypub)[:actor_stale_period]
  end

  def needs_update?(_), do: true

  @spec should_rotate_actor_key(Actor.t()) :: boolean
  def should_rotate_actor_key(%Actor{id: actor_id}) do
    with {:ok, value} when is_boolean(value) <- Cachex.exists?(:actor_key_rotation, actor_id) do
      value
    end
  end

  # TODO: Move me otherwhere
  @spec schedule_key_rotation(Actor.t(), integer()) :: :ok
  def schedule_key_rotation(%Actor{id: actor_id} = actor, delay) do
    Cachex.put(:actor_key_rotation, actor_id, true)

    Workers.Background.enqueue("actor_key_rotation", %{"actor_id" => actor.id}, schedule_in: delay)

    :ok
  end

  @spec delete_files_if_media_changed(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp delete_files_if_media_changed(%Ecto.Changeset{changes: changes, data: data} = changeset) do
    Enum.each([:avatar, :banner], fn key ->
      if Map.has_key?(changes, key) do
        with %Ecto.Changeset{changes: %{url: new_url}} <- changes[key],
             %{url: old_url} <- data |> Map.from_struct() |> Map.get(key),
             false <- new_url == old_url do
          Upload.remove(old_url)
        end
      end
    end)

    changeset
  end

  @spec actor_with_preload_query(integer | String.t(), boolean()) :: Ecto.Query.t()
  defp actor_with_preload_query(actor_id, include_suspended \\ false)

  defp actor_with_preload_query(actor_id, false) do
    actor_id
    |> actor_with_preload_query(true)
    |> where([a], not a.suspended)
  end

  defp actor_with_preload_query(actor_id, true) do
    Actor
    |> where([a], a.id == ^actor_id)
    |> preload([a], [:organized_events, :followers, :followings])
  end

  @spec actor_by_username_query(String.t()) :: Ecto.Query.t()
  defp actor_by_username_query(username) do
    from(
      a in Actor,
      where:
        fragment(
          "f_unaccent(?) <% f_unaccent(?) or f_unaccent(coalesce(?, '')) <% f_unaccent(?)",
          a.preferred_username,
          ^username,
          a.name,
          ^username
        ),
      order_by:
        fragment(
          "word_similarity(?, ?) + word_similarity(coalesce(?, ''), ?) desc",
          a.preferred_username,
          ^username,
          a.name,
          ^username
        )
    )
  end

  @spec actor_by_username_or_name_query(Ecto.Queryable.t(), String.t()) :: Ecto.Query.t()
  defp actor_by_username_or_name_query(query, ""), do: query

  defp actor_by_username_or_name_query(query, username) do
    query
    |> where(
      [a],
      fragment(
        "f_unaccent(?) %> f_unaccent(?) or f_unaccent(coalesce(?, '')) %> f_unaccent(?)",
        a.preferred_username,
        ^username,
        a.name,
        ^username
      )
    )
    |> order_by(
      [a],
      fragment(
        "word_similarity(?, ?) + word_similarity(coalesce(?, ''), ?) desc",
        a.preferred_username,
        ^username,
        a.name,
        ^username
      )
    )
  end

  @spec actors_for_location(Ecto.Queryable.t(), String.t(), integer()) :: Ecto.Query.t()
  defp actors_for_location(query, location, radius)
       when is_valid_string(location) and not is_nil(radius) do
    with {lon, lat} <- Geohax.decode(location),
         point <- Geo.WKT.decode!("SRID=4326;POINT(#{lon} #{lat})") do
      query
      |> join(:inner, [q], a in Address, on: a.id == q.physical_address_id, as: :address)
      |> where(
        [q],
        st_dwithin_in_meters(^point, as(:address).geom, ^(radius * 1000))
      )
    else
      _ -> query
    end
  end

  defp actors_for_location(query, _location, _radius), do: query

  @spec person_query :: Ecto.Query.t()
  defp person_query do
    from(a in Actor, where: a.type == ^:Person)
  end

  @spec group_query :: Ecto.Query.t()
  defp group_query do
    from(a in Actor, where: a.type == ^:Group)
  end

  @spec groups_member_of_query(integer | String.t()) :: Ecto.Query.t()
  defp groups_member_of_query(actor_id) do
    Actor
    |> join(:inner, [a], m in Member, on: a.id == m.parent_id)
    |> where([a, m], m.actor_id == ^actor_id and m.role in ^@member_roles)
  end

  @spec groups_query :: Ecto.Query.t()
  defp groups_query do
    from(
      a in Actor,
      where: a.type == ^:Group,
      where: a.visibility == ^:public
    )
  end

  @spec external_groups_query :: Ecto.Query.t()
  defp external_groups_query do
    where(Actor, [a], a.type == ^:Group and not is_nil(a.domain))
  end

  @spec list_members_for_user_query(integer()) :: Ecto.Query.t()
  defp list_members_for_user_query(user_id) do
    from(
      m in Member,
      join: a in Actor,
      on: m.actor_id == a.id,
      where: a.user_id == ^user_id and m.role != ^:not_approved,
      preload: [:parent, :actor, :invited_by]
    )
  end

  @spec members_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp members_for_actor_query(actor_id) do
    from(
      m in Member,
      where: m.actor_id == ^actor_id,
      preload: [:parent, :invited_by]
    )
  end

  @spec members_for_group_query(integer | String.t()) :: Ecto.Query.t()
  defp members_for_group_query(group_id) do
    Member
    |> where(parent_id: ^group_id)
    |> order_by(desc: :updated_at)
    |> preload([:parent, :actor])
  end

  @spec group_external_member_actor_query(integer()) :: Ecto.Query.t()
  defp group_external_member_actor_query(group_id) do
    Member
    |> where([m], m.parent_id == ^group_id)
    |> join(:inner, [m], a in Actor, on: m.actor_id == a.id)
    |> where([_m, a], not is_nil(a.domain))
    |> select([_m, a], a)
  end

  @spec group_internal_member_actor_query(integer(), list()) :: Ecto.Query.t()
  defp group_internal_member_actor_query(group_id, role) do
    Member
    |> where([m], m.parent_id == ^group_id)
    |> filter_member_role(role)
    |> join(:inner, [m], a in Actor, on: m.actor_id == a.id)
    |> where([_m, a], is_nil(a.domain))
    |> select([_m, a], a)
  end

  @spec group_internal_member_query(integer()) :: Ecto.Query.t()
  defp group_internal_member_query(group_id) do
    Member
    |> where([m], m.parent_id == ^group_id)
    |> join(:inner, [m], a in Actor, on: m.actor_id == a.id)
    |> where([_m, a], is_nil(a.domain))
    |> preload([m], [:parent, :actor])
    |> select([m, _a], m)
  end

  @spec filter_member_role(Ecto.Queryable.t(), list(atom()) | atom()) :: Ecto.Query.t()
  defp filter_member_role(query, []), do: query

  defp filter_member_role(query, roles) when is_list(roles) do
    where(query, [m], m.role in ^roles)
  end

  defp filter_member_role(query, role) when is_atom(role) do
    from(m in query, where: m.role == ^role)
  end

  @spec administrator_members_for_group_query(integer | String.t()) :: Ecto.Query.t()
  defp administrator_members_for_group_query(group_id) do
    from(
      m in Member,
      where: m.parent_id == ^group_id and m.role in ^@administrator_roles,
      preload: [:actor]
    )
  end

  @spec administrator_members_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp administrator_members_for_actor_query(actor_id) do
    from(
      m in Member,
      where: m.actor_id == ^actor_id and m.role in ^@administrator_roles,
      select: m.parent_id
    )
  end

  @spec group_ids_where_last_administrator_query(integer | String.t()) :: Ecto.Query.t()
  defp group_ids_where_last_administrator_query(actor_id) do
    from(
      m in Member,
      where: m.role in ^@administrator_roles,
      join: m2 in subquery(administrator_members_for_actor_query(actor_id)),
      on: m.parent_id == m2.parent_id,
      group_by: m.parent_id,
      select: m.parent_id,
      having: count(m.actor_id) == 1
    )
  end

  @spec follower_by_url(String.t()) :: Ecto.Query.t()
  defp follower_by_url(url) do
    from(
      f in Follower,
      where: f.url == ^url,
      preload: [:actor, :target_actor]
    )
  end

  @spec follower_by_followed_and_following_query(integer | String.t(), integer | String.t()) ::
          Ecto.Query.t()
  defp follower_by_followed_and_following_query(followed_id, follower_id) do
    from(
      f in Follower,
      where: f.target_actor_id == ^followed_id and f.actor_id == ^follower_id,
      preload: [:actor, :target_actor]
    )
  end

  @spec follower_actors_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp follower_actors_for_actor_query(actor_id) do
    from(
      a in Actor,
      join: f in Follower,
      on: a.id == f.actor_id,
      where: f.target_actor_id == ^actor_id and f.approved == true
    )
  end

  @spec follower_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp follower_for_actor_query(actor_id) do
    from(
      f in Follower,
      join: a in Actor,
      on: a.id == f.actor_id,
      where: f.target_actor_id == ^actor_id
    )
  end

  @spec followings_actors_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp followings_actors_for_actor_query(actor_id) do
    from(
      a in Actor,
      join: f in Follower,
      on: a.id == f.target_actor_id,
      where: f.actor_id == ^actor_id
    )
  end

  @spec followings_for_actor_query(integer | String.t()) :: Ecto.Query.t()
  defp followings_for_actor_query(actor_id) do
    from(
      f in Follower,
      join: a in Actor,
      on: a.id == f.target_actor_id,
      where: f.actor_id == ^actor_id
    )
  end

  @spec list_external_follower_actors_for_actor_query(integer) :: Ecto.Query.t()
  defp list_external_follower_actors_for_actor_query(actor_id) do
    actor_id
    |> follower_actors_for_actor_query()
    |> filter_external()
  end

  @spec list_external_followers_for_actor_query(integer) :: Ecto.Query.t()
  defp list_external_followers_for_actor_query(actor_id) do
    actor_id
    |> follower_for_actor_query()
    |> filter_follower_actors_external()
  end

  @spec list_external_followings_for_actor_query(integer) :: Ecto.Query.t()
  defp list_external_followings_for_actor_query(actor_id) do
    actor_id
    |> followings_for_actor_query()
    |> filter_follower_actors_external()
    |> order_by(desc: :updated_at)
  end

  @spec filter_local(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_local(query) do
    from(a in query, where: is_nil(a.domain))
  end

  @spec filter_external(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_external(query) do
    from(a in query, where: not is_nil(a.domain))
  end

  @spec filter_follower_actors_external(Ecto.Queryable.t()) :: Ecto.Query.t()
  defp filter_follower_actors_external(query) do
    query
    |> where([_f, a], not is_nil(a.domain))
    |> preload([f, a], [:target_actor, :actor])
  end

  @spec filter_by_type(Ecto.Queryable.t(), ActorType.t() | nil) :: Ecto.Queryable.t()
  defp filter_by_type(query, type)
       when type in [:Person, :Group, :Application, :Service, :Organisation] do
    from(a in query, where: a.type == ^type)
  end

  defp filter_by_type(query, _type), do: query

  @spec filter_by_types(Ecto.Queryable.t(), [ActorType.t()]) :: Ecto.Query.t()
  defp filter_by_types(query, types) do
    from(a in query, where: a.type in ^types)
  end

  @spec filter_by_minimum_visibility(Ecto.Queryable.t(), atom()) :: Ecto.Query.t()
  defp filter_by_minimum_visibility(query, :private), do: query

  defp filter_by_minimum_visibility(query, :restricted) do
    from(a in query, where: a.visibility in ^[:public, :unlisted, :restricted])
  end

  defp filter_by_minimum_visibility(query, :unlisted) do
    from(a in query, where: a.visibility in ^[:public, :unlisted])
  end

  defp filter_by_minimum_visibility(query, :public) do
    from(a in query, where: a.visibility == ^:public)
  end

  @spec filter_by_name(query :: Ecto.Queryable.t(), [String.t()]) :: Ecto.Query.t()
  defp filter_by_name(query, [name]) do
    where(query, [a], a.preferred_username == ^name and is_nil(a.domain))
  end

  defp filter_by_name(query, [name, domain]) do
    if domain == Mobilizon.Config.instance_hostname() do
      filter_by_name(query, [name])
    else
      where(query, [a], a.preferred_username == ^name and a.domain == ^domain)
    end
  end

  @spec filter_followed_by_approved_status(Ecto.Queryable.t(), boolean() | nil) :: Ecto.Query.t()
  defp filter_followed_by_approved_status(query, nil), do: query

  defp filter_followed_by_approved_status(query, approved) do
    from(f in query, where: f.approved == ^approved)
  end

  @spec preload_followers(Actor.t(), boolean) :: Actor.t()
  defp preload_followers(actor, true), do: Repo.preload(actor, [:followers])
  defp preload_followers(actor, false), do: actor
end
