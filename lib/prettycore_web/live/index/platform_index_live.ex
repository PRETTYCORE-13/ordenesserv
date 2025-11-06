defmodule PrettycoreWeb.PlatformIndexLive do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.PlatformLayout

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "inicio")
     |> assign(:show_programacion_children, false)}
  end

  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    {:noreply,
     socket
     |> assign(:current_page, "inicio")
     |> assign(:show_programacion_children, false)}
  end

  # Programación: navega directo a la página principal de programación
  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/programacion")}
  end

  # WorkOrder
  def handle_event("change_page", %{"id" => "workorder"}, socket) do
  {:noreply, push_navigate(socket, to: ~p"/ui/workorder")}
end


  # Desde Inicio, si clican el hijo (Herramienta SQL) también navega
  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/programacion/sql")}
  end

  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.platform_shell
      current_page={@current_page}
      show_programacion_children={@show_programacion_children}
    >
      <section>
        <header class="pc-page-header">
          <h1>Inicio</h1>
          <p>Resumen general de tu espacio PrettyCore.</p>
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
    </.platform_shell>
    """
  end
end
