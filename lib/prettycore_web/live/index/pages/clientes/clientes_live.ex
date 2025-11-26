defmodule PrettycoreWeb.Clientes do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout
  alias Prettycore.Clientes

  # Recibimos el :email desde la ruta /admin/clientes
  @impl true
  def mount(_params, session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "clientes")
     |> assign(:sidebar_open, true)
     |> assign(:show_programacion_children, false)
     |> assign(:current_user_email, session["user_email"])
     |> assign(:current_path, "/admin/clientes")
     |> assign(:filters_open, false)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # Parsear visible_columns desde los params de la URL
    visible_columns_params =
      params
      |> Enum.filter(fn {key, _value} -> String.starts_with?(key, "visible_columns[") end)
      |> Enum.map(fn {key, value} ->
        column_name = String.replace(key, ~r/visible_columns\[(.*)\]/, "\\1")
        {column_name, value == "true"}
      end)
      |> Enum.into(%{})

    # Columnas visibles desde params o por defecto todas visibles
    default_visible_columns = %{
      "codigo" => true,
      "razon_social" => true,
      "nombre_comercial" => true,
      "rfc" => true,
      "telefono" => true,
      "estado" => true,
      "colonia" => true,
      "calle" => true,
      "preventa" => true,
      "entrega" => true,
      "autoventa" => true
    }

    visible_columns = Map.merge(default_visible_columns, visible_columns_params)

    # Cargar clientes con paginación usando Flop
    {clientes, meta, error} =
      try do
        case Clientes.list_clientes_with_flop(params) do
          {:ok, {clientes, meta}} -> {clientes, meta, nil}
          {:error, _meta} -> {[], %Flop.Meta{}, "Error al cargar clientes"}
        end
      rescue
        e ->
          require Logger
          Logger.error("Error cargando clientes: #{inspect(e)}")
          {[], %Flop.Meta{}, "Error al cargar clientes. Por favor intenta de nuevo."}
      end

    {:noreply,
     socket
     |> assign(:clientes, clientes)
     |> assign(:meta, meta)
     |> assign(:params, params)
     |> assign(:loading, false)
     |> assign(:error, error)
     |> assign(:visible_columns, visible_columns)}
  end

  ## Handle event para toggle de filtros
  @impl true
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, update(socket, :filters_open, &(not &1))}
  end

  ## Handle event para toggle de columnas
  def handle_event("toggle_column", %{"column" => column}, socket) do
    visible_columns = socket.assigns.visible_columns
    new_visible = Map.update!(visible_columns, column, &(not &1))

    # Actualizar el assign directamente para reflejar cambios inmediatamente
    {:noreply, assign(socket, :visible_columns, new_visible)}
  end

  ## Handle event para seleccionar/deseleccionar todas las columnas
  def handle_event("toggle_all_columns", _params, socket) do
    visible_columns = socket.assigns.visible_columns
    # Si todas están seleccionadas, las deselecciona; si no, las selecciona todas
    all_selected = Enum.all?(visible_columns, fn {_k, v} -> v end)

    new_visible =
      visible_columns
      |> Enum.map(fn {k, _v} -> {k, !all_selected} end)
      |> Enum.into(%{})

    {:noreply, assign(socket, :visible_columns, new_visible)}
  end

  ## Navegación centralizada con CASE (modelo recomendado)
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

  ## Helper para verificar si todas las columnas están seleccionadas
  defp all_columns_selected?(visible_columns) do
    Enum.all?(visible_columns, fn {_k, v} -> v end)
  end

  ## Helper para aplanar params anidados
  defp flatten_params(params) do
    Enum.reduce(params, %{}, fn {key, value}, acc ->
      case value do
        %{} = nested_map when is_map(nested_map) ->
          Enum.reduce(nested_map, acc, fn {nested_key, nested_value}, inner_acc ->
            Map.put(inner_acc, "visible_columns[#{nested_key}]", nested_value)
          end)
        _ ->
          Map.put(acc, key, value)
      end
    end)
  end

  ## Funciones helper para paginación (igual que workorder)
  def get_visible_pages(current_page, total_pages, max_visible) do
    cond do
      total_pages <= max_visible ->
        1..total_pages |> Enum.to_list()

      current_page <= div(max_visible, 2) + 1 ->
        1..max_visible |> Enum.to_list()

      current_page >= total_pages - div(max_visible, 2) ->
        (total_pages - max_visible + 1)..total_pages |> Enum.to_list()

      true ->
        start_page = current_page - div(max_visible, 2)
        start_page..(start_page + max_visible - 1) |> Enum.to_list()
    end
  end

  def build_pagination_path(new_params, current_params) do
    merged_params = Map.merge(current_params, new_params)
    flattened_params = flatten_params(merged_params)
    query_string = URI.encode_query(flattened_params)
    "/admin/clientes?#{query_string}"
  end

  ## Render
  @impl true
  def render(assigns) do
    ~H"""
    <section class="wo-container">
      <header class="wo-header">
        <div class="wo-hero-main">
          <div class="wo-hero-icon">👥</div>
          <div>
            <h1 class="wo-title">Clientes</h1>
            <p class="wo-subtitle">
              Visualiza y gestiona tus clientes activos.
            </p>
          </div>
        </div>

        <div class="wo-header-right">
          <div class="wo-stats">
            <div class="wo-stat-card">
              <span class="wo-stat-label">Clientes activos</span>
              <span class="wo-stat-value">
                <%= Map.get(@meta, :total_count, length(@clientes)) %>
              </span>
            </div>
          </div>

          <!-- Botón para abrir el menú lateral de columnas -->
          <button
            type="button"
            class={"wo-filters-toggle" <> if @filters_open, do: " wo-filters-toggle-open", else: ""}
            phx-click="toggle_filters"
          >
            <span class="wo-filters-toggle-icon">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path
                  fill="currentColor"
                  d="M5 7h14a1 1 0 0 1 0 2H5a1 1 0 0 1 0-2Zm3 5h8a1 1 0 0 1 0 2H8a1 1 0 0 1 0-2Zm3 5h2a1 1 0 0 1 0 2h-2a1 1 0 0 1 0-2Z"
                />
              </svg>
            </span>
            <span class="wo-filters-toggle-text">
              Columnas
            </span>
          </button>
        </div>
      </header>

      <!-- Drawer lateral de columnas -->
      <div class={"wo-filters-drawer" <> if @filters_open, do: " wo-filters-drawer-open", else: ""}>
        <div class="wo-filters-header">
          <h2 class="wo-filters-title">Columnas visibles</h2>
          <button type="button" class="wo-filters-close" phx-click="toggle_filters">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path
                fill="currentColor"
                d="M6.4 19 5 17.6l5.6-5.6L5 6.4 6.4 5l5.6 5.6L17.6 5 19 6.4 13.4 12l5.6 5.6-1.4 1.4-5.6-5.6Z"
              />
            </svg>
          </button>
        </div>

        <div class="wo-filters-content">
          <div class="wo-filter-group">
            <label class="wo-filter-label">Selecciona las columnas a mostrar</label>

            <!-- Checkbox para Seleccionar/Deseleccionar todas -->
            <label class="wo-checkbox-label wo-checkbox-label-all">
              <input
                type="checkbox"
                checked={all_columns_selected?(@visible_columns)}
                phx-click="toggle_all_columns"
                class="wo-checkbox"
              />
              <span>Seleccionar todas</span>
            </label>

            <!-- Checkbox para Código -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["codigo"]}
                phx-click="toggle_column"
                phx-value-column="codigo"
                class="wo-checkbox"
              />
              <span>Código</span>
            </label>

            <!-- Checkbox para Razón Social -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["razon_social"]}
                phx-click="toggle_column"
                phx-value-column="razon_social"
                class="wo-checkbox"
              />
              <span>Razón Social</span>
            </label>

            <!-- Checkbox para Nombre Comercial -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["nombre_comercial"]}
                phx-click="toggle_column"
                phx-value-column="nombre_comercial"
                class="wo-checkbox"
              />
              <span>Nombre Comercial</span>
            </label>

            <!-- Checkbox para RFC -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["rfc"]}
                phx-click="toggle_column"
                phx-value-column="rfc"
                class="wo-checkbox"
              />
              <span>RFC</span>
            </label>

            <!-- Checkbox para Teléfono -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["telefono"]}
                phx-click="toggle_column"
                phx-value-column="telefono"
                class="wo-checkbox"
              />
              <span>Teléfono</span>
            </label>

            <!-- Checkbox para Estado -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["estado"]}
                phx-click="toggle_column"
                phx-value-column="estado"
                class="wo-checkbox"
              />
              <span>Estado</span>
            </label>

            <!-- Checkbox para Colonia -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["colonia"]}
                phx-click="toggle_column"
                phx-value-column="colonia"
                class="wo-checkbox"
              />
              <span>Colonia</span>
            </label>

            <!-- Checkbox para Calle -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["calle"]}
                phx-click="toggle_column"
                phx-value-column="calle"
                class="wo-checkbox"
              />
              <span>Calle</span>
            </label>

            <!-- Checkbox para Preventa -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["preventa"]}
                phx-click="toggle_column"
                phx-value-column="preventa"
                class="wo-checkbox"
              />
              <span>Preventa</span>
            </label>

            <!-- Checkbox para Entrega -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["entrega"]}
                phx-click="toggle_column"
                phx-value-column="entrega"
                class="wo-checkbox"
              />
              <span>Entrega</span>
            </label>

            <!-- Checkbox para Autoventa -->
            <label class="wo-checkbox-label">
              <input
                type="checkbox"
                checked={@visible_columns["autoventa"]}
                phx-click="toggle_column"
                phx-value-column="autoventa"
                class="wo-checkbox"
              />
              <span>Autoventa</span>
            </label>
          </div>
        </div>
      </div>

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
              <%= if @visible_columns["codigo"] do %>
                <th>Código</th>
              <% end %>
              <%= if @visible_columns["razon_social"] do %>
                <th>Razón Social</th>
              <% end %>
              <%= if @visible_columns["nombre_comercial"] do %>
                <th>Nombre Comercial</th>
              <% end %>
              <%= if @visible_columns["rfc"] do %>
                <th>RFC</th>
              <% end %>
              <%= if @visible_columns["telefono"] do %>
                <th>Teléfono</th>
              <% end %>
              <%= if @visible_columns["estado"] do %>
                <th>Estado</th>
              <% end %>
              <%= if @visible_columns["colonia"] do %>
                <th>Colonia</th>
              <% end %>
              <%= if @visible_columns["calle"] do %>
                <th>Calle</th>
              <% end %>
              <%= if @visible_columns["preventa"] do %>
                <th>Preventa</th>
              <% end %>
              <%= if @visible_columns["entrega"] do %>
                <th>Entrega</th>
              <% end %>
              <%= if @visible_columns["autoventa"] do %>
                <th>Autoventa</th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= if @loading do %>
              <tr>
                <td colspan="11" style="text-align: center; padding: 40px;">
                  Cargando clientes...
                </td>
              </tr>
            <% else %>
              <%= if Enum.empty?(@clientes) do %>
                <tr>
                  <td colspan="11" style="text-align: center; padding: 40px; color: #666;">
                    No se encontraron clientes con los filtros seleccionados
                  </td>
                </tr>
              <% else %>
                <%= for cliente <- @clientes do %>
                  <tr class="wo-row">
                    <%= if @visible_columns["codigo"] do %>
                      <td><%= cliente.codigo %></td>
                    <% end %>
                    <%= if @visible_columns["razon_social"] do %>
                      <td><%= cliente.razon_social %></td>
                    <% end %>
                    <%= if @visible_columns["nombre_comercial"] do %>
                      <td><%= cliente.nombre_comercial %></td>
                    <% end %>
                    <%= if @visible_columns["rfc"] do %>
                      <td><%= cliente.rfc %></td>
                    <% end %>
                    <%= if @visible_columns["telefono"] do %>
                      <td><%= cliente.telefono %></td>
                    <% end %>
                    <%= if @visible_columns["estado"] do %>
                      <td><%= cliente.estado %></td>
                    <% end %>
                    <%= if @visible_columns["colonia"] do %>
                      <td><%= cliente.colonia %></td>
                    <% end %>
                    <%= if @visible_columns["calle"] do %>
                      <td><%= cliente.calle %></td>
                    <% end %>
                    <%= if @visible_columns["preventa"] do %>
                      <td><%= cliente.preventa %></td>
                    <% end %>
                    <%= if @visible_columns["entrega"] do %>
                      <td><%= cliente.entrega %></td>
                    <% end %>
                    <%= if @visible_columns["autoventa"] do %>
                      <td><%= cliente.autoventa %></td>
                    <% end %>
                  </tr>
                <% end %>
              <% end %>
            <% end %>
          </tbody>
        </table>
      </div>

      <!-- Paginación personalizada (igual que workorder) -->
      <%= if Map.get(@meta, :total_pages, 0) > 1 do %>
        <div class="wo-pagination-container">
          <div class="wo-pagination">
            <!-- Botón Anterior -->
            <%= if Map.get(@meta, :has_previous_page?, false) do %>
              <a
                href={build_pagination_path(%{"page" => Map.get(@meta, :previous_page, 1)}, @params)}
                class="wo-pagination-btn wo-pagination-prev"
              >
                Anterior
              </a>
            <% else %>
              <span class="wo-pagination-btn wo-pagination-disabled">Anterior</span>
            <% end %>

            <!-- Números de página visibles (solo 3) -->
            <div class="wo-pagination-numbers">
              <%= for page <- get_visible_pages(Map.get(@meta, :current_page, 1), Map.get(@meta, :total_pages, 1), 3) do %>
                <%= if page == Map.get(@meta, :current_page, 1) do %>
                  <span class="wo-pagination-number wo-pagination-current">
                    <%= page %>
                  </span>
                <% else %>
                  <a
                    href={build_pagination_path(%{"page" => page}, @params)}
                    class="wo-pagination-number"
                  >
                    <%= page %>
                  </a>
                <% end %>
              <% end %>
            </div>

            <!-- Botón Siguiente -->
            <%= if Map.get(@meta, :has_next_page?, false) do %>
              <a
                href={build_pagination_path(%{"page" => Map.get(@meta, :next_page, 1)}, @params)}
                class="wo-pagination-btn wo-pagination-next"
              >
                Siguiente
              </a>
            <% else %>
              <span class="wo-pagination-btn wo-pagination-disabled">Siguiente</span>
            <% end %>
          </div>
        </div>
      <% end %>
    </section>
    """
  end
end
