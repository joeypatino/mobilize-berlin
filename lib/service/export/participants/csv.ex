defmodule Mobilizon.Service.Export.Participants.CSV do
  @moduledoc """
  Export a list of participants to CSV
  """

  alias Mobilizon.{Events, Export}
  alias Mobilizon.Events.Event
  alias Mobilizon.Storage.Repo
  alias Mobilizon.Web.Gettext
  import Mobilizon.Web.Gettext, only: [gettext: 2]

  import Mobilizon.Service.Export.Participants.Common,
    only: [
      save_upload: 5,
      columns: 0,
      to_list: 1,
      clean_exports: 2,
      export_enabled?: 1,
      export_path: 1
    ]

  @extension "csv"

  def extension do
    @extension
  end

  @spec export(Event.t(), Keyword.t()) ::
          {:ok, String.t()} | {:error, :failed_to_save_upload | :export_dependency_not_installed}
  def export(%Event{id: event_id} = event, options \\ []) do
    if ready?() do
      filename = "#{ShortUUID.encode!(Ecto.UUID.generate())}.csv"
      full_path = Path.join([export_path(@extension), filename])

      file = File.open!(full_path, [:write, :utf8])

      case Repo.transaction(
             fn ->
               event_id
               |> Events.participant_for_event_export_query(Keyword.get(options, :roles, []))
               |> Repo.stream()
               |> Stream.map(&to_list/1)
               |> NimbleCSV.RFC4180.dump_to_iodata()
               |> add_header_column()
               |> Stream.each(fn line -> IO.write(file, line) end)
               |> Stream.run()

               with {:error, err} <- save_csv_upload(full_path, filename, event) do
                 Repo.rollback(err)
               end
             end,
             timeout: :infinity
           ) do
        {:error, _err} ->
          File.rm!(full_path)
          {:error, :failed_to_save_upload}

        {:ok, _ok} ->
          {:ok, filename}
      end
    else
      {:error, :export_dependency_not_installed}
    end
  end

  defp add_header_column(stream) do
    Stream.concat([Enum.join(columns(), ","), "\n"], stream)
  end

  @spec save_csv_upload(String.t(), String.t(), Event.t()) ::
          {:ok, Export.t()} | {:error, atom() | Ecto.Changeset.t()}
  defp save_csv_upload(full_path, filename, %Event{id: event_id, title: title}) do
    Gettext.gettext_comment(
      "File name template for exported list of participants. Should NOT contain spaces. Make sure the output is going to be something standardized that is acceptable as a file name on most systems."
    )

    save_upload(
      full_path,
      filename,
      to_string(event_id),
      gettext("%{event}_participants", event: title) <> ".csv",
      "csv"
    )
  end

  @doc """
  Clean outdated files in export folder
  """
  @spec clean_exports :: :ok
  def clean_exports do
    clean_exports("csv", export_path(@extension))
  end

  @spec dependencies_ok? :: boolean
  def dependencies_ok? do
    true
  end

  @spec enabled? :: boolean
  def enabled? do
    export_enabled?(__MODULE__)
  end

  @spec ready? :: boolean
  def ready? do
    enabled?() && dependencies_ok?()
  end
end
