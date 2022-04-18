defmodule Mobilizon.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query
  import EctoEnum

  import Mobilizon.Storage.Ecto

  alias Ecto.Multi
  alias Mobilizon.Actors.Actor
  alias Mobilizon.{Crypto, Events}
  alias Mobilizon.Events.FeedToken
  alias Mobilizon.Storage.{Page, Repo}
  alias Mobilizon.Users.{ActivitySetting, PushSubscription, Setting, User}

  defenum(UserRole, :user_role, [:administrator, :moderator, :user])

  defenum(NotificationPendingNotificationDelay,
    none: 0,
    direct: 1,
    one_hour: 5,
    one_day: 10,
    one_week: 15
  )

  @confirmation_token_length 30

  @doc """
  Registers an user.
  """
  @spec register(map) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register(args) do
    with {:ok, %User{} = user} <-
           %User{}
           |> User.registration_changeset(args)
           |> Repo.insert() do
      Events.create_feed_token(%{user_id: user.id})

      {:ok, user}
    end
  end

  @spec create_external(String.t(), String.t(), map()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_external(email, provider, args \\ %{}) do
    with {:ok, %User{} = user} <-
           %User{}
           |> User.auth_provider_changeset(Map.merge(args, %{email: email, provider: provider}))
           |> Repo.insert() do
      Events.create_feed_token(%{user_id: user.id})

      {:ok, user}
    end
  end

  @doc """
  Gets a single user.
  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  @spec get_user!(integer | String.t()) :: User.t()
  def get_user!(id), do: Repo.get!(User, id)

  @spec get_user(integer | String.t() | nil) :: User.t() | nil
  def get_user(nil), do: nil
  def get_user(id), do: Repo.get(User, id)

  def get_user_with_settings!(id) do
    User
    |> Repo.get(id)
    |> Repo.preload([:settings])
  end

  def get_user_with_activity_settings!(id) do
    User
    |> Repo.get(id)
    |> Repo.preload([:settings, :activity_settings])
  end

  @doc """
  Gets an user by its email.
  """
  @spec get_user_by_email(String.t(), Keyword.t()) ::
          {:ok, User.t()} | {:error, :user_not_found}
  def get_user_by_email(email, options \\ []) do
    activated = Keyword.get(options, :activated, nil)
    unconfirmed = Keyword.get(options, :unconfirmed, true)
    query = user_by_email_query(email, activated, unconfirmed)

    case Repo.one(query) do
      nil ->
        {:error, :user_not_found}

      user ->
        {:ok, user}
    end
  end

  @doc """
  Get an user by its activation token.
  """
  @spec get_user_by_activation_token(String.t()) :: User.t() | nil
  def get_user_by_activation_token(token) do
    token
    |> user_by_activation_token_query()
    |> Repo.one()
  end

  @doc """
  Get an user by its reset password token.
  """
  @spec get_user_by_reset_password_token(String.t()) :: User.t() | nil
  def get_user_by_reset_password_token(token) do
    token
    |> user_by_reset_password_token_query()
    |> Repo.one()
  end

  @doc """
  Updates an user.
  """
  @spec update_user(User.t(), map) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    with {:ok, %User{} = user} <-
           user
           |> User.changeset(attrs)
           |> Repo.update() do
      {:ok, Repo.preload(user, [:default_actor])}
    end
  end

  @spec update_user_email(User.t(), String.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user_email(%User{} = user, new_email) do
    user
    |> User.changeset(%{
      unconfirmed_email: new_email,
      confirmation_token: Crypto.random_string(@confirmation_token_length),
      confirmation_sent_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
    |> Repo.update()
  end

  @spec validate_email(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def validate_email(%User{} = user) do
    user
    |> User.changeset(%{
      email: user.unconfirmed_email,
      unconfirmed_email: nil,
      confirmation_token: nil,
      confirmation_sent_at: nil
    })
    |> Repo.update()
  end

  @delete_user_default_options [reserve_email: true]

  @doc """
  Deletes an user.

  Options:
  * `reserve_email` whether to keep a record of the email so that the user can't register again
  """
  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{id: user_id} = user, options \\ @delete_user_default_options) do
    delete_user_options = Keyword.merge(@delete_user_default_options, options)

    multi =
      Multi.new()
      |> Multi.delete_all(:settings, from(s in Setting, where: s.user_id == ^user_id))
      |> Multi.delete_all(:feed_tokens, from(f in FeedToken, where: f.user_id == ^user_id))

    multi =
      if Keyword.get(delete_user_options, :reserve_email, true) do
        Multi.update(multi, :user, User.delete_changeset(user))
      else
        Multi.delete(multi, :user, user)
      end

    case Repo.transaction(multi) do
      {:ok, %{user: %User{} = user}} ->
        {:ok, user}

      {:error, remove, error, _} when remove in [:settings, :feed_tokens] ->
        {:error, error}
    end
  end

  @doc """
  Get an user with its actors
  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  @spec get_user_with_actors!(integer | String.t()) :: User.t()
  def get_user_with_actors!(id) do
    id
    |> get_user!()
    |> Repo.preload([:actors, :default_actor])
  end

  @doc """
  Get user with its actors.
  """
  @spec get_user_with_actors(integer()) :: {:ok, User.t()} | {:error, String.t()}
  def get_user_with_actors(id) do
    case Repo.get(User, id) do
      nil ->
        {:error, "User with ID #{id} not found"}

      user ->
        user =
          user
          |> Repo.preload([:actors, :default_actor])
          |> Map.put(:actors, get_actors_for_user(user))

        {:ok, user}
    end
  end

  @doc """
  Gets the associated actor for an user, either the default set one or the first
  found.
  """
  @spec get_actor_for_user(User.t()) :: Actor.t() | nil
  def get_actor_for_user(%User{} = user) do
    actor =
      user
      |> actor_for_user_query()
      |> Repo.one()

    case actor do
      nil ->
        case get_actors_for_user(user) do
          [] ->
            nil

          actors ->
            hd(actors)
        end

      actor ->
        actor
    end
  end

  @doc """
  Gets actors for an user.
  """
  @spec get_actors_for_user(User.t()) :: [Actor.t()]
  def get_actors_for_user(%User{} = user) do
    user
    |> actors_for_user_query()
    |> Repo.all()
  end

  @doc """
  Updates user's default actor.
  Raises `Ecto.NoResultsError` if the user does not exist.
  """
  @spec update_user_default_actor(User.t(), Actor.t() | nil) :: User.t()
  def update_user_default_actor(%User{id: user_id} = user, actor) do
    actor_id = if is_nil(actor), do: nil, else: actor.id

    user_id
    |> update_user_default_actor_query()
    |> Repo.update_all(set: [default_actor_id: actor_id])

    Cachex.put(:default_actors, to_string(user_id), actor)

    %User{user | default_actor: actor}
  end

  @doc """
  Returns the list of users.
  """
  @spec list_users(Keyword.t()) :: Page.t(User.t())
  def list_users(options) do
    User
    |> filter_by_email(Keyword.get(options, :email))
    |> filter_by_ip(Keyword.get(options, :current_sign_in_ip))
    |> sort(Keyword.get(options, :sort), Keyword.get(options, :direction))
    |> preload([u], [:actors, :feed_tokens, :settings, :default_actor])
    |> Page.build_page(Keyword.get(options, :page), Keyword.get(options, :limit))
  end

  @doc """
  Returns the list of administrators.
  """
  @spec list_admins :: [User.t()]
  def list_admins do
    User
    |> where([u], u.role == ^:administrator)
    |> Repo.all()
  end

  @doc """
  Returns the list of moderators.
  """
  @spec list_moderators :: [User.t()]
  def list_moderators do
    User
    |> where([u], u.role in ^[:administrator, :moderator])
    |> Repo.all()
  end

  @doc """
  Counts users.
  """
  @spec count_users :: integer
  def count_users, do: Repo.one(from(u in User, select: count(u.id), where: u.disabled == false))

  @spec get_setting(User.t()) :: Setting.t() | nil
  def get_setting(%User{id: user_id}), do: get_setting(user_id)

  @spec get_setting(String.t() | integer()) :: Setting.t() | nil
  def get_setting(user_id), do: Repo.get(Setting, user_id)

  @doc """
  Creates a setting.

  ## Examples

      iex> create_setting(%{field: value})
      {:ok, %Setting{}}

      iex> create_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_setting(map()) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  def create_setting(attrs \\ %{}) do
    %Setting{}
    |> Setting.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:user_id, :inserted_at]},
      conflict_target: :user_id
    )
  end

  @doc """
  Updates a setting.

  ## Examples

      iex> update_setting(setting, %{field: new_value})
      {:ok, %Setting{}}

      iex> update_setting(setting, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_setting(%Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Get a paginated list of all of a user's subscriptions
  """
  @spec list_user_push_subscriptions(String.t() | integer(), integer() | nil, integer() | nil) ::
          Page.t(PushSubscription.t())
  def list_user_push_subscriptions(user_id, page \\ nil, limit \\ nil) do
    PushSubscription
    |> where([p], p.user_id == ^user_id)
    |> Page.build_page(page, limit)
  end

  @doc """
  Get a push subscription by their endpoint
  """
  @spec get_push_subscription_by_endpoint(String.t()) :: PushSubscription.t() | nil
  def get_push_subscription_by_endpoint(endpoint) do
    PushSubscription
    |> Repo.get_by(endpoint: endpoint)
    |> Repo.preload([:user])
  end

  @doc """
  Creates a push subscription.

  ## Examples

      iex> create_push_subscription(%{field: value})
      {:ok, %PushSubscription{}}

      iex> create_push_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_push_subscription(map()) ::
          {:ok, PushSubscription.t()} | {:error, Ecto.Changeset.t()}
  def create_push_subscription(attrs) do
    %PushSubscription{}
    |> PushSubscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a push subscription.

  ## Examples

      iex> delete_push_subscription(push_subscription)
      {:ok, %PushSubscription{}}

      iex> delete_push_subscription(push_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_push_subscription(%PushSubscription{} = push_subscription) do
    Repo.delete(push_subscription)
  end

  @doc """
  Lists the activity settings for an user

  ## Examples

      iex> activity_settings_for_user(user)
      [%ActivitySetting{}]

      iex> activity_settings_for_user(user)
      []

  """
  def activity_settings_for_user(%User{id: user_id}) do
    ActivitySetting
    |> where([a], a.user_id == ^user_id)
    |> Repo.all()
  end

  @doc """
  Creates an activity setting. Overrides existing values if present

  ## Examples

      iex> create_activity_setting(%{field: value})
      {:ok, %ActivitySetting{}}

      iex> create_activity_setting(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_activity_setting(attrs \\ %{}) do
    %ActivitySetting{}
    |> ActivitySetting.changeset(attrs)
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:user_id, :key, :method])
  end

  @doc """
  Returns a stream of users which want to have a scheduled recap
  """
  @spec stream_users_for_recap :: Enum.t()
  def stream_users_for_recap do
    User
    |> filter_activated(true)
    |> join(:inner, [u], s in Setting, on: s.user_id == u.id)
    |> where([_u, s], s.group_notifications in [:one_hour, :one_day, :one_week])
    |> Repo.stream()
  end

  @spec user_by_email_query(String.t(), boolean | nil, boolean()) :: Ecto.Query.t()
  defp user_by_email_query(email, activated, unconfirmed) do
    User
    |> where([u], u.email == ^email)
    |> include_unconfirmed(unconfirmed, email)
    |> filter_activated(activated)
    |> preload([:default_actor])
  end

  defp include_unconfirmed(query, false, _email), do: query

  defp include_unconfirmed(query, true, email),
    do: or_where(query, [u], u.unconfirmed_email == ^email)

  defp filter_activated(query, nil), do: query

  defp filter_activated(query, true),
    do: where(query, [u], not is_nil(u.confirmed_at) and not u.disabled)

  defp filter_activated(query, false), do: where(query, [u], is_nil(u.confirmed_at))

  @spec user_by_activation_token_query(String.t()) :: Ecto.Query.t()
  defp user_by_activation_token_query(token) do
    from(
      u in User,
      where: u.confirmation_token == ^token,
      preload: [:default_actor]
    )
  end

  @spec user_by_reset_password_token_query(String.t()) :: Ecto.Query.t()
  defp user_by_reset_password_token_query(token) do
    from(
      u in User,
      where: u.reset_password_token == ^token,
      preload: [:default_actor]
    )
  end

  @spec actor_for_user_query(User.t()) :: Ecto.Query.t()
  defp actor_for_user_query(%User{id: user_id}) do
    from(
      a in Actor,
      join: u in User,
      on: u.default_actor_id == a.id,
      where: u.id == ^user_id
    )
  end

  @spec actors_for_user_query(User.t()) :: Ecto.Query.t()
  defp actors_for_user_query(%User{id: user_id}) do
    from(a in Actor, where: a.user_id == ^user_id)
  end

  @spec update_user_default_actor_query(integer | String.t()) ::
          Ecto.Query.t()
  defp update_user_default_actor_query(user_id) do
    where(User, [u], u.id == ^user_id)
  end

  @spec filter_by_email(Ecto.Queryable.t(), String.t() | nil) :: Ecto.Query.t()
  defp filter_by_email(query, nil), do: query
  defp filter_by_email(query, ""), do: query
  defp filter_by_email(query, email), do: where(query, [q], ilike(q.email, ^"%#{email}%"))

  @spec filter_by_ip(Ecto.Queryable.t(), String.t() | nil) :: Ecto.Query.t()
  defp filter_by_ip(query, nil), do: query
  defp filter_by_ip(query, ""), do: query

  defp filter_by_ip(query, current_sign_in_ip),
    do: where(query, [q], q.current_sign_in_ip == ^current_sign_in_ip)
end
