defmodule Mobilizon.Service.MetadataTest do
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Discussions.Comment
  alias Mobilizon.Events.Event
  alias Mobilizon.Posts.Post
  alias Mobilizon.Service.Metadata
  alias Mobilizon.Tombstone
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.JsonLD.ObjectView
  alias Mobilizon.Web.Router.Helpers, as: Routes
  use Mobilizon.DataCase
  import Mobilizon.Factory

  describe "build_tags/2 for an actor" do
    test "that is a group gives tags" do
      %Actor{} = group = insert(:group, name: "My group")

      assert group |> Metadata.build_tags() |> Metadata.Utils.stringify_tags() ==
               String.trim("""
               <meta content="#{group.name} (@#{group.preferred_username})" property="og:title"><meta content="#{group.url}" property="og:url"><meta content="The event organizer didn&#39;t add any description." property="og:description"><meta content="profile" property="og:type"><meta content="#{group.preferred_username}" property="profile:username"><meta content="summary" property="twitter:card"><meta content="#{group.avatar.url}" property="og:image"><script type="application/ld+json">{"@context":"http://schema.org","@type":"Organization","address":null,"name":"#{group.name}","url":"#{group.url}"}</script><link href="#{Routes.feed_url(Endpoint, :actor, group.preferred_username, "atom")}" rel="alternate" title="#{group.name}'s feed" type="application/atom+xml"><link href="#{Routes.feed_url(Endpoint, :actor, group.preferred_username, "ics")}" rel="alternate" title="#{group.name}'s feed" type="text/calendar">
               """)

      assert group
             |> Map.put(:avatar, nil)
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               String.trim("""
               <meta content="#{group.name} (@#{group.preferred_username})" property="og:title"><meta content="#{group.url}" property="og:url"><meta content="The event organizer didn&#39;t add any description." property="og:description"><meta content="profile" property="og:type"><meta content="#{group.preferred_username}" property="profile:username"><meta content="summary" property="twitter:card"><script type="application/ld+json">{"@context":"http://schema.org","@type":"Organization","address":null,"name":"#{group.name}","url":"#{group.url}"}</script><link href="#{Routes.feed_url(Endpoint, :actor, group.preferred_username, "atom")}" rel="alternate" title="#{group.name}'s feed" type="application/atom+xml"><link href="#{Routes.feed_url(Endpoint, :actor, group.preferred_username, "ics")}" rel="alternate" title="#{group.name}'s feed" type="text/calendar">
               """)
    end

    test "that is not a group doesn't give anything" do
      %Actor{} = person = insert(:actor)

      assert person |> Metadata.build_tags() |> Metadata.Utils.stringify_tags() == ""
      assert person |> Metadata.build_tags("fr") |> Metadata.Utils.stringify_tags() == ""
    end
  end

  describe "build_tags/2 for an event" do
    @long_description """
    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer malesuada commodo nunc, dictum dignissim erat aliquet quis. Morbi iaculis scelerisque magna eu dapibus. Morbi ultricies mollis arcu, vel auctor enim dapibus ut. Cras tempus sapien eu lacus blandit suscipit. Fusce tincidunt fringilla velit non elementum. Etiam pretium venenatis placerat. Suspendisse interdum, justo efficitur faucibus commodo, dolor elit vehicula lacus, eu molestie nulla mi vel dolor. Nullam fringilla at lorem a gravida. Praesent viverra, ante eu porttitor rutrum, ex leo condimentum felis, vitae vestibulum neque turpis in nunc. Nullam aliquam rhoncus ornare. Suspendisse finibus finibus est sed eleifend. Nam a massa vestibulum, mollis lorem vel, placerat purus. Nam ex nunc, hendrerit ut lacinia ac, pellentesque eu est.</p>

    <p>Fusce nec odio tellus. Aliquam at fermentum turpis, ut dictum tellus. Fusce ac nibh vehicula, imperdiet ipsum sit amet, pellentesque dui. Vivamus venenatis efficitur elementum. Quisque mattis dui ac faucibus mollis. Nullam ac malesuada nisi, vitae scelerisque nisi. Nulla placerat nunc non convallis sollicitudin. Donec sed pulvinar leo, quis tristique eros. Nulla pretium elit ante, consectetur aliquam sapien varius nec. Donec cursus, orci quis suscipit placerat, mi lectus convallis sem, et scelerisque urna libero nec sapien. Nam quis justo ante. Nulla placerat est nec suscipit euismod.</p>
    """
    @truncated_description "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer malesuada commodo nunc, dictum dignissim erat aliquet quis. Morbi iaculis scelerisque magna eu dapibus. Morbi ultricies mollis arcu, vel???"

    test "gives tags" do
      %Event{} = event = insert(:event, description: @long_description)

      tags_output = event |> Metadata.build_tags() |> Metadata.Utils.stringify_tags()
      {:ok, document} = Floki.parse_fragment(tags_output)
      assert "#{event.title} - Mobilizon" == document |> Floki.find("title") |> Floki.text()

      assert @truncated_description ==
               document
               |> Floki.find("meta[name=\"description\"]")
               |> Floki.attribute("content")
               |> hd

      assert event.title ==
               document
               |> Floki.find("meta[property=\"og:title\"]")
               |> Floki.attribute("content")
               |> hd

      assert event.url ==
               document
               |> Floki.find("meta[property=\"og:url\"]")
               |> Floki.attribute("content")
               |> hd

      assert document
             |> Floki.find("meta[property=\"og:description\"]")
             |> Floki.attribute("content")
             |> hd =~ @truncated_description

      assert "website" ==
               document
               |> Floki.find("meta[property=\"og:type\"]")
               |> Floki.attribute("content")
               |> hd

      assert event.url ==
               document
               |> Floki.find("link[rel=\"canonical\"]")
               |> Floki.attribute("href")
               |> hd

      assert event.picture.file.url ==
               document
               |> Floki.find("meta[property=\"og:image\"]")
               |> Floki.attribute("content")
               |> hd

      assert "summary_large_image" ==
               document
               |> Floki.find("meta[property=\"twitter:card\"]")
               |> Floki.attribute("content")
               |> hd

      assert "event.json" |> ObjectView.render(%{event: event}) |> Jason.encode!() ==
               document
               |> Floki.find("script[type=\"application/ld+json\"]")
               |> Floki.text(js: true)

      tags_output =
        event
        |> Map.put(:picture, nil)
        |> Metadata.build_tags()
        |> Metadata.Utils.stringify_tags()

      {:ok, document} = Floki.parse_fragment(tags_output)

      assert [] == Floki.find(document, "meta[property=\"og:image\"]")
    end
  end

  describe "build_tags/2 for a post" do
    test "gives tags" do
      %Post{} = post = insert(:post)

      assert post
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               String.trim("""
               <meta content="#{post.title}" property="og:title"><meta content="#{post.url}" property="og:url"><meta content="#{Metadata.Utils.process_description(post.body)}" property="og:description"><meta content="article" property="og:type"><meta content="summary" property="twitter:card"><link href="#{post.url}" rel="canonical"><meta content="#{post.picture.file.url}" property="og:image"><meta content="summary_large_image" property="twitter:card"><script type="application/ld+json">{"@context":"https://schema.org","@type":"Article","author":{"@type":"Organization","name":"#{post.attributed_to.preferred_username}"},"dateModified":"#{DateTime.to_iso8601(post.updated_at)}","datePublished":"#{DateTime.to_iso8601(post.publish_at)}","name":"My Awesome article"}</script>
               """)
    end
  end

  describe "build_tags/2 for a comment" do
    test "gives tags" do
      %Comment{} = comment = insert(:comment)

      assert comment
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() ==
               String.trim("""
               <meta content="#{comment.actor.preferred_username}" property="og:title"><meta content="#{comment.url}" property="og:url"><meta content="#{comment.text}" property="og:description"><meta content="website" property="og:type"><meta content="summary" property="twitter:card">
               """)
    end
  end

  describe "build_tags/2 for a tombstone" do
    test "gives nothing" do
      %Tombstone{} = tombstone = insert(:tombstone)

      assert tombstone
             |> Metadata.build_tags()
             |> Metadata.Utils.stringify_tags() == ""
    end
  end
end
