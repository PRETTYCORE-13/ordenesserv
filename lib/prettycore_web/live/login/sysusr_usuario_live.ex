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

  # Evento cuando envían el formulario
def handle_event("login", %{"username" => user, "password" => pass}, socket) do
  case Auth.authenticate(user, pass) do
    {:ok, _user} ->
      {:noreply,
       socket
       |> assign(:error, nil)
       |> push_redirect(to: ~p"/ui/platform")}

    {:error, :invalid_credentials} ->
      {:noreply,
       socket
       |> assign(:error, "Usuario o contraseña incorrectos")}
  end
end

  def render(assigns) do
    ~H"""
    <div class="pc-login-wrap">
      <div class="pc-login-card">
        <div class="pc-login-header">
          <h1>Iniciar sesión</h1>
          <p>Accede al sistema</p>
        </div>

        <%= if @error do %>
          <div class="pc-error">
            <%= @error %>
          </div>
        <% end %>

        <.form class="pc-login-form" action="/ui/login" method="post">
          <div class="pc-field">
            <label for="username">Usuario</label>
            <input
              id="username"
              name="username"
              class="pc-input"
              placeholder="Ingresa tu usuario"
              value={@username}
            />
          </div>

          <div class="pc-field">
            <label for="password">Contraseña</label>
            <input
              id="password"
              name="password"
              type="password"
              class="pc-input"
              placeholder="Ingresa tu contraseña"
              value={@password}
            />
          </div>

          <button type="submit" class="pc-btn pc-btn-primary pc-btn-full">
            Entrar
          </button>
        </.form>
      </div>
    </div>
    """
  end
end
