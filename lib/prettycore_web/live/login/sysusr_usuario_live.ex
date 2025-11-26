# lib/prettycore_web/live/login_live.ex
defmodule PrettycoreWeb.LoginLive do
  use PrettycoreWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:username, "")
     |> assign(:password, "")
     |> assign(:error, nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="pc-login-wrap">
      <div class="pc-login-card">
        <div class="pc-login-header">
          <.header>
            Iniciar sesión
            <:subtitle>
              Accede al sistema
            </:subtitle>
          </.header>
        </div>

        <%= if Phoenix.Flash.get(@flash, :error) do %>
          <div class="pc-error">{Phoenix.Flash.get(@flash, :error)}</div>
        <% end %>

        <form class="pc-login-form" action={~p"/"} method="post">
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

          <.input
            type="text"
            id="username"
            name="username"
            label="Usuario (correo)"
            value={@username}
            class="pc-input"
          />

          <.input
            type="password"
            id="password"
            name="password"
            label="Contraseña"
            value={@password}
            class="pc-input"
          />

          <.button type="submit" class="pc-btn pc-btn-primary pc-btn-full">
            Entrar
          </.button>

          <div class="pc-login-footer">
            <.link navigate={~p"/password-reset"} class="pc-link">¿Olvidaste tu contraseña?</.link>
          </div>
        </form>
      </div>
    </div>
    """
  end
end
