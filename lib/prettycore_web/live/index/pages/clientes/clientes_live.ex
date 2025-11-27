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
        # ya estás aquí
        {:noreply, socket}

      "config" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/configuracion")}

      _ ->
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
    <section class="flex flex-col gap-6 p-6 max-w-7xl mx-auto">
      <header class="flex justify-between items-start gap-4 flex-wrap">
        <div class="flex items-center gap-4">
          <div class="w-10 h-10 rounded-full inline-flex items-center justify-center bg-gradient-to-br from-purple-600 to-slate-900 shadow-sm shadow-indigo-400/40 text-2xl">
            👥
          </div>

          <div>
            <h1 class="text-xl font-semibold tracking-tight text-gray-900">Clientes</h1>

            <p class="text-sm text-gray-500 mt-1">Visualiza y gestiona tus clientes activos.</p>
          </div>
        </div>

        <div class="flex flex-col gap-3">
          <div class="flex gap-3">
            <div class="min-w-[140px] px-3.5 py-2.5 rounded-xl bg-gradient-to-br from-purple-800 to-purple-800 border border-slate-300/35 flex flex-col gap-0.5">
              <span class="text-[11px] uppercase tracking-wider text-white">Clientes activos</span>
              <span class="text-xl font-semibold text-white">
                {Map.get(@meta, :total_count, length(@clientes))}
              </span>
            </div>
          </div>
          <!-- Botón para abrir el menú lateral de columnas -->
          <button
            type="button"
            class={"inline-flex items-center gap-2 px-4 py-2 rounded-lg border transition-all " <> if @filters_open, do: "bg-slate-900 border-indigo-500 shadow-sm shadow-indigo-500/50 text-white", else: "bg-white border-gray-300 hover:bg-gray-50 text-gray-700"}
            phx-click="toggle_filters"
          >
            <span class="w-4 h-4">
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path
                  fill="currentColor"
                  d="M5 7h14a1 1 0 0 1 0 2H5a1 1 0 0 1 0-2Zm3 5h8a1 1 0 0 1 0 2H8a1 1 0 0 1 0-2Zm3 5h2a1 1 0 0 1 0 2h-2a1 1 0 0 1 0-2Z"
                />
              </svg>
            </span>
             <span class="text-sm font-medium">Columnas</span>
          </button>
        </div>
      </header>
      <!-- Drawer lateral de columnas -->
      <div class={"fixed inset-y-0 right-0 w-80 bg-white border-l border-gray-200 shadow-2xl transform transition-transform duration-300 ease-in-out z-50 " <> if @filters_open, do: "translate-x-0", else: "translate-x-full"}>
        <div class="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 class="text-base font-semibold text-gray-900">Columnas visibles</h2>

          <button
            type="button"
            class="p-1 rounded hover:bg-gray-100 text-gray-500 hover:text-gray-900 transition-colors"
            phx-click="toggle_filters"
          >
            <svg viewBox="0 0 24 24" aria-hidden="true" class="w-5 h-5">
              <path
                fill="currentColor"
                d="M6.4 19 5 17.6l5.6-5.6L5 6.4 6.4 5l5.6 5.6L17.6 5 19 6.4 13.4 12l5.6 5.6-1.4 1.4-5.6-5.6Z"
              />
            </svg>
          </button>
        </div>

        <div class="flex flex-col gap-2 p-4 overflow-y-auto max-h-screen">
          <div class="flex flex-col gap-3">
            <label class="text-[11px] uppercase tracking-wider text-gray-600">
              Selecciona las columnas a mostrar
            </label>
            <!-- Checkbox para Seleccionar/Deseleccionar todas -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-800 border-2 border-indigo-600 rounded-lg cursor-pointer hover:bg-purple-900 hover:border-indigo-500 hover:shadow-sm hover:shadow-indigo-500/10 transition-all select-none mb-2">
              <input
                type="checkbox"
                checked={all_columns_selected?(@visible_columns)}
                phx-click="toggle_all_columns"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              />
              <span class="flex-1 text-[15px] font-semibold text-indigo-200">Seleccionar todas</span>
            </label>
            <!-- Checkbox para Código -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["codigo"]}
                phx-click="toggle_column"
                phx-value-column="codigo"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Código</span>
            </label>
            <!-- Checkbox para Razón Social -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["razon_social"]}
                phx-click="toggle_column"
                phx-value-column="razon_social"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Razón Social</span>
            </label>
            <!-- Checkbox para Nombre Comercial -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["nombre_comercial"]}
                phx-click="toggle_column"
                phx-value-column="nombre_comercial"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Nombre Comercial</span>
            </label>
            <!-- Checkbox para RFC -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["rfc"]}
                phx-click="toggle_column"
                phx-value-column="rfc"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">RFC</span>
            </label>
            <!-- Checkbox para Teléfono -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["telefono"]}
                phx-click="toggle_column"
                phx-value-column="telefono"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Teléfono</span>
            </label>
            <!-- Checkbox para Estado -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["estado"]}
                phx-click="toggle_column"
                phx-value-column="estado"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Estado</span>
            </label>
            <!-- Checkbox para Colonia -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["colonia"]}
                phx-click="toggle_column"
                phx-value-column="colonia"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Colonia</span>
            </label>
            <!-- Checkbox para Calle -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["calle"]}
                phx-click="toggle_column"
                phx-value-column="calle"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Calle</span>
            </label>
            <!-- Checkbox para Preventa -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["preventa"]}
                phx-click="toggle_column"
                phx-value-column="preventa"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Preventa</span>
            </label>
            <!-- Checkbox para Entrega -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["entrega"]}
                phx-click="toggle_column"
                phx-value-column="entrega"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Entrega</span>
            </label>
            <!-- Checkbox para Autoventa -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input
                type="checkbox"
                checked={@visible_columns["autoventa"]}
                phx-click="toggle_column"
                phx-value-column="autoventa"
                class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2"
              /> <span class="flex-1 text-[15px] text-slate-300">Autoventa</span>
            </label>
          </div>
        </div>
      </div>
      <!-- Mensaje de error si existe -->
      <%= if @error do %>
        <div class="bg-red-100 border border-red-300 text-red-800 px-4 py-3 rounded-lg mb-5">
          <strong>⚠ Error:</strong> {@error}
        </div>
      <% end %>
      <!-- Tabla de clientes -->
      <div class="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div class="overflow-x-auto">
          <table class="w-full border-collapse min-w-[800px]">
            <thead>
              <tr class="bg-gradient-to-r from-slate-900 to-purple-950 border-b border-slate-700">
                <%= if @visible_columns["codigo"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Código
                  </th>
                <% end %>

                <%= if @visible_columns["razon_social"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Razón Social
                  </th>
                <% end %>

                <%= if @visible_columns["nombre_comercial"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Nombre Comercial
                  </th>
                <% end %>

                <%= if @visible_columns["rfc"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    RFC
                  </th>
                <% end %>

                <%= if @visible_columns["telefono"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Teléfono
                  </th>
                <% end %>

                <%= if @visible_columns["estado"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Estado
                  </th>
                <% end %>

                <%= if @visible_columns["colonia"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Colonia
                  </th>
                <% end %>

                <%= if @visible_columns["calle"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Calle
                  </th>
                <% end %>

                <%= if @visible_columns["preventa"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Preventa
                  </th>
                <% end %>

                <%= if @visible_columns["entrega"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Entrega
                  </th>
                <% end %>

                <%= if @visible_columns["autoventa"] do %>
                  <th class="px-4 py-3 text-left text-xs font-semibold text-white tracking-wide">
                    Autoventa
                  </th>
                <% end %>
              </tr>
            </thead>

            <tbody>
              <%= if @loading do %>
                <tr>
                  <td colspan="11" class="text-center py-10 text-gray-500 text-sm">
                    Cargando clientes...
                  </td>
                </tr>
              <% else %>
                <%= if Enum.empty?(@clientes) do %>
                  <tr>
                    <td colspan="11" class="text-center py-10 text-gray-500 text-sm">
                      No se encontraron clientes con los filtros seleccionados
                    </td>
                  </tr>
                <% else %>
                  <%= for cliente <- @clientes do %>
                    <tr class="border-b border-gray-100 hover:bg-purple-50 transition-colors">
                      <%= if @visible_columns["codigo"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.codigo}</td>
                      <% end %>

                      <%= if @visible_columns["razon_social"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.razon_social}</td>
                      <% end %>

                      <%= if @visible_columns["nombre_comercial"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.nombre_comercial}</td>
                      <% end %>

                      <%= if @visible_columns["rfc"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.rfc}</td>
                      <% end %>

                      <%= if @visible_columns["telefono"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.telefono}</td>
                      <% end %>

                      <%= if @visible_columns["estado"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.estado}</td>
                      <% end %>

                      <%= if @visible_columns["colonia"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.colonia}</td>
                      <% end %>

                      <%= if @visible_columns["calle"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.calle}</td>
                      <% end %>

                      <%= if @visible_columns["preventa"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.preventa}</td>
                      <% end %>

                      <%= if @visible_columns["entrega"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.entrega}</td>
                      <% end %>

                      <%= if @visible_columns["autoventa"] do %>
                        <td class="px-4 py-3 text-sm text-gray-700">{cliente.autoventa}</td>
                      <% end %>
                    </tr>
                  <% end %>
                <% end %>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
      <!-- Paginación personalizada (igual que workorder) -->
      <%= if Map.get(@meta, :total_pages, 0) > 1 do %>
        <div class="flex items-center justify-center gap-2 mt-6 flex-wrap">
          <!-- Botón Anterior -->
          <%= if Map.get(@meta, :has_previous_page?, false) do %>
            <a
              href={build_pagination_path(%{"page" => Map.get(@meta, :previous_page, 1)}, @params)}
              class="px-4 py-2 text-sm font-medium text-white bg-gradient-to-r from-purple-600 to-purple-700 rounded-lg hover:from-purple-700 hover:to-purple-800 transition-all shadow-sm hover:shadow-md"
            >
              Anterior
            </a>
          <% else %>
            <span class="px-4 py-2 text-sm font-medium text-gray-400 bg-gray-200 rounded-lg cursor-not-allowed">
              Anterior
            </span>
          <% end %>
          <!-- Números de página visibles (solo 3) -->
          <div class="flex items-center gap-1">
            <%= for page <- get_visible_pages(Map.get(@meta, :current_page, 1), Map.get(@meta, :total_pages, 1), 3) do %>
              <%= if page == Map.get(@meta, :current_page, 1) do %>
                <span class="min-w-[40px] h-10 flex items-center justify-center text-sm font-semibold bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg shadow-md">
                  {page}
                </span>
              <% else %>
                <a
                  href={build_pagination_path(%{"page" => page}, @params)}
                  class="min-w-[40px] h-10 flex items-center justify-center text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-purple-50 hover:border-purple-300 hover:text-purple-700 transition-all"
                >
                  {page}
                </a>
              <% end %>
            <% end %>
          </div>
          <!-- Botón Siguiente -->
          <%= if Map.get(@meta, :has_next_page?, false) do %>
            <a
              href={build_pagination_path(%{"page" => Map.get(@meta, :next_page, 1)}, @params)}
              class="px-4 py-2 text-sm font-medium text-white bg-gradient-to-r from-purple-600 to-purple-700 rounded-lg hover:from-purple-700 hover:to-purple-800 transition-all shadow-sm hover:shadow-md"
            >
              Siguiente
            </a>
          <% else %>
            <span class="px-4 py-2 text-sm font-medium text-gray-400 bg-gray-200 rounded-lg cursor-not-allowed">
              Siguiente
            </span>
          <% end %>
        </div>
      <% end %>
    </section>
    """
  end
end
