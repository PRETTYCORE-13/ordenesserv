defmodule PrettycoreWeb.Inicio do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout

  # Recibimos el :email desde la ruta /admin/platform/:email
  def mount(%{"email" => email} = _params, _session, socket) do
    current_path = "/admin/platform/#{email}"

    {:ok,
     socket
     |> assign(:current_page, "inicio")
     |> assign(:sidebar_open, true)
     |> assign(:show_programacion_children, false)
     |> assign(:current_user_email, email)
     |> assign(:current_path, current_path)}
  end

  ## Navegación y toggle sidebar

  # 1) Toggle del menú
  def handle_event("change_page", %{"id" => "toggle_sidebar"}, socket) do
    {:noreply, update(socket, :sidebar_open, fn open -> not open end)}
  end

  # 2) Resto de navegación

  # Ir a Inicio (manteniendo el email en la URL)
  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    email = socket.assigns.current_user_email

    {:noreply,
     socket
     |> assign(:current_page, "inicio")
     |> assign(:show_programacion_children, false)
     |> push_navigate(to: ~p"/admin/platform/#{email}")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion/#{email}")}
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/workorder/#{email}")}
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql/#{email}")}
  end

  # 3) Catch-all
  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end

  ## Render

  def render(assigns) do
    ~H"""
      <section>
        <header class="pc-page-header">
          <h1>Inicio</h1>
          <p>Resumen general de tu espacio PrettyCore.</p>
          <p class="pc-small-muted">
            Correo actual: {@current_user_email} <br />
            URL actual: {@current_path}
          </p>
        </header>

        <div class="pc-page-grid">
          <div class="pc-page-card">
            <h2>Actividad reciente</h2>
            <p>Aquí puedes mostrar un resumen de lo último que pasó.</p>
          </div>

          <div class="pc-page-card">
            <h2>Accesos rápidos</h2>
            <p>Enlaces, dashboards o módulos frecuentes.</p>
          </div>
        </div>
      </section>
    """
  end
end
