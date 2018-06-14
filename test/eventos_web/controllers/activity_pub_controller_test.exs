defmodule EventosWeb.ActivityPubControllerTest do
  use EventosWeb.ConnCase
  import Eventos.Factory
  alias EventosWeb.ActivityPub.{ActorView, ObjectView}
  alias Eventos.{Repo, Actors, Actors.Actor}
  alias Eventos.Activity
  import Logger

  describe "/@:username" do
    test "it returns a json representation of the actor", %{conn: conn} do
      actor = insert(:actor)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/@#{actor.preferred_username}")

      actor = Actors.get_actor!(actor.id)

      assert json_response(conn, 200) == ActorView.render("actor.json", %{actor: actor})
      Logger.error(inspect ActorView.render("actor.json", %{actor: actor}))
    end
  end

  describe "/events/uuid" do
    test "it returns a json representation of the object", %{conn: conn} do
      event = insert(:event)

      conn =
        conn
        |> put_req_header("accept", "application/activity+json")
        |> get("/events/#{event.uuid}")

      assert json_response(conn, 200) == ObjectView.render("event.json", %{event: event})
      Logger.error(inspect ObjectView.render("event.json", %{event: event}))
    end
  end

#  describe "/actors/:username/inbox" do
#    test "it inserts an incoming activity into the database", %{conn: conn} do
#      data = File.read!("test/fixtures/mastodon-post-activity.json") |> Poison.decode!()
#
#      conn =
#        conn
#        |> assign(:valid_signature, true)
#        |> put_req_header("content-type", "application/activity+json")
#        |> post("/inbox", data)
#
#      assert "ok" == json_response(conn, 200)
#      :timer.sleep(500)
#      assert Activity.get_by_ap_id(data["id"])
#    end
#  end

#  describe "/actors/:nickname/followers" do
#    test "it returns the followers in a collection", %{conn: conn} do
#      user = insert(:user)
#      user_two = insert(:user)
#      User.follow(user, user_two)
#
#      result =
#        conn
#        |> get("/users/#{user_two.nickname}/followers")
#        |> json_response(200)
#
#      assert result["first"]["orderedItems"] == [user.ap_id]
#    end
#
#    test "it works for more than 10 users", %{conn: conn} do
#      user = insert(:user)
#
#      Enum.each(1..15, fn _ ->
#        other_user = insert(:user)
#        User.follow(other_user, user)
#      end)
#
#      result =
#        conn
#        |> get("/users/#{user.nickname}/followers")
#        |> json_response(200)
#
#      assert length(result["first"]["orderedItems"]) == 10
#      assert result["first"]["totalItems"] == 15
#      assert result["totalItems"] == 15
#
#      result =
#        conn
#        |> get("/users/#{user.nickname}/followers?page=2")
#        |> json_response(200)
#
#      assert length(result["orderedItems"]) == 5
#      assert result["totalItems"] == 15
#    end
#  end
#
#  describe "/users/:nickname/following" do
#    test "it returns the following in a collection", %{conn: conn} do
#      user = insert(:user)
#      user_two = insert(:user)
#      User.follow(user, user_two)
#
#      result =
#        conn
#        |> get("/users/#{user.nickname}/following")
#        |> json_response(200)
#
#      assert result["first"]["orderedItems"] == [user_two.ap_id]
#    end
#
#    test "it works for more than 10 users", %{conn: conn} do
#      user = insert(:user)
#
#      Enum.each(1..15, fn _ ->
#        user = Repo.get(User, user.id)
#        other_user = insert(:user)
#        User.follow(user, other_user)
#      end)
#
#      result =
#        conn
#        |> get("/users/#{user.nickname}/following")
#        |> json_response(200)
#
#      assert length(result["first"]["orderedItems"]) == 10
#      assert result["first"]["totalItems"] == 15
#      assert result["totalItems"] == 15
#
#      result =
#        conn
#        |> get("/users/#{user.nickname}/following?page=2")
#        |> json_response(200)
#
#      assert length(result["orderedItems"]) == 5
#      assert result["totalItems"] == 15
#    end
#  end
end