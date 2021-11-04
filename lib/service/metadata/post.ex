defimpl Mobilizon.Service.Metadata, for: Mobilizon.Posts.Post do
  alias Phoenix.HTML
  alias Phoenix.HTML.Tag
  alias Mobilizon.Actors.Actor
  alias Mobilizon.Medias.{File, Media}
  alias Mobilizon.Posts.Post
  alias Mobilizon.Web.Endpoint
  alias Mobilizon.Web.JsonLD.ObjectView
  alias Mobilizon.Web.Router.Helpers, as: Routes
  import Mobilizon.Service.Metadata.Utils, only: [process_description: 2, strip_tags: 1]

  def build_tags(%Post{} = post, locale \\ "en") do
    post = Map.put(post, :body, process_description(post.body, locale))

    tags =
      [
        Tag.tag(:meta, property: "og:title", content: post.title),
        Tag.tag(:meta, property: "og:url", content: post.url),
        Tag.tag(:meta, property: "og:description", content: post.body),
        Tag.tag(:meta, property: "og:type", content: "article"),
        Tag.tag(:meta, property: "twitter:card", content: "summary"),
        # Tell Search Engines what's the origin
        Tag.tag(:link, rel: "canonical", href: post.url)
      ]
      |> maybe_add_post_picture(post)

    breadcrumbs = %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => [
        %{
          "@type" => "ListItem",
          "position" => 1,
          "name" => Actor.display_name(post.attributed_to),
          "item" =>
            Endpoint
            |> Routes.page_url(
              :actor,
              Actor.preferred_username_and_domain(post.attributed_to)
            )
            |> URI.decode()
        },
        %{
          "@type" => "ListItem",
          "position" => 2,
          "name" => post.title
        }
      ]
    }

    tags ++
      [
        Tag.tag(:meta, property: "twitter:card", content: "summary_large_image"),
        ~s{<script type="application/ld+json">#{Jason.encode!(breadcrumbs)}</script>}
        |> HTML.raw(),
        ~s{<script type="application/ld+json">#{json(post)}</script>} |> HTML.raw()
      ]
  end

  # Insert JSON-LD schema by hand because Tag.content_tag wants to escape it
  defp json(%Post{title: title} = post) do
    "post.json"
    |> ObjectView.render(%{post: %{post | title: strip_tags(title)}})
    |> Jason.encode!()
  end

  @spec maybe_add_post_picture(list(), Post.t()) :: list()
  defp maybe_add_post_picture(tags, %Post{picture: %Media{file: %File{url: url}}}),
    do:
      tags ++
        [
          Tag.tag(:meta,
            property: "og:image",
            content: url
          )
        ]

  defp maybe_add_post_picture(tags, _), do: tags
end
