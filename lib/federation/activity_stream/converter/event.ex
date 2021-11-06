defmodule Mobilizon.Federation.ActivityStream.Converter.Event do
  @moduledoc """
  Event converter.

  This module allows to convert events from ActivityStream format to our own
  internal one, and back.
  """

  alias Mobilizon.Actors.Actor
  alias Mobilizon.Addresses.Address
  alias Mobilizon.Events.Event, as: EventModel
  alias Mobilizon.Medias.Media

  alias Mobilizon.Federation.ActivityStream.{Converter, Convertible}
  alias Mobilizon.Federation.ActivityStream.Converter.Address, as: AddressConverter
  alias Mobilizon.Federation.ActivityStream.Converter.EventMetadata, as: EventMetadataConverter
  alias Mobilizon.Federation.ActivityStream.Converter.Media, as: MediaConverter
  alias Mobilizon.Service.TimezoneDetector
  alias Mobilizon.Web.Endpoint

  import Mobilizon.Federation.ActivityStream.Converter.Utils,
    only: [
      fetch_tags: 1,
      fetch_mentions: 1,
      build_tags: 1,
      maybe_fetch_actor_and_attributed_to_id: 1,
      process_pictures: 2,
      get_address: 1
    ]

  require Logger

  @behaviour Converter

  defimpl Convertible, for: EventModel do
    alias Mobilizon.Federation.ActivityStream.Converter.Event, as: EventConverter

    defdelegate model_to_as(event), to: EventConverter
  end

  @online_address_name "Website"
  @banner_picture_name "Banner"
  @ap_public "https://www.w3.org/ns/activitystreams#Public"

  @doc """
  Converts an AP object data to our internal data structure.
  """
  @impl Converter
  @spec as_to_model_data(map) :: map() | {:error, atom()}
  def as_to_model_data(object) do
    case maybe_fetch_actor_and_attributed_to_id(object) do
      {:ok, %Actor{id: actor_id}, attributed_to} ->
        address = get_address(object["location"])
        tags = fetch_tags(object["tag"])
        mentions = fetch_mentions(object["tag"])
        visibility = get_visibility(object)
        options = get_options(object, address)
        metadata = get_metdata(object)

        [description: description, picture_id: picture_id, medias: medias] =
          process_pictures(object, actor_id)

        %{
          title: object["name"],
          description: description,
          organizer_actor_id: actor_id,
          attributed_to_id: if(is_nil(attributed_to), do: nil, else: attributed_to.id),
          picture_id: picture_id,
          medias: medias,
          begins_on: object["startTime"],
          ends_on: object["endTime"],
          category: object["category"],
          visibility: visibility,
          join_options: Map.get(object, "joinMode", "free"),
          local: is_local(object["id"]),
          options: options,
          metadata: metadata,
          status: object |> Map.get("ical:status", "CONFIRMED") |> String.downcase(),
          online_address: object |> Map.get("attachment", []) |> get_online_address(),
          phone_address: object["phoneAddress"],
          draft: object["draft"] == true,
          url: object["id"],
          uuid: object["uuid"],
          tags: tags,
          mentions: mentions,
          physical_address_id: if(address, do: address.id, else: nil),
          updated_at: object["updated"],
          publish_at: object["published"],
          language: object["inLanguage"]
        }

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Convert an event struct to an ActivityStream representation.
  """
  @impl Converter
  @spec model_to_as(EventModel.t()) :: map
  def model_to_as(%EventModel{} = event) do
    {to, cc} =
      if event.visibility == :public,
        do: {[@ap_public], []},
        else: {[attributed_to_or_default(event).followers_url], [@ap_public]}

    %{
      "type" => "Event",
      "to" => to,
      "cc" => cc,
      "attributedTo" => attributed_to_or_default(event).url,
      "name" => event.title,
      "actor" =>
        if(Ecto.assoc_loaded?(event.organizer_actor), do: event.organizer_actor.url, else: nil),
      "uuid" => event.uuid,
      "category" => event.category,
      "content" => event.description,
      "published" => (event.publish_at || event.inserted_at) |> date_to_string(),
      "updated" => event.updated_at |> date_to_string(),
      "mediaType" => "text/html",
      "startTime" => event.begins_on |> shift_tz(event.options.timezone) |> date_to_string(),
      "joinMode" => to_string(event.join_options),
      "endTime" => event.ends_on |> shift_tz(event.options.timezone) |> date_to_string(),
      "tag" => event.tags |> build_tags(),
      "maximumAttendeeCapacity" => event.options.maximum_attendee_capacity,
      "repliesModerationOption" => event.options.comment_moderation,
      "commentsEnabled" => event.options.comment_moderation == :allow_all,
      "anonymousParticipationEnabled" => event.options.anonymous_participation,
      "attachment" => Enum.map(event.metadata, &EventMetadataConverter.metadata_to_as/1),
      "draft" => event.draft,
      "ical:status" => event.status |> to_string |> String.upcase(),
      "id" => event.url,
      "url" => event.url,
      "inLanguage" => event.language,
      "timezone" => event.options.timezone
    }
    |> maybe_add_physical_address(event)
    |> maybe_add_event_picture(event)
    |> maybe_add_online_address(event)
    |> maybe_add_inline_media(event)
  end

  @spec attributed_to_or_default(EventModel.t()) :: Actor.t()
  defp attributed_to_or_default(%EventModel{} = event) do
    if(is_nil(event.attributed_to) or not Ecto.assoc_loaded?(event.attributed_to),
      do: nil,
      else: event.attributed_to
    ) ||
      event.organizer_actor
  end

  # Get only elements that we have in EventOptions
  @spec get_options(map, Address.t() | nil) :: map
  defp get_options(object, address) do
    %{
      maximum_attendee_capacity: object["maximumAttendeeCapacity"],
      anonymous_participation: object["anonymousParticipationEnabled"],
      comment_moderation:
        Map.get(
          object,
          "repliesModerationOption",
          if(Map.get(object, "commentsEnabled", true), do: :allow_all, else: :closed)
        ),
      timezone: calculate_timezone(object, address)
    }
  end

  defp calculate_timezone(%{"timezone" => timezone}, %Address{geom: geom}) do
    TimezoneDetector.detect(
      timezone,
      geom,
      "Etc/UTC"
    )
  end

  defp calculate_timezone(_object, nil), do: nil

  defp calculate_timezone(_object, %Address{geom: geom}) do
    TimezoneDetector.detect(
      nil,
      geom,
      "Etc/UTC"
    )
  end

  defp get_metdata(%{"attachment" => attachments}) do
    attachments
    |> Enum.filter(&(&1["type"] == "PropertyValue"))
    |> Enum.map(&EventMetadataConverter.as_to_metadata/1)
  end

  defp get_metdata(_), do: []

  defp get_visibility(object), do: if(@ap_public in object["to"], do: :public, else: :unlisted)

  @spec date_to_string(DateTime.t() | nil) :: String.t()
  defp date_to_string(nil), do: nil
  defp date_to_string(%DateTime{} = date), do: DateTime.to_iso8601(date)

  @spec shift_tz(DateTime.t(), String.t() | nil) :: DateTime.t()
  defp shift_tz(%DateTime{} = date, timezone) when is_binary(timezone) do
    DateTime.shift_zone!(date, timezone)
  end

  defp shift_tz(datetime, _tz), do: datetime

  defp get_online_address(attachments) do
    Enum.find_value(attachments, fn attachment ->
      case attachment do
        %{
          "type" => "Link",
          "href" => url,
          "mediaType" => "text/html",
          "name" => @online_address_name
        } ->
          url

        _ ->
          nil
      end
    end)
  end

  @spec maybe_add_physical_address(map(), EventModel.t()) :: map()
  defp maybe_add_physical_address(res, %EventModel{
         physical_address: %Address{} = physical_address
       }) do
    Map.put(res, "location", AddressConverter.model_to_as(physical_address))
  end

  defp maybe_add_physical_address(res, %EventModel{physical_address: _}), do: res

  @spec maybe_add_event_picture(map(), EventModel.t()) :: map()
  defp maybe_add_event_picture(res, %EventModel{picture: %Media{} = picture}) do
    Map.update(
      res,
      "attachment",
      [],
      &(&1 ++
          [
            picture
            |> MediaConverter.model_to_as()
            |> Map.put("name", @banner_picture_name)
          ])
    )
  end

  defp maybe_add_event_picture(res, %EventModel{picture: _}), do: res

  @spec maybe_add_online_address(map(), EventModel.t()) :: map()
  defp maybe_add_online_address(res, %EventModel{online_address: online_address})
       when is_binary(online_address) do
    Map.update(
      res,
      "attachment",
      [],
      &(&1 ++
          [
            %{
              "type" => "Link",
              "href" => online_address,
              "mediaType" => "text/html",
              "name" => @online_address_name
            }
          ])
    )
  end

  defp maybe_add_online_address(res, %EventModel{online_address: _}), do: res

  @spec maybe_add_inline_media(map(), EventModel.t()) :: map()
  defp maybe_add_inline_media(res, %EventModel{media: media}) do
    medias = Enum.map(media, &MediaConverter.model_to_as/1)

    Map.update(
      res,
      "attachment",
      [],
      &(&1 ++ medias)
    )
  end

  defp is_local(url) do
    %URI{host: url_domain} = URI.parse(url)
    %URI{host: local_domain} = URI.parse(Endpoint.url())
    url_domain == local_domain
  end
end
