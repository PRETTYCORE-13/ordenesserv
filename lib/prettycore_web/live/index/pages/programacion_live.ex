defmodule PrettycoreWeb.Programacion do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout

  # RECIBIR EL EMAIL DE LA RUTA /admin/programacion/:email
  def mount(%{"email" => email} = _params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "programacion")
     |> assign(:sidebar_open, true)
     |> assign(:show_programacion_children, true)
     |> assign(:current_user_email, email)
     |> assign(:current_path, "/admin/programacion/#{email}")}
  end

  ## Navegación + toggle sidebar

  # Toggle del menú
  def handle_event("change_page", %{"id" => "toggle_sidebar"}, socket) do
    {:noreply, update(socket, :sidebar_open, fn open -> not open end)}
  end

  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/platform/#{email}")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    # ya estás aquí
    {:noreply,
     socket
     |> assign(:current_page, "programacion")
     |> assign(:show_programacion_children, true)}
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql/#{email}")}
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/workorder/#{email}")}
  end

  # Catch-all
  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
      <section>
        <header class="pc-page-header">
          <h1>Programación</h1>
          <p>Sección general de programación. Aquí luego metemos más módulos.</p>
          <p class="pc-small-muted">
            Correo actual: {@current_user_email} <br />
            URL actual: {@current_path}
          </p>
        </header>

        <div class="pc-page-card">
          <h2>Programación</h2>
          <p>Página base de Programación, en blanco por ahora.</p>
        </div>
      </section>
    """
  end
end
