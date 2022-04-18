# Portions of this file are derived from Pleroma:
# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Service.RichMedia.Parser do
  @moduledoc """
  Module to parse data in HTML pages
  """
  @options [
    max_body: 2_000_000,
    timeout: 10_000,
    recv_timeout: 20_000,
    follow_redirect: true,
    # TODO: Remove me once Hackney/HTTPoison fixes their issue with TLS1.3 and OTP 23
    ssl: [{:versions, [:"tlsv1.2"]}]
  ]

  alias Mobilizon.Config
  alias Mobilizon.Service.HTTP.RichMediaPreviewClient
  alias Mobilizon.Service.RichMedia.Favicon
  alias Mobilizon.Service.RichMedia.Parsers.Fallback
  alias Plug.Conn.Utils
  require Logger

  defp parsers do
    Mobilizon.Config.get([:rich_media, :parsers])
  end

  def parse(nil), do: {:error, "No URL provided"}

  @spec parse(String.t()) :: {:ok, map()} | {:error, any()}
  def parse(url) do
    case Cachex.fetch(:rich_media_cache, url, fn _ ->
           case parse_url(url) do
             {:ok, data} -> {:commit, data}
             {:error, err} -> {:ignore, err}
           end
         end) do
      {status, value} when status in [:ok, :commit] ->
        {:ok, value}

      {_, err} ->
        {:error, err}
    end
  rescue
    e ->
      {:error, "Cachex error: #{inspect(e)}"}
  end

  @doc """
  Get a filename for the fetched data, using the response header or the last part of the URL
  """
  @spec get_filename_from_response(Enum.t(), String.t()) :: String.t() | nil
  def get_filename_from_response(response_headers, url) do
    get_filename_from_headers(response_headers) || get_filename_from_url(url)
  end

  @spec parse_url(String.t(), Enum.t()) :: {:ok, map()} | {:error, any()}
  defp parse_url(url, options \\ []) do
    user_agent = Keyword.get(options, :user_agent, default_user_agent(url))
    headers = [{"User-Agent", user_agent}]
    Logger.debug("Fetching content at address #{inspect(url)}")

    try do
      with {:ok, _} <- prevent_local_address(url),
           {:ok, %{body: body, status: code, headers: response_headers}}
           when code in 200..299 <-
             RichMediaPreviewClient.get(
               url,
               headers: headers,
               opts: @options
             ),
           {:is_html, _response_headers, true} <-
             {:is_html, response_headers, is_html(response_headers)} do
        body
        |> convert_utf8(response_headers)
        |> maybe_parse()
        |> Map.put(:url, url)
        |> maybe_add_favicon()
        |> clean_parsed_data()
        |> check_parsed_data(body)
        |> check_remote_picture_path()
      else
        {:is_html, response_headers, false} ->
          data = get_data_for_media(response_headers, url)

          {:ok, data}

        {:ok, err} ->
          Logger.debug("HTTP error: #{inspect(err)}")
          {:error, "HTTP error: #{inspect(err)}"}

        {:error, err} ->
          Logger.debug("HTTP error: #{inspect(err)}")
          {:error, "HTTP error: #{inspect(err)}"}
      end
    rescue
      e ->
        {:error, "Parsing error: #{inspect(e)} #{inspect(__STACKTRACE__)}"}
    end
  end

  @spec get_data_for_media(Enum.t(), String.t()) :: map()
  defp get_data_for_media(response_headers, url) do
    data = %{title: get_filename_from_headers(response_headers) || get_filename_from_url(url)}

    if is_image(response_headers) do
      Map.put(data, :image_remote_url, url)
    else
      data
    end
  end

  @spec is_html(Enum.t()) :: boolean
  def is_html(headers) do
    headers
    |> get_header("Content-Type")
    |> content_type_header_matches(["text/html", "application/xhtml"])
  end

  @spec is_image(Enum.t()) :: boolean
  defp is_image(headers) do
    headers
    |> get_header("Content-Type")
    |> content_type_header_matches(["image/"])
  end

  @spec content_type_header_matches(String.t() | nil, Enum.t()) :: boolean
  defp content_type_header_matches(header, content_types)
  defp content_type_header_matches(nil, _content_types), do: false

  defp content_type_header_matches(header, content_types) when is_binary(header) do
    Enum.any?(content_types, fn content_type -> String.starts_with?(header, content_type) end)
  end

  @spec get_header(Enum.t(), String.t()) :: String.t() | nil
  defp get_header(headers, key) do
    key = String.downcase(key)

    case List.keyfind(headers, key, 0) do
      {^key, value} -> String.downcase(value)
      nil -> nil
    end
  end

  @spec get_filename_from_headers(Enum.t()) :: String.t() | nil
  defp get_filename_from_headers(headers) do
    case get_header(headers, "Content-Disposition") do
      nil -> nil
      content_disposition -> parse_content_disposition(content_disposition)
    end
  end

  @spec get_filename_from_url(String.t()) :: String.t()
  defp get_filename_from_url(url) do
    case URI.parse(url) do
      %URI{path: nil} ->
        nil

      %URI{path: path} ->
        path
        |> String.split("/", trim: true)
        |> Enum.at(-1)
        |> URI.decode()
    end
  end

  # The following is taken from https://github.com/elixir-plug/plug/blob/65986ad32f9aaae3be50dc80cbdd19b326578da7/lib/plug/parsers/multipart.ex#L207
  @spec parse_content_disposition(String.t()) :: String.t() | nil
  defp parse_content_disposition(disposition) do
    with [_, params] <- :binary.split(disposition, ";"),
         %{"name" => _name} = params <- Utils.params(params) do
      handle_disposition(params)
    else
      _ -> nil
    end
  end

  @spec handle_disposition(map()) :: String.t() | nil
  defp handle_disposition(params) do
    case params do
      %{"filename" => ""} ->
        nil

      %{"filename" => filename} ->
        filename

      %{"filename*" => ""} ->
        nil

      %{"filename*" => "utf-8''" <> filename} ->
        URI.decode(filename)

      _ ->
        nil
    end
  end

  @spec maybe_parse(String.t()) :: map()
  defp maybe_parse(html) do
    Enum.reduce_while(parsers(), %{}, fn parser, acc ->
      Logger.debug("Using #{inspect(parser)} to parse link")

      case parser.parse(html, acc) do
        {:ok, data} ->
          {:halt, data}

        {:error, _msg} ->
          {:cont, acc}
      end
    end)
  end

  defp check_parsed_data(data, html, first_run \\ true)

  defp check_parsed_data(%{title: title} = data, _html, _first_run)
       when is_binary(title) and byte_size(title) > 0 do
    data
  end

  defp check_parsed_data(data, html, first_run) do
    # Maybe the first data found is incomplete, pass it through the Fallback parser once again
    if first_run do
      {:ok, data} = Fallback.parse(html, data)
      Logger.debug("check parsed data")
      Logger.debug(inspect(data))
      check_parsed_data(data, html, false)
    else
      Logger.debug("Found metadata was invalid or incomplete: #{inspect(data)}")
      {:error, :invalid_parsed_data}
    end
  end

  defp clean_parsed_data(data) do
    data
    |> Enum.reject(fn {key, val} ->
      case Jason.encode(%{key => val}) do
        {:ok, _} -> false
        _ -> true
      end
    end)
    |> Map.new()
  end

  defp prevent_local_address(url) do
    case URI.parse(url) do
      %URI{host: host} when not is_nil(host) ->
        host = String.downcase(host)

        if validate_hostname_not_localhost(host) && validate_hostname_only(host) &&
             validate_ip(host) do
          {:ok, url}
        else
          {:error, "Host violates local access rules"}
        end

      _ ->
        {:error, "Could not detect any host"}
    end
  end

  defp validate_hostname_not_localhost(hostname),
    do:
      hostname != "localhost" && !String.ends_with?(hostname, ".local") &&
        !String.ends_with?(hostname, ".localhost")

  defp validate_hostname_only(hostname),
    do: hostname |> String.graphemes() |> Enum.count(&(&1 == ".")) > 0

  defp validate_ip(hostname) do
    case hostname |> String.to_charlist() |> :inet.parse_address() do
      {:ok, address} ->
        !IpReserved.is_reserved?(address)

      # Not a valid IP
      {:error, _} ->
        true
    end
  end

  @spec maybe_add_favicon(map()) :: map()
  defp maybe_add_favicon(%{url: url} = data) do
    case Favicon.fetch(url) do
      {:ok, favicon_url} ->
        Logger.debug("Adding favicon #{favicon_url} to metadata")
        Map.put(data, :favicon_url, favicon_url)

      err ->
        Logger.debug("Failed to add favicon to metadata")
        Logger.debug(inspect(err))
        data
    end
  end

  @spec check_remote_picture_path(map()) :: {:ok, map()}
  defp check_remote_picture_path(%{image_remote_url: image_remote_url, url: url} = data)
       when is_binary(image_remote_url) and is_binary(url) do
    Logger.debug("Checking image_remote_url #{image_remote_url}")

    data = Map.put(data, :image_remote_url, format_url(url, image_remote_url))
    {:ok, data}
  end

  defp check_remote_picture_path(data), do: {:ok, data}

  @spec format_url(String.t(), String.t()) :: String.t()
  defp format_url(url, path) do
    url
    |> URI.parse()
    |> URI.merge(path)
    |> to_string()
  end

  # Twitter requires a well-know crawler user-agent to show server-rendered data
  defp default_user_agent("https://twitter.com/" <> _) do
    Config.instance_user_agent() <> " (compatible; bot)"
  end

  defp default_user_agent("https://mobile.twitter.com/" <> _) do
    Config.instance_user_agent() <> " (compatible; bot)"
  end

  defp default_user_agent(_url) do
    Config.instance_user_agent()
  end

  defp convert_utf8(body, headers) do
    headers
    |> get_header("Content-Type")
    |> handle_charset(body)
  end

  defp handle_charset(nil, body) do
    case detect_charset_from_meta(body) do
      "" -> body
      nil -> body
      charset -> convert_body(body, charset)
    end
  end

  defp handle_charset(content_type, body) do
    case charset_from_content_type(content_type) do
      nil -> handle_charset(nil, body)
      charset -> convert_body(body, charset)
    end
  end

  defp charset_from_content_type(content_type) do
    with [_, params] <- :binary.split(content_type, ";"),
         %{"charset" => charset} <- Utils.params(params) do
      charset
    else
      _ -> nil
    end
  end

  defp detect_charset_from_meta(body) do
    Logger.debug("Trying to detect charset from meta")

    document = Floki.parse_document!(body)

    case document
         |> Floki.find("meta[http-equiv=\"content-type\"]")
         |> List.first() do
      nil ->
        case document
             |> Floki.find("meta[http-equiv=\"Content-Type\"]")
             |> List.first() do
          nil -> nil
          meta -> content_type_from_meta(meta)
        end

      meta ->
        content_type_from_meta(meta)
    end
  end

  defp content_type_from_meta(meta) do
    Logger.debug("Finding content-type into <meta> element")

    meta
    |> Floki.attribute("content")
    |> List.first()
    |> String.trim()
    |> charset_from_content_type()
  end

  defp convert_body(body, "utf-8"), do: body

  defp convert_body(body, charset) do
    Logger.debug("Converting body from #{charset}")
    Codepagex.to_string!(body, fix_charset(charset))
  end

  defp fix_charset("windows-1252"), do: :"VENDORS/MICSFT/WINDOWS/CP1252"

  defp fix_charset(charset) do
    String.replace(charset, "-", "_")
  end
end
