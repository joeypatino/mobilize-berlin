defmodule MobilizonWeb.SearchView do
  @moduledoc """
  View for Events
  """
  use MobilizonWeb, :view
  alias MobilizonWeb.{EventView, ActorView, GroupView, AddressView}

  def render("search.json", %{events: events, actors: actors}) do
    %{
      data: %{
        events: render_many(events, EventView, "event_simple.json"),
        actors: render_many(actors, ActorView, "actor_basic.json")
      }
    }
  end
end