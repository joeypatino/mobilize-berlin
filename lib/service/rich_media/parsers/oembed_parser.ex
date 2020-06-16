# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.RichMedia.Parsers.OEmbed do
  @moduledoc """
  Module to parse OEmbed data in HTML pages
  """
  alias Mobilizon.Service.Formatter.HTML
  require Logger

  @http_options [
    follow_redirect: true,
    ssl: [{:versions, [:"tlsv1.2"]}]
  ]

  def parse(html, _data) do
    Logger.debug("Using OEmbed parser")

    with elements = [_ | _] <- get_discovery_data(html),
         {:ok, oembed_url} <- get_oembed_url(elements),
         {:ok, oembed_data} <- get_oembed_data(oembed_url),
         oembed_data <- filter_oembed_data(oembed_data) do
      Logger.debug("Data found with OEmbed parser")
      Logger.debug(inspect(oembed_data))
      {:ok, oembed_data}
    else
      _e ->
        {:error, "No OEmbed data found"}
    end
  end

  defp get_discovery_data(html) do
    html |> Floki.find("link[type='application/json+oembed']")
  end

  defp get_oembed_url(nodes) do
    {"link", attributes, _children} = nodes |> hd()

    {:ok, Enum.into(attributes, %{})["href"]}
  end

  defp get_oembed_data(url) do
    with {:ok, %HTTPoison.Response{body: json}} <- HTTPoison.get(url, [], @http_options),
         {:ok, data} <- Jason.decode(json),
         data <- data |> Map.new(fn {k, v} -> {String.to_atom(k), v} end) do
      {:ok, data}
    end
  end

  defp filter_oembed_data(data) do
    case Map.get(data, :type) do
      nil ->
        {:error, "No type declared for OEmbed data"}

      "link" ->
        Map.put(data, :image_remote_url, Map.get(data, :thumbnail_url))

      "photo" ->
        if Map.get(data, :url, "") == "" do
          {:error, "No URL for photo OEmbed data"}
        else
          data
          |> Map.put(:image_remote_url, Map.get(data, :url))
          |> Map.put(:width, Map.get(data, :width, 0))
          |> Map.put(:height, Map.get(data, :height, 0))
        end

      "video" ->
        {:ok, html} = data |> Map.get(:html, "") |> HTML.filter_tags_for_oembed()

        data
        |> Map.put(:html, html)
        |> Map.put(:width, Map.get(data, :width, 0))
        |> Map.put(:height, Map.get(data, :height, 0))
        |> Map.put(:image_remote_url, Map.get(data, :thumbnail_url))

      "rich" ->
        {:error, "OEmbed data has rich type, which we don't support"}
    end
  end
end