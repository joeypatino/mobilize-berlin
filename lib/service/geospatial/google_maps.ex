defmodule Mobilizon.Service.Geospatial.GoogleMaps do
  @moduledoc """
  Google Maps [Geocoding service](https://developers.google.com/maps/documentation/geocoding/intro). Only works with addresses.

  Note: Endpoint is hardcoded to Google Maps API.
  """

  alias Mobilizon.Addresses.Address
  alias Mobilizon.Service.Geospatial.Provider
  alias Mobilizon.Service.HTTP.GeospatialClient

  require Logger

  @behaviour Provider

  @components [
    "street_number",
    "route",
    "locality",
    "administrative_area_level_1",
    "country",
    "postal_code"
  ]

  @api_key_missing_message "API Key required to use Google Maps"

  @geocode_endpoint "https://maps.googleapis.com/maps/api/geocode/json"
  @details_endpoint "https://maps.googleapis.com/maps/api/place/details/json"

  @impl Provider
  @doc """
  Google Maps implementation for `c:Mobilizon.Service.Geospatial.Provider.geocode/3`.
  """
  @spec geocode(float(), float(), keyword()) :: list(Address.t())
  def geocode(lon, lat, options \\ []) do
    url = build_url(:geocode, %{lon: lon, lat: lat}, options)

    Logger.debug("Asking Google Maps for reverse geocode with #{url}")

    %Tesla.Env{status: 200, body: body} = GeospatialClient.get!(url)

    case body do
      %{"results" => results, "status" => "OK"} ->
        Enum.map(results, &process_data(&1, options))

      %{"status" => "REQUEST_DENIED", "error_message" => error_message} ->
        raise ArgumentError, message: to_string(error_message)
    end
  end

  @impl Provider
  @doc """
  Google Maps implementation for `c:Mobilizon.Service.Geospatial.Provider.search/2`.
  """
  @spec search(String.t(), keyword()) :: list(Address.t())
  def search(q, options \\ []) do
    url = build_url(:search, %{q: q}, options)

    Logger.debug("Asking Google Maps for addresses with #{url}")

    %Tesla.Env{status: 200, body: body} = GeospatialClient.get!(url)

    case body do
      %{"results" => results, "status" => "OK"} ->
        results |> Enum.map(fn entry -> process_data(entry, options) end)

      %{"status" => "REQUEST_DENIED", "error_message" => error_message} ->
        raise ArgumentError, message: to_string(error_message)

      %{"results" => [], "status" => "ZERO_RESULTS"} ->
        []
    end
  end

  @spec build_url(:search | :geocode | :place_details, map(), list()) :: String.t() | no_return
  defp build_url(method, args, options) do
    limit = Keyword.get(options, :limit, 10)
    lang = Keyword.get(options, :lang, "en")
    api_key = Keyword.get(options, :api_key, api_key())
    if is_nil(api_key), do: raise(ArgumentError, message: @api_key_missing_message)

    url = "#{@geocode_endpoint}?limit=#{limit}&key=#{api_key}&language=#{lang}"

    uri =
      case method do
        :search ->
          "#{url}&address=#{args.q}"
          |> add_parameter(options, :type)

        :geocode ->
          zoom = Keyword.get(options, :zoom, 15)

          result_type = if zoom >= 15, do: "street_address", else: "locality"

          url <> "&latlng=#{args.lat},#{args.lon}&result_type=#{result_type}"

        :place_details ->
          "#{@details_endpoint}?key=#{api_key}&placeid=#{args.place_id}"
      end

    URI.encode(uri)
  end

  @spec process_data(map(), Keyword.t()) :: Address.t()
  defp process_data(
         %{
           "formatted_address" => description,
           "geometry" => %{"location" => %{"lat" => lat, "lng" => lon}},
           "address_components" => components,
           "place_id" => place_id
         },
         options
       ) do
    components =
      @components
      |> Enum.reduce(%{}, fn component, acc ->
        Map.put(acc, component, extract_component(components, component))
      end)

    description =
      if Keyword.get(options, :fetch_place_details, fetch_place_details()) == true do
        do_fetch_place_details(place_id, options) || description
      else
        description
      end

    coordinates = Provider.coordinates([lon, lat])

    %Address{
      country: Map.get(components, "country"),
      locality: Map.get(components, "locality"),
      region: Map.get(components, "administrative_area_level_1"),
      description: description,
      geom: coordinates,
      timezone: Provider.timezone(coordinates),
      postal_code: Map.get(components, "postal_code"),
      street: street_address(components),
      origin_id: "gm:" <> to_string(place_id)
    }
  end

  defp extract_component(components, key) do
    case components
         |> Enum.filter(fn component -> key in component["types"] end)
         |> Enum.map(& &1["long_name"]) do
      [] -> nil
      component -> hd(component)
    end
  end

  defp street_address(body) do
    if Map.has_key?(body, "street_number") && !is_nil(Map.get(body, "street_number")) do
      Map.get(body, "street_number") <> " " <> Map.get(body, "route")
    else
      Map.get(body, "route")
    end
  end

  @spec do_fetch_place_details(String.t() | nil, Keyword.t()) :: String.t() | nil
  defp do_fetch_place_details(place_id, options) do
    url = build_url(:place_details, %{place_id: place_id}, options)

    Logger.debug("Asking Google Maps for details with #{url}")

    %Tesla.Env{status: 200, body: body} = GeospatialClient.get!(url)

    case body do
      %{"result" => %{"name" => name}, "status" => "OK"} ->
        name

      %{"status" => "REQUEST_DENIED", "error_message" => error_message} ->
        raise ArgumentError, message: to_string(error_message)

      %{"status" => "INVALID_REQUEST"} ->
        raise ArgumentError, message: "Invalid Request"

      %{"results" => [], "status" => "ZERO_RESULTS"} ->
        nil
    end
  end

  @spec add_parameter(String.t(), Keyword.t(), atom()) :: String.t()
  defp add_parameter(url, options, key, default \\ nil) do
    value = Keyword.get(options, key, default)

    if is_nil(value), do: url, else: do_add_parameter(url, key, value)
  end

  @spec do_add_parameter(String.t(), atom(), any()) :: String.t()
  defp do_add_parameter(url, :type, :administrative),
    do: "#{url}&components=administrative_area"

  defp do_add_parameter(url, :type, _), do: url

  defp api_key do
    Application.get_env(:mobilizon, __MODULE__) |> get_in([:api_key])
  end

  defp fetch_place_details do
    (Application.get_env(:mobilizon, __MODULE__)
     |> get_in([:fetch_place_details])) in [true, "true", "True"]
  end
end
