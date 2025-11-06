defmodule PrettycoreWeb.ProgrammingHomeLive do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.PlatformLayout

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "programacion")
     |> assign(:show_programacion_children, true)}
  end

  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/platform")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    {:noreply, socket} # ya estás aquí
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/programacion/sql")}
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
  {:noreply, push_navigate(socket, to: ~p"/ui/workorder")}
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
