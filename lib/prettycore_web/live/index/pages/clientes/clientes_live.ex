defmodule PrettycoreWeb.Clientes do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout
  alias Prettycore.Clientes

  # Recibimos el :email desde la ruta /admin/clientes
  def mount(_params, session, socket) do
    current_path = "/admin/clientes"

    # Parámetros por defecto para la consulta
    sysudn_codigo_k = "100"  # TODO: obtener de usuario/sesión
    vtarut_codigo_k_ini = "001"
    vtarut_codigo_k_fin = "999"

    # Cargar clientes con manejo de errores
    {clientes, error} =
      try do
        clientes = Clientes.list_clientes_resumen(sysudn_codigo_k, vtarut_codigo_k_ini, vtarut_codigo_k_fin)
        {clientes, nil}
      rescue
        e ->
          require Logger
          Logger.error("Error cargando clientes: #{inspect(e)}")
          {[], "Error al cargar clientes. Por favor intenta de nuevo."}
      end

    {:ok,
     socket
     |> assign(:current_page, "clientes")
     |> assign(:sidebar_open, true)
     |> assign(:show_programacion_children, false)
     |> assign(:current_user_email, session["user_email"])
     |> assign(:current_path, current_path)
     |> assign(:clientes, clientes)
     |> assign(:loading, false)
     |> assign(:error, error)}
  end

  ## Navegación centralizada con CASE (modelo recomendado)
  @impl true
  def handle_event("change_page", %{"id" => id}, socket) do
    email = socket.assigns.current_user_email

    case id do
      "toggle_sidebar" ->
        {:noreply, update(socket, :sidebar_open, &(not &1))}

      "inicio" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/platform")}

      "programacion" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/programacion")}

      "programacion_sql" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql")}

      "workorder" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/workorder")}

      "clientes" ->
        {:noreply, socket}  # ya estás aquí


      "config" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/configuracion")}
      _->
        {:noreply, socket}
    end
  end

  ## Render
  @impl true
  def render(assigns) do
    ~H"""
    <section class="wo-container">
      <header class="wo-header">
        <h1>Clientes</h1>
        <div class="wo-header-stats">
          <span class="wo-stat">
            <strong><%= length(@clientes) %></strong>
            clientes activos
          </span>
        </div>
      </header>

      <!-- Mensaje de error si existe -->
      <%= if @error do %>
        <div style="background: #fee2e2; border: 1px solid #fecaca; color: #991b1b; padding: 16px; border-radius: 8px; margin-bottom: 20px;">
          <strong>⚠ Error:</strong> <%= @error %>
        </div>
      <% end %>

      <!-- Tabla de clientes -->
      <div class="wo-table-container">
        <table class="wo-table">
          <thead>
            <tr>
              <th>Código</th>
              <th>Razón Social</th>
              <th>Nombre Comercial</th>
              <th>RFC</th>
              <th>Teléfono</th>
              <th>Estado</th>
              <th>Colonia</th>
              <th>Preventa</th>
              <th>Entrega</th>
              <th>Autoventa</th>
            </tr>
          </thead>
          <tbody>
            <%= if @loading do %>
              <tr>
                <td colspan="10" style="text-align: center; padding: 40px;">
                  Cargando clientes...
                </td>
              </tr>
            <% else %>
              <%= if Enum.empty?(@clientes) do %>
                <tr>
                  <td colspan="10" style="text-align: center; padding: 40px; color: #666;">
                    No se encontraron clientes con los filtros seleccionados
                  </td>
                </tr>
              <% else %>
                <%= for cliente <- @clientes do %>
                  <tr class="wo-row">
                    <td><%= cliente.codigo %></td>
                    <td><%= cliente.razon_social %></td>
                    <td><%= cliente.nombre_comercial %></td>
                    <td><%= cliente.rfc %></td>
                    <td><%= cliente.telefono %></td>
                    <td><%= cliente.estado %></td>
                    <td><%= cliente.colonia %></td>
                    <td><%= cliente.preventa %></td>
                    <td><%= cliente.entrega %></td>
                    <td><%= cliente.autoventa %></td>
                  </tr>
                <% end %>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>
    </section>
    """
  end
end
