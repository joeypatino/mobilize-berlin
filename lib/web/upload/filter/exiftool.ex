# Pleroma: A lightweight social networking server
# Copyright © 2017-2020 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mobilizon.Web.Upload.Filter.Exiftool do
  @moduledoc """
  Strips GPS related EXIF tags and overwrites the file in place.
  Also strips or replaces filesystem metadata e.g., timestamps.
  """
  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Filter

  @behaviour Filter

  @spec filter(Upload.t()) :: {:ok, :filtered | :noop} | {:error, String.t()}

  # webp is not compatible with exiftool at this time
  @impl Filter
  def filter(%Upload{content_type: "image/webp"}), do: {:ok, :noop}

  def filter(%Upload{tempfile: file, content_type: "image" <> _}) do
    case System.cmd("exiftool", ["-overwrite_original", "-gps:all=", file], parallelism: true) do
      {_response, 0} -> {:ok, :filtered}
      {error, 1} -> {:error, error}
    end
  rescue
    _e in ErlangError ->
      {:error, "exiftool command not found"}
  end

  def filter(_), do: {:ok, :noop}
end
