defmodule Mobilizon.Web.Upload.Filter.BlurHash do
  @moduledoc """
  Computes blurhash from the upload
  """
  require Logger
  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Filter

  @behaviour Filter

  @impl Filter
  @spec filter(Upload.t()) ::
          {:ok, :filtered, Upload.t()} | {:ok, :noop}
  def filter(%Upload{tempfile: file, content_type: "image" <> _} = upload) do
    {:ok, :filtered, %Upload{upload | blurhash: generate_blurhash(file)}}
  rescue
    e in ErlangError ->
      Logger.warn("#{__MODULE__}: #{inspect(e)}")
      {:ok, :noop}
  end

  def filter(_), do: {:ok, :noop}

  defp generate_blurhash(file) do
    case :eblurhash.magick(to_charlist(file)) do
      {:ok, blurhash} ->
        to_string(blurhash)

      _ ->
        nil
    end
  end
end
