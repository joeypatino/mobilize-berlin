defmodule Mobilizon.Web.Endpoint do
  @moduledoc """
  Endpoint for Mobilizon app
  """

  if Application.fetch_env!(:mobilizon, :env) !== :test &&
       Application.get_env(:sentry, :dsn) != nil do
    use Sentry.PlugCapture
  end

  use Phoenix.Endpoint, otp_app: :mobilizon
  use Absinthe.Phoenix.Endpoint

  plug(Mobilizon.Web.Plugs.DetectLocalePlug)

  if Application.fetch_env!(:mobilizon, :env) !== :dev do
    plug(Mobilizon.Web.Plugs.HTTPSecurityPlug)
  end

  # For e2e tests
  # if Application.get_env(:mobilizon, :sql_sandbox) do
  #   plug(Phoenix.Ecto.SQL.Sandbox,
  #     at: "/sandbox",
  #     header: "x-session-id",
  #     repo: Mobilizon.Storage.Repo
  #   )
  # end

  socket("/graphql_socket", Mobilizon.Web.GraphQLSocket,
    websocket: true,
    longpoll: false
  )

  endpoint_config = Application.get_env(:mobilizon, Mobilizon.Web.Endpoint)

  if Keyword.get(endpoint_config, :has_reverse_proxy, false) == true do
    plug(RemoteIp)
  end

  plug(Mobilizon.Web.Plugs.UploadedMedia)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: {:mobilizon, "priv/static"},
    gzip: false,
    only: ~w(index.html manifest.json service-worker.js css fonts img js favicon.ico robots.txt),
    only_matching: ["precache-manifest"]
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(CORSPlug)
  plug(Plug.RequestId)
  plug(Plug.Logger)

  upload_limit =
    Keyword.get(Application.get_env(:mobilizon, :instance, []), :upload_limit, 10_485_760)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, {:multipart, length: upload_limit}, :json, Absinthe.Plug.Parser],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Mobilizon.Web.Router)

  @spec websocket_url :: String.t()
  def websocket_url do
    String.replace_leading(url(), "http", "ws")
  end

  if Application.fetch_env!(:mobilizon, :env) !== :test &&
       Application.get_env(:sentry, :dsn) != nil do
    plug(Sentry.PlugContext)
  end
end
