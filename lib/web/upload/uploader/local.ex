# Portions of this file are derived from Pleroma:
# Copyright © 2017-2019 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/pleroma/uploaders/local.ex

defmodule Mobilizon.Web.Upload.Uploader.Local do
  @moduledoc """
  Local uploader for files
  """

  alias Mobilizon.Config
  alias Mobilizon.Web.Upload
  alias Mobilizon.Web.Upload.Uploader

  @behaviour Uploader

  @impl Uploader
  def get_file(_) do
    {:ok, {:static_dir, upload_path()}}
  end

  @impl Uploader
  @spec put_file(Upload.t()) ::
          :ok | {:ok, {:file, String.t()}} | {:error, :tempfile_no_longer_exists}
  def put_file(%Upload{path: initial_path, tempfile: tempfile}) do
    {path, file} = local_path(initial_path)
    result_file = Path.join(path, file)

    if File.exists?(result_file) do
      # If the resulting file already exists, it's because of the Dedupe filter
      :ok
    else
      if File.exists?(tempfile) do
        File.cp!(tempfile, result_file)
        {:ok, {:file, initial_path}}
      else
        {:error, :tempfile_no_longer_exists}
      end
    end
  end

  @impl Uploader
  @spec remove_file(String.t()) ::
          {:ok, {:file, String.t()}}
          | {:error, :folder_not_empty}
          | {:error, :enofile}
          | {:error, File.posix()}
  def remove_file(path) do
    {path, file} = local_path(path)
    full_path = Path.join(path, file)

    if File.exists?(full_path) do
      do_remove_file(path, full_path)
    else
      {:error, :enofile}
    end
  end

  @spec do_remove_file(String.t(), String.t()) ::
          {:ok, {:file, String.t()}}
          | {:error, :folder_not_empty}
          | {:error, File.posix()}
  defp do_remove_file(path, full_path) do
    case File.rm(full_path) do
      :ok ->
        case remove_folder(path) do
          :ok ->
            {:ok, {:file, path}}

          {:error, err} ->
            {:error, err}
        end

      {:error, err} ->
        {:error, err}
    end
  end

  @spec remove_folder(String.t()) :: :ok | {:error, :folder_not_empty} | {:error, File.posix()}
  defp remove_folder(path) do
    with {:subfolder, true} <- {:subfolder, path != upload_path()},
         {:empty_folder, {:ok, [] = _files}} <- {:empty_folder, File.ls(path)} do
      File.rmdir(path)
    else
      {:subfolder, _} -> :ok
      {:empty_folder, _} -> {:error, :folder_not_empty}
    end
  end

  @spec local_path(String.t()) :: {String.t(), String.t()}
  defp local_path(path) do
    case Enum.reverse(String.split(path, "/", trim: true)) do
      [file] ->
        {upload_path(), file}

      [file | folders] ->
        path = Path.join([upload_path()] ++ Enum.reverse(folders))
        File.mkdir_p!(path)
        {path, file}
    end
  end

  @spec upload_path :: String.t()
  def upload_path do
    Config.get!([__MODULE__, :uploads])
  end
end
