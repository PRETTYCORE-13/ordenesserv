# lib/prettycore_web/live/login_live.ex
defmodule PrettycoreWeb.LoginLive do
  use PrettycoreWeb, :live_view

  alias Prettycore.Auth

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
          <h1>Iniciar sesión</h1>
          <p>Accede al sistema</p>
        </div>

        <%= if live_flash(@flash, :error) do %>
          <div class="pc-error"><%= live_flash(@flash, :error) %></div>
        <% end %>

        <form class="pc-login-form" action={~p"/"} method="post">
          <input type="hidden" name="_csrf_token" value={Plug.CSRFProtection.get_csrf_token()} />

          <div class="pc-field">
            <label for="username">Usuario</label>
            <input id="username" name="username" class="pc-input" value={@username} />
          </div>

          <div class="pc-field">
            <label for="password">Contraseña</label>
            <input id="password" name="password" type="password" class="pc-input" value={@password} />
          </div>

          <button type="submit" class="pc-btn pc-btn-primary pc-btn-full">Entrar</button>
        </form>
      </div>
    </div>
    """
  end
end
