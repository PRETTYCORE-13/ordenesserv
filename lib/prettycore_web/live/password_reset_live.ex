# apps/prettycore_web/lib/prettycore_web/live/password_reset_live.ex
defmodule PrettycoreWeb.PasswordResetLive do
  use PrettycoreWeb, :live_view
  alias Prettycore.Auth.PasswordReset

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:step, :request)
     # <- Cambiar de email a username
     |> assign(:username, "")
     |> assign(:code, "")
     |> assign(:new_password, "")
     |> assign(:confirm_password, "")
     |> assign(:message, nil)
     |> assign(:error, nil)
     |> assign(:loading, false)}
  end

  @impl true
  def handle_event("request_code", %{"username" => username}, socket) do
    socket = assign(socket, :loading, true)

    case PasswordReset.request_reset_by_username(username) do
      {:ok, message} ->
        {:noreply,
         socket
         |> assign(:step, :verify)
         # <- Guardar username
         |> assign(:username, username)
         |> assign(:message, message)
         |> assign(:error, nil)
         |> assign(:loading, false)}

      {:error, reason} ->
        {:noreply,
         socket
         # <- Cambiar inspect por to_string
         |> assign(:error, to_string(reason))
         |> assign(:message, nil)
         |> assign(:loading, false)}
    end
  end

  @impl true
  def handle_event(
        "verify_code",
        %{"code" => code, "new_password" => password, "confirm_password" => confirm},
        socket
      ) do
    socket = assign(socket, :loading, true)

    cond do
      password != confirm ->
        {:noreply, assign(socket, error: "Las contraseñas no coinciden", loading: false)}

      String.length(password) < 8 ->
        {:noreply,
         assign(socket, error: "La contraseña debe tener al menos 8 caracteres", loading: false)}

      true ->
        # Usar username en lugar de email
        case PasswordReset.verify_and_reset(socket.assigns.username, code, password) do
          {:ok, message} ->
            {:noreply,
             socket
             |> assign(:step, :success)
             |> assign(:message, message)
             |> assign(:error, nil)
             |> assign(:loading, false)}

          {:error, reason} ->
            {:noreply, assign(socket, error: to_string(reason), loading: false)}
        end
    end
  end

  @impl true
  def handle_event("back_to_request", _params, socket) do
    {:noreply,
     socket
     |> assign(:step, :request)
     |> assign(:code, "")
     |> assign(:new_password, "")
     |> assign(:confirm_password, "")
     |> assign(:message, nil)
     |> assign(:error, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="pc-login-wrap">
      <div class="pc-login-card">
        <div class="pc-login-header">
          <h1>Cambio de Contraseña</h1>
          
          <p>Recupera el acceso a tu cuenta</p>
        </div>
        
        <%= if @message do %>
          <div class="pc-success">{@message}</div>
        <% end %>
        
        <%= if @error do %>
          <div class="pc-error">{@error}</div>
        <% end %>
        
        <%= if @step == :request do %>
          <form id="request-form" phx-submit="request_code" class="pc-login-form">
            <div class="pc-field">
              <label for="username">Usuario</label>
              <input
                id="username"
                name="username"
                type="text"
                required
                class="pc-input"
              />
            </div>
            
            <button
              type="submit"
              disabled={@loading}
              class="pc-btn pc-btn-primary pc-btn-full"
            >
              {if @loading, do: "Enviando...", else: "Enviar código"}
            </button>
          </form>
        <% end %>
        
        <%= if @step == :verify do %>
          <form id="verify-form" phx-submit="verify_code" class="pc-login-form">
            <div class="pc-field">
              <label for="code">Código de verificación</label>
              <input
                id="code"
                name="code"
                type="text"
                value={@code}
                maxlength="6"
                required
                class="pc-input pc-input-code"
                placeholder="123456"
              />
              <p class="pc-field-hint">Revisa tu correo (usuario: {@username})</p>
            </div>
            
            <div class="pc-field">
              <label for="new_password">Nueva contraseña</label>
              <input
                id="new_password"
                name="new_password"
                type="password"
                minlength="8"
                required
                class="pc-input"
              />
            </div>
            
            <div class="pc-field">
              <label for="confirm_password">Confirmar contraseña</label>
              <input
                id="confirm_password"
                name="confirm_password"
                type="password"
                minlength="8"
                required
                class="pc-input"
              />
            </div>
            
            <div class="pc-btn-group">
              <button
                type="submit"
                disabled={@loading}
                class="pc-btn pc-btn-primary"
              >
                {if @loading, do: "Verificando...", else: "Cambiar contraseña"}
              </button>
              <button
                type="button"
                phx-click="back_to_request"
                class="pc-btn pc-btn-secondary"
              >
                Nuevo código
              </button>
            </div>
          </form>
        <% end %>
        
        <%= if @step == :success do %>
          <div class="pc-success-state">
            <div class="pc-success-icon">
              <svg fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
            </div>
            
            <h2>¡Contraseña actualizada!</h2>
            
            <p>Ya puedes iniciar sesión con tu nueva contraseña.</p>
             <.link navigate={~p"/"} class="pc-btn pc-btn-primary pc-btn-full">Ir a Login</.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
