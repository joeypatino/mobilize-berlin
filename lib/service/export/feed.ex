defmodule Mobilizon.Service.Export.Feed do
  @moduledoc """
  Serve Atom Syndication Feeds.
  """

  import Mobilizon.Web.Gettext

  alias Atomex.{Entry, Feed}

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Config
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Service.Export.{Cachable, Common}
  alias Mobilizon.Users.User

  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.Router.Helpers, as: Routes

  require Logger

  @behaviour Cachable

  @item_limit 500

  @spec version :: String.t()
  defp version, do: Config.instance_version()

  @impl Cachable
  @spec create_cache(String.t()) ::
          {:commit, String.t()}
          | {:ignore, :actor_not_found | :actor_not_public | :bad_token | :token_not_found}
  def create_cache("actor_" <> name) do
    case fetch_actor_event_feed(name) do
      {:ok, res} ->
        {:commit, res}

      {:error, err} ->
        {:ignore, err}
    end
  end

  @impl Cachable
  def create_cache("token_" <> token) do
    case fetch_events_from_token(token) do
      {:ok, res} ->
        {:commit, res}

      {:error, err} ->
        {:ignore, err}
    end
  end

  @impl Cachable
  def create_cache("instance") do
    {:ok, res} = fetch_instance_feed()
    {:commit, res}
  end

  @spec fetch_instance_feed :: {:ok, String.t()}
  defp fetch_instance_feed do
    {:ok, events, posts} = Common.fetch_instance_public_content(@item_limit)
    {:ok, build_instance_feed(events, posts)}
  end

  # Build an atom feed from the whole instance and its public events and posts
  @spec build_instance_feed(list(), list()) :: String.t()
  defp build_instance_feed(events, posts) do
    self_url = Endpoint.url()

    title =
      gettext("Public feed for %{instance}",
        instance: Config.instance_name()
      )

    # Title uses default instance language
    self_url
    |> Feed.new(
      DateTime.utc_now(),
      title
    )
    |> Feed.link(self_url, rel: "self")
    |> Feed.link(self_url, rel: "alternate")
    |> Feed.generator(Config.instance_name(), uri: Endpoint.url(), version: version())
    |> Feed.entries(Enum.map(events ++ posts, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  @spec fetch_actor_event_feed(String.t(), integer()) ::
          {:ok, String.t()} | {:error, :actor_not_found | :actor_not_public}
  defp fetch_actor_event_feed(name, limit \\ @item_limit) do
    case Common.fetch_actor_event_feed(name, limit) do
      {:ok, actor, events, posts} ->
        {:ok, build_actor_feed(actor, events, posts)}

      {:error, err} ->
        {:error, err}
    end
  end

  # Build an atom feed from actor and its public events and posts
  @spec build_actor_feed(Actor.t(), list(Event.t()), list(Post.t()), boolean()) :: String.t()
  defp build_actor_feed(%Actor{} = actor, events, posts, public \\ true) do
    display_name = Actor.display_name(actor)

    self_url =
      Endpoint
      |> Routes.feed_url(:actor, actor.preferred_username, "atom")
      |> URI.decode()

    title =
      if public,
        do:
          gettext("%{actor}'s public events feed on %{instance}",
            actor: display_name,
            instance: Config.instance_name()
          ),
        else:
          gettext("%{actor}'s private events feed on %{instance}",
            actor: display_name,
            instance: Config.instance_name()
          )

    # Title uses default instance language
    feed =
      self_url
      |> Feed.new(
        DateTime.utc_now(),
        title
      )
      |> Feed.author(display_name, uri: actor.url)
      |> Feed.link(self_url, rel: "self")
      |> Feed.link(actor.url, rel: "alternate")
      |> Feed.generator(Config.instance_name(), uri: Endpoint.url(), version: version())
      |> Feed.entries(Enum.map(events ++ posts, &get_entry/1))

    feed =
      if actor.avatar do
        feed |> Feed.icon(actor.avatar.url)
      else
        feed
      end

    feed =
      if actor.banner do
        feed |> Feed.logo(actor.banner.url)
      else
        feed
      end

    feed
    |> Feed.build()
    |> Atomex.generate_document()
  end

  # Create an entry for the Atom feed
  @spec get_entry(Event.t()) :: any()
  defp get_entry(%Event{} = event) do
    description = event.description || ""

    entry =
      event.url
      |> Entry.new(event.publish_at || event.inserted_at, event.title)
      |> Entry.link(event.url, rel: "alternate", type: "text/html")
      |> Entry.content({:cdata, description}, type: "html")
      |> Entry.published(event.publish_at || event.inserted_at)

    # Add tags
    entry =
      event.tags
      |> Enum.uniq()
      |> Enum.reduce(entry, fn tag, acc -> Entry.category(acc, tag.slug, label: tag.title) end)

    Entry.build(entry)
  end

  @spec get_entry(Post.t()) :: any()
  defp get_entry(%Post{} = post) do
    body = post.body || ""

    entry =
      post.url
      |> Entry.new(post.publish_at || post.inserted_at, post.title)
      |> Entry.link(post.url, rel: "alternate", type: "text/html")
      |> Entry.content({:cdata, body}, type: "html")
      |> Entry.published(post.publish_at || post.inserted_at)
      |> Entry.author(post.author.name || post.author.preferred_username)

    # Add tags
    entry =
      post.tags
      |> Enum.uniq()
      |> Enum.reduce(entry, fn tag, acc -> Entry.category(acc, tag.slug, label: tag.title) end)

    Entry.build(entry)
  end

  # Only events, not posts
  @spec fetch_events_from_token(String.t(), integer()) ::
          {:ok, String.t()} | {:error, :bad_token | :token_not_found}
  defp fetch_events_from_token(token, limit \\ @item_limit) do
    case Common.fetch_events_from_token(token, limit) do
      %{events: events, token: token, user: user, actor: actor, type: type} ->
        case type do
          :user -> {:ok, build_user_feed(events, user, token)}
          :actor -> {:ok, build_actor_feed(actor, events, [], false)}
        end

      {:error, err} ->
        {:error, err}
    end
  end

  # Build an atom feed from actor and its public events
  @spec build_user_feed(list(Event.t()), User.t(), String.t()) :: String.t()
  defp build_user_feed(events, %User{email: email}, token) do
    self_url = Endpoint |> Routes.feed_url(:going, token, "atom") |> URI.decode()

    # Title uses default instance language
    self_url
    |> Feed.new(
      DateTime.utc_now(),
      gettext("Feed for %{email} on %{instance}",
        email: email,
        instance: Config.instance_name()
      )
    )
    |> Feed.link(self_url, rel: "self")
    |> Feed.generator(Config.instance_name(), uri: Endpoint.url(), version: version())
    |> Feed.entries(Enum.map(events, &get_entry/1))
    |> Feed.build()
    |> Atomex.generate_document()
  end

  @impl Cachable
  def clear_caches(%Event{attributed_to: %Actor{} = actor} = event) do
    clear_actor_feed(actor)
    clear_caches(%{event | attributed_to: nil})
  end

  @impl Cachable
  def clear_caches(%Event{}) do
    # TODO: It would be nice to clear feed token cache based on participations as well,
    # but that's harder, as it would require loading all participations
    clear_instance()
  end

  @impl Cachable
  def clear_caches(%Post{attributed_to: %Actor{} = actor} = post) do
    clear_actor_feed(actor)
    clear_caches(%{post | attributed_to: nil})
  end

  @impl Cachable
  def clear_caches(%Post{}) do
    clear_instance()
  end

  @impl Cachable
  def clear_caches(%Actor{} = actor) do
    clear_actor_feed(actor)
    clear_instance()
  end

  defp clear_instance do
    Cachex.del(:feed, "instance")
  end

  defp clear_actor_feed(%Actor{preferred_username: preferred_username} = actor) do
    if Actor.is_public_visibility?(actor) do
      Cachex.del(:feed, "actor_#{preferred_username}")
    end
  end
end
