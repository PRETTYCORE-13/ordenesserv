defmodule PrettycoreWeb.Programacion do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.PlatformLayout

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "programacion")
     |> assign(:sidebar_open, true)             # estado inicial
     |> assign(:show_programacion_children, true)}
  end

  ## Navegación + toggle sidebar

  # Toggle del menú
  def handle_event("change_page", %{"id" => "toggle_sidebar"}, socket) do
    {:noreply, update(socket, :sidebar_open, fn open -> not open end)}
  end

  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/platform")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    {:noreply, socket} # ya estás aquí
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql")}
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/admin/workorder")}
  end

  # Catch-all
  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <.platform_shell
      current_page={@current_page}
      show_programacion_children={@show_programacion_children}
      sidebar_open={@sidebar_open}
    >
      <section>
        <header class="pc-page-header">
          <h1>Programación</h1>
          <p>Sección general de programación. Aquí luego metemos más módulos.</p>
        </header>

        <div class="pc-page-card">
          <h2>Programación</h2>
          <p>Página base de Programación, en blanco por ahora.</p>
        </div>
      </section>
    </.platform_shell>
    """
  end
end
