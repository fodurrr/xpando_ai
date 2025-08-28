defmodule XpandoWebWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :xpando_web

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_xpando_web_key",
    signing_salt: "D6dKUUwS",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  socket "/socket", XpandoWebWeb.UserSocket,
    websocket: true,
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :xpando_web,
    gzip: false,
    only: XpandoWebWeb.static_paths()

  # Tidewave MCP server
  if Code.ensure_loaded?(Tidewave) do
    plug Tidewave
  end

  # Ash AI MCP Server
  if Code.ensure_loaded?(AshAi.Mcp.Dev) do
    plug AshAi.Mcp.Dev
  end

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket

    plug AshAi.Mcp.Dev,
      # see the note below on protocol versions below
      protocol_version_statement: "2024-11-05",
      otp_app: :xpando_web

    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug XpandoWebWeb.Router
end
