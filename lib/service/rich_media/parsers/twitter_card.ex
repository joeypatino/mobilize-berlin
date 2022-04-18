# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.RichMedia.Parsers.TwitterCard do
  @moduledoc """
  Module to parse Twitter tags data in HTML pages
  """
  alias Mobilizon.Service.RichMedia.Parsers.MetaTagsParser
  require Logger

  @twitter_card_properties [
    :card,
    :site,
    :creator,
    :title,
    :description,
    :image,
    :"image:alt"
  ]

  @spec parse(String.t(), map()) :: {:ok, map()} | {:error, String.t()}
  def parse(html, data) do
    Logger.debug("Using Twitter card parser")

    with {:ok, data} <- parse_name_attrs(data, html),
         {:ok, data} <- parse_property_attrs(data, html) do
      data = transform_tags(data)
      Logger.debug("Data found with Twitter card parser")
      Logger.debug(inspect(data))
      data
    end
  end

  @spec parse_name_attrs(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp parse_name_attrs(data, html) do
    MetaTagsParser.parse(
      html,
      data,
      "twitter",
      "No twitter card metadata found",
      :name,
      :content,
      [:"twitter:card"]
    )
  end

  @spec parse_property_attrs(map(), String.t()) :: {:ok, map()} | {:error, String.t()}
  defp parse_property_attrs(data, html) do
    MetaTagsParser.parse(
      html,
      data,
      "twitter",
      "No twitter card metadata found",
      :property,
      :content,
      @twitter_card_properties
    )
  end

  @spec transform_tags(map()) :: map()
  defp transform_tags(data) do
    data
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} -> {k, String.trim(v)} end)
    |> Map.new()
    |> Map.update(:image_remote_url, Map.get(data, :image), & &1)
  end
end
