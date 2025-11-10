defmodule PrettycoreWeb.Router do
  use PrettycoreWeb, :router

  # Navegador (para LiveView o vistas HTML)
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PrettycoreWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # API (solo JSON)
  pipeline :api do
    plug :accepts, ["json"]
  end

  # Interfaz Login
scope "/ui", PrettycoreWeb do
  pipe_through :browser

  live "/login", LoginLive
  live "/platform", Inicio
  live "/programacion", Programacion
  live "/programacion/sql", HerramientaSql
  live "/workorder", WorkOrder
end

scope "/ui", PrettycoreWeb do
  pipe_through :browser
  live "/sys_udn", SysUdnLive
end

  # Interfaz visual tipo Excel
  scope "/ui", PrettycoreWeb do
    pipe_through :browser
    live "/sys_udn", SysUdnLive
  end

    # Interfaz visual tipo Excel
  scope "/ui", PrettycoreWeb do
    pipe_through :browser
    live "/sys_udn", SysUdnLive
  end


  # Health simple en raíz
  scope "/", PrettycoreWeb do
    pipe_through :api
    get "/", HealthController, :index
  end

  # Endpoints JSON
  scope "/api", PrettycoreWeb do
    pipe_through :api

    get "/sys_udn", SysUdnController, :index
    get "/sys_udn/codigos", SysUdnController, :codigos
  end
end
