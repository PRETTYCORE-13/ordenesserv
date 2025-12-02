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
     |> assign(:filters_open, false)
     |> assign(:expanded_clients, MapSet.new())
     |> assign(:search_query, "")
     |> assign(:filter_ruta, "")
     |> assign(:filter_udn, "")}
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
      "udn" => true,
      "preventa" => true,
      "entrega" => true,
      "autoventa" => true,
      "ctedir_codigo_k" => true,
      "rfc" => true,
      "codigo" => true,
      "razon_social" => true,
      "diascredito" => true,
      "limite_credito" => true,
      "paquete_codigo" => true,
      "frecuencia_codigo" => true,
      "email_receptor" => true,
      "forma_pago" => true,
      "metodo_pago" => true,
      "estatus" => true
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

  ## Handle event para expandir/colapsar detalles de cliente
  def handle_event("toggle_client_details", %{"codigo" => codigo, "dir" => dir}, socket) do
    key = "#{codigo}|#{dir}"
    expanded_clients = socket.assigns.expanded_clients

    new_expanded_clients =
      if MapSet.member?(expanded_clients, key) do
        MapSet.delete(expanded_clients, key)
      else
        MapSet.put(expanded_clients, key)
      end

    {:noreply, assign(socket, :expanded_clients, new_expanded_clients)}
  end

  ## Handle event para ver detalles completos del cliente
  def handle_event("show_details", %{"client-id" => client_id}, socket) do
    # Aquí puedes redirigir a una página de detalles o abrir un modal
    # Por ahora solo expandimos la fila
    expanded_rows = MapSet.put(socket.assigns.expanded_rows, client_id)
    {:noreply, assign(socket, :expanded_rows, expanded_rows)}
  end

  ## Handle event para editar cliente
  def handle_event("edit_client", %{"client-id" => client_id}, socket) do
    # Aquí puedes redirigir a la página de edición o abrir un modal
    # Por ejemplo: push_navigate(socket, to: ~p"/admin/clientes/#{client_id}/edit")
    {:noreply, socket}
  end

  ## Handle event para enviar email al cliente
  def handle_event("send_email", %{"email" => email}, socket) do
    # Aquí puedes implementar la lógica para enviar email
    # Por ejemplo, abrir el cliente de email o un modal de composición
    {:noreply, socket}
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

  ## Helper para verificar si un cliente está expandido
  defp client_expanded?(expanded_clients, codigo, dir) do
    key = "#{codigo}|#{dir}"
    MapSet.member?(expanded_clients, key)
  end

  ## Helper para obtener la inicial del cliente
  defp get_initial(razon_social) when is_binary(razon_social) do
    razon_social
    |> String.trim()
    |> String.first()
    |> String.upcase()
  end
  defp get_initial(_), do: "?"

  ## Helper para obtener color de avatar basado en código
  defp avatar_color(codigo) when is_binary(codigo) do
    colors = [
      "bg-purple-600",
      "bg-blue-600",
      "bg-emerald-600",
      "bg-amber-600",
      "bg-rose-600",
      "bg-indigo-600",
      "bg-cyan-600",
      "bg-pink-600"
    ]

    hash = :erlang.phash2(codigo, length(colors))
    Enum.at(colors, hash)
  end
  defp avatar_color(_), do: "bg-gray-600"

  ## Helper para obtener etiqueta de estatus
  defp estatus_label("A"), do: "Activo"
  defp estatus_label("I"), do: "Inactivo"
  defp estatus_label(_), do: "?"

  ## Helper para color del badge de estatus
  defp estatus_badge_class("A"), do: "px-1.5 py-0.5 bg-green-100 text-green-700 rounded text-xs font-medium"
  defp estatus_badge_class("I"), do: "px-1.5 py-0.5 bg-red-100 text-red-700 rounded text-xs font-medium"
  defp estatus_badge_class(_), do: "px-1.5 py-0.5 bg-gray-100 text-gray-700 rounded text-xs font-medium"

  ## Helper para obtener estado de crédito (simulado)
  defp credit_status(_cliente) do
    # Aquí podrías implementar lógica real basada en pagos
    # Por ahora retornamos un valor aleatorio para demostración
    Enum.random(["Al Corriente", "Vencido", "Sin Crédito"])
  end

  ## Helper para color del badge de crédito
  defp credit_badge_class(status) do
    case status do
      "Al Corriente" -> "bg-emerald-500 text-white"
      "Vencido" -> "bg-amber-500 text-white"
      "Sin Crédito" -> "bg-rose-500 text-white"
      _ -> "bg-gray-500 text-white"
    end
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
    <section class="flex flex-col gap-6 p-6 max-w-7xl mx-auto bg-gray-50 min-h-screen">
      <!-- HEADER MODERNO -->
      <header class="bg-white rounded-2xl shadow-sm border border-gray-200 p-6">
        <div class="flex items-center justify-between gap-4 mb-6">
          <div class="flex items-center gap-4">
            <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-purple-600 to-indigo-600 flex items-center justify-center shadow-lg">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
              </svg>
            </div>
            <div>
              <h1 class="text-2xl font-bold text-gray-900">Clientes</h1>
              <p class="text-sm text-gray-500 mt-0.5">Gestiona y visualiza tus clientes</p>
            </div>
          </div>

          <div class="flex items-center gap-3">
            <!-- Contador de Clientes -->
            <div class="px-4 py-2 bg-purple-50 rounded-lg border border-purple-200">
              <div class="flex items-center gap-2">
                <span class="text-sm font-medium text-purple-700">Total:</span>
                <span class="text-xl font-bold text-purple-900">
                  <%= Map.get(@meta, :total_count, length(@clientes)) %>
                </span>
              </div>
            </div>

            <!-- Botón Nuevo Cliente -->
            <button
              type="button"
              class="inline-flex items-center gap-2 px-4 py-2.5 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white font-semibold rounded-xl shadow-lg hover:shadow-xl transition-all duration-200"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
              </svg>
              Nuevo Cliente
            </button>
          </div>
        </div>

        <!-- BARRA DE BÚSQUEDA Y FILTROS -->
        <div class="flex items-center gap-3 flex-wrap">
          <!-- Búsqueda Principal -->
          <div class="flex-1 min-w-[300px]">
            <div class="relative">
              <svg class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
              </svg>
              <input
                type="text"
                placeholder="Buscar por código, nombre, RFC..."
                class="w-full pl-10 pr-4 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all"
              />
            </div>
          </div>

          <!-- Filtros Rápidos -->
          <select class="px-4 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-gray-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all">
            <option value="">Todas las Rutas</option>
            <option value="R01">Ruta 01</option>
            <option value="R02">Ruta 02</option>
          </select>

          <select class="px-4 py-2.5 bg-gray-50 border border-gray-300 rounded-xl text-gray-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all">
            <option value="">Todas las UDN</option>
            <option value="100">UDN 100</option>
            <option value="200">UDN 200</option>
          </select>

          <!-- Botón Filtros Avanzados -->
          <button
            type="button"
            phx-click="toggle_filters"
            class={"inline-flex items-center gap-2 px-4 py-2.5 rounded-xl font-medium transition-all " <> if @filters_open, do: "bg-purple-600 text-white shadow-lg", else: "bg-white border border-gray-300 text-gray-700 hover:bg-gray-50"}
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path>
            </svg>
            Filtros Avanzados
          </button>
        </div>
      </header>

      <!-- Drawer lateral de columnas -->
      <div class={"fixed inset-y-0 right-0 w-80 bg-white border-l border-gray-200 shadow-2xl transform transition-transform duration-300 ease-in-out z-50 " <> if @filters_open, do: "translate-x-0", else: "translate-x-full"}>
        <div class="flex items-center justify-between p-4 border-b border-gray-200">
          <h2 class="text-base font-semibold text-gray-900">Columnas visibles</h2>
          <button type="button" class="p-1 rounded hover:bg-gray-100 text-gray-500 hover:text-gray-900 transition-colors" phx-click="toggle_filters">
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
            <label class="text-[11px] uppercase tracking-wider text-gray-600">Selecciona las columnas a mostrar</label>

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

            <!-- Checkbox para UDN -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["udn"]} phx-click="toggle_column" phx-value-column="udn" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">UDN</span>
            </label>

            <!-- Checkbox para Preventa -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["preventa"]} phx-click="toggle_column" phx-value-column="preventa" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Preventa</span>
            </label>

            <!-- Checkbox para Entrega -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["entrega"]} phx-click="toggle_column" phx-value-column="entrega" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Entrega</span>
            </label>

            <!-- Checkbox para Autoventa -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["autoventa"]} phx-click="toggle_column" phx-value-column="autoventa" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Autoventa</span>
            </label>

            <!-- Checkbox para Código Dirección -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["ctedir_codigo_k"]} phx-click="toggle_column" phx-value-column="ctedir_codigo_k" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Código Dirección</span>
            </label>

            <!-- Checkbox para RFC -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["rfc"]} phx-click="toggle_column" phx-value-column="rfc" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">RFC</span>
            </label>

            <!-- Checkbox para Código -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["codigo"]} phx-click="toggle_column" phx-value-column="codigo" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Código Cliente</span>
            </label>

            <!-- Checkbox para Razón Social -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["razon_social"]} phx-click="toggle_column" phx-value-column="razon_social" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Razón Social</span>
            </label>

            <!-- Checkbox para Días Crédito -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["diascredito"]} phx-click="toggle_column" phx-value-column="diascredito" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Días Crédito</span>
            </label>

            <!-- Checkbox para Límite Crédito -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["limite_credito"]} phx-click="toggle_column" phx-value-column="limite_credito" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Límite Crédito</span>
            </label>

            <!-- Checkbox para Lista Precios -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["paquete_codigo"]} phx-click="toggle_column" phx-value-column="paquete_codigo" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Lista Precios</span>
            </label>

            <!-- Checkbox para Frecuencia -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["frecuencia_codigo"]} phx-click="toggle_column" phx-value-column="frecuencia_codigo" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Frecuencia</span>
            </label>

            <!-- Checkbox para Email Receptor -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["email_receptor"]} phx-click="toggle_column" phx-value-column="email_receptor" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Email Receptor</span>
            </label>

            <!-- Checkbox para Forma Pago -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["forma_pago"]} phx-click="toggle_column" phx-value-column="forma_pago" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Forma Pago</span>
            </label>

            <!-- Checkbox para Método Pago -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["metodo_pago"]} phx-click="toggle_column" phx-value-column="metodo_pago" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Método Pago</span>
            </label>

            <!-- Checkbox para Estatus -->
            <label class="flex items-center gap-3 px-3 py-2.5 bg-slate-900 border border-slate-800 rounded-lg cursor-pointer hover:bg-slate-800 hover:border-slate-600 transition-all select-none">
              <input type="checkbox" checked={@visible_columns["estatus"]} phx-click="toggle_column" phx-value-column="estatus" class="w-[18px] h-[18px] cursor-pointer accent-indigo-600 border-2 border-gray-400 rounded transition-all focus:outline-2 focus:outline-indigo-600 focus:outline-offset-2" />
              <span class="flex-1 text-[15px] text-slate-300">Estatus</span>
            </label>
          </div>
        </div>
      </div>

      <!-- Mensaje de error si existe -->
      <%= if @error do %>
        <div class="bg-red-100 border border-red-300 text-red-800 px-4 py-3 rounded-lg mb-5">
          <strong>⚠ Error:</strong> <%= @error %>
        </div>
      <% end %>

      <!-- LISTA DE CLIENTES CON CARDS EXPANDIBLES (sin espacios) -->
      <div class="rounded-2xl bg-white/95 border border-white/95 shadow-2xl shadow-white/80 overflow-hidden">
        <%= if @loading do %>
          <div class="p-12 text-center">
            <div class="flex flex-col items-center gap-3">
              <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-purple-600"></div>
              <span class="font-medium text-gray-600">Cargando clientes...</span>
            </div>
          </div>
        <% else %>
          <%= if Enum.empty?(@clientes) do %>
            <div class="py-10 px-6 text-center grid place-items-center gap-2.5">
              <div class="w-10 h-10 rounded-full inline-flex items-center justify-center text-2xl bg-slate-900 border border-dashed border-slate-400/50">
                👥
              </div>
              <h2 class="text-base font-medium text-gray-900">Sin clientes registrados</h2>
              <p class="text-sm text-gray-500">No hay clientes para el filtro seleccionado.</p>
            </div>
          <% else %>
            <!-- ENCABEZADOS DE COLUMNAS -->
            <div class="flex items-center gap-3 px-4 py-3 bg-gradient-to-r from-slate-900 to-slate-800 border-b-2 border-slate-700">
              <!-- Avatar Header -->
              <div class="w-9 flex-shrink-0">
                <span class="text-xs font-bold text-slate-300 uppercase tracking-wide"></span>
              </div>

              <!-- UDN Header -->
              <div class="w-16 flex-shrink-0">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">UDN</span>
              </div>

              <!-- Código Header -->
              <div class="w-20 flex-shrink-0">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">Código</span>
              </div>

              <!-- Dir Header -->
              <div class="w-16 flex-shrink-0">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">Dir</span>
              </div>

              <!-- Nombre Header -->
              <div class="flex-1 min-w-0">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">Nombre</span>
              </div>

              <!-- RFC Header -->
              <div class="w-32 flex-shrink-0 hidden md:block">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">RFC</span>
              </div>

              <!-- Preventa Header -->
              <div class="w-20 flex-shrink-0 hidden lg:block">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">Preventa</span>
              </div>

              <!-- Entrega Header -->
              <div class="w-20 flex-shrink-0 hidden lg:block">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">Entrega</span>
              </div>

              <!-- Autoventa Header -->
              <div class="w-20 flex-shrink-0 hidden xl:block">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">Autoventa</span>
              </div>

              <!-- Estatus Header -->
              <div class="w-20 flex-shrink-0 hidden xl:block">
                <span class="text-xs font-bold text-slate-200 uppercase tracking-wide">Estatus</span>
              </div>

              <!-- Chevron Header (vacío) -->
              <div class="flex-shrink-0">
                <span class="w-5 h-5 inline-block"></span>
              </div>
            </div>

            <!-- REGISTROS COMPACTOS SIN ESPACIOS -->
            <%= for cliente <- @clientes do %>
              <% is_expanded = client_expanded?(@expanded_clients, cliente.codigo, cliente.ctedir_codigo_k) %>
              <% initial = get_initial(cliente.razon_social) %>
              <% avatar_bg = avatar_color(cliente.codigo) %>

              <div class="border-b border-gray-200 last:border-b-0">
                <!-- VISTA COMPACTA: Una sola línea clickeable -->
                <div
                  class="flex items-center gap-3 px-4 py-2.5 hover:bg-gradient-to-r hover:from-purple-50/50 hover:to-transparent cursor-pointer transition-all duration-200"
                  phx-click="toggle_client_details"
                  phx-value-codigo={cliente.codigo}
                  phx-value-dir={cliente.ctedir_codigo_k}
                >
                  <!-- AVATAR -->
                  <div class={"w-9 h-9 rounded-full flex items-center justify-center text-white font-bold text-sm shadow #{avatar_bg}"}>
                    <%= initial %>
                  </div>

                  <!-- UDN -->
                  <div class="w-16 flex-shrink-0">
                    <span class="px-2 py-0.5 bg-purple-100 text-purple-700 rounded text-xs font-semibold">
                      <%= cliente.udn %>
                    </span>
                  </div>

                  <!-- CÓDIGO -->
                  <div class="w-20 flex-shrink-0">
                    <span class="text-sm font-bold text-gray-900"><%= cliente.codigo %></span>
                  </div>

                  <!-- DIR -->
                  <div class="w-16 flex-shrink-0">
                    <span class="text-xs text-gray-600"><%= cliente.ctedir_codigo_k %></span>
                  </div>

                  <!-- NOMBRE -->
                  <div class="flex-1 min-w-0">
                    <span class="text-sm font-medium text-gray-900 truncate block" title={cliente.razon_social}>
                      <%= cliente.razon_social %>
                    </span>
                  </div>

                  <!-- RFC -->
                  <div class="w-32 flex-shrink-0 hidden md:block">
                    <span class="text-xs font-mono text-gray-700"><%= cliente.rfc %></span>
                  </div>

                  <!-- PREVENTA -->
                  <div class="w-20 flex-shrink-0 hidden lg:block">
                    <span class="px-1.5 py-0.5 bg-blue-100 text-blue-700 rounded text-xs font-medium">
                      <%= cliente.preventa %>
                    </span>
                  </div>

                  <!-- ENTREGA -->
                  <div class="w-20 flex-shrink-0 hidden lg:block">
                    <span class="px-1.5 py-0.5 bg-emerald-100 text-emerald-700 rounded text-xs font-medium">
                      <%= cliente.entrega %>
                    </span>
                  </div>

                  <!-- AUTOVENTA -->
                  <div class="w-20 flex-shrink-0 hidden xl:block">
                    <%= if cliente.autoventa do %>
                      <span class="px-1.5 py-0.5 bg-orange-100 text-orange-700 rounded text-xs font-medium">
                        <%= cliente.autoventa %>
                      </span>
                    <% else %>
                      <span class="text-xs text-gray-400">—</span>
                    <% end %>
                  </div>

                  <!-- ESTADO -->
                  <div class="w-20 flex-shrink-0 hidden xl:block">
                    <span class={estatus_badge_class(cliente.estatus)}>
                      <%= estatus_label(cliente.estatus) %>
                    </span>
                  </div>

                  <!-- CHEVRON -->
                  <div class="flex-shrink-0">
                    <svg
                      class={[
                        "w-5 h-5 text-gray-400 transition-transform duration-300",
                        if(is_expanded, do: "rotate-180", else: "rotate-0")
                      ]}
                      fill="none"
                      stroke="currentColor"
                      viewBox="0 0 24 24"
                    >
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                    </svg>
                  </div>
                </div>

                <!-- VISTA EXPANDIDA -->
                <div class={[
                  "transition-all duration-300 ease-in-out overflow-hidden bg-gradient-to-r from-slate-50 to-purple-50/30",
                  if(is_expanded, do: "max-h-96 opacity-100", else: "max-h-0 opacity-0")
                ]}>
                  <div class="px-4 py-4 space-y-3">

                    <!-- SECCIÓN FINANCIERO -->
                    <div class="flex items-center gap-2 text-sm">
                      <span class="text-lg">💳</span>
                      <span class="font-semibold text-gray-700">Financiero:</span>
                      <div class="flex items-center gap-3 flex-wrap">
                        <span class="text-gray-800">
                          Días Crédito: <span class="font-bold text-indigo-600"><%= cliente.diascredito %>d</span>
                        </span>
                        <span class="text-gray-400">|</span>
                        <span class="text-gray-800">
                          Límite: <span class="font-bold text-emerald-600">$<%= if cliente.limite_credito, do: :erlang.float_to_binary(Decimal.to_float(cliente.limite_credito), decimals: 2), else: "0.00" %></span>
                        </span>
                        <span class="text-gray-400">|</span>
                        <span class="text-gray-800">
                          Lista: <span class="font-bold text-purple-600"><%= cliente.paquete_codigo %></span>
                        </span>
                        <span class="text-gray-400">|</span>
                        <span class="text-gray-800">
                          Frecuencia: <span class="font-bold text-gray-700"><%= cliente.frecuencia_codigo %></span>
                        </span>
                      </div>
                    </div>

                    <!-- SECCIÓN CONTACTO -->
                    <div class="flex items-center gap-2 text-sm">
                      <span class="text-lg">📧</span>
                      <span class="font-semibold text-gray-700">Contacto:</span>
                      <div class="flex items-center gap-3 flex-wrap">
                        <%= if cliente.email_receptor do %>
                          <a href={"mailto:#{cliente.email_receptor}"} class="text-blue-600 hover:underline font-medium">
                            <%= cliente.email_receptor %>
                          </a>
                        <% else %>
                          <span class="text-amber-600 font-medium">Sin email</span>
                        <% end %>
                        <span class="text-gray-400">|</span>
                        <span class="text-gray-800">
                          Forma Pago: <span class="font-bold"><%= cliente.forma_pago %></span>
                        </span>
                        <span class="text-gray-400">|</span>
                        <span class="text-gray-800">
                          Método Pago: <span class="font-bold"><%= cliente.metodo_pago %></span>
                        </span>
                      </div>
                    </div>

                    <!-- BOTONES DE ACCIÓN -->
                    <div class="flex gap-2 pt-2">
                      <button
                        type="button"
                        phx-click="edit_client"
                        phx-value-client-id={cliente.codigo}
                        class="px-3 py-1.5 bg-purple-600 hover:bg-purple-700 text-white text-xs font-semibold rounded transition-colors"
                      >
                        ✏️ Editar
                      </button>
                      <%= if cliente.email_receptor do %>
                        <button
                          type="button"
                          phx-click="send_email"
                          phx-value-email={cliente.email_receptor}
                          class="px-3 py-1.5 bg-blue-600 hover:bg-blue-700 text-white text-xs font-semibold rounded transition-colors"
                        >
                          📧 Email
                        </button>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        <% end %>
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
              <span class="px-4 py-2 text-sm font-medium text-gray-400 bg-gray-200 rounded-lg cursor-not-allowed">Anterior</span>
            <% end %>

            <!-- Números de página visibles (solo 3) -->
            <div class="flex items-center gap-1">
              <%= for page <- get_visible_pages(Map.get(@meta, :current_page, 1), Map.get(@meta, :total_pages, 1), 3) do %>
                <%= if page == Map.get(@meta, :current_page, 1) do %>
                  <span class="min-w-[40px] h-10 flex items-center justify-center text-sm font-semibold bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg shadow-md">
                    <%= page %>
                  </span>
                <% else %>
                  <a
                    href={build_pagination_path(%{"page" => page}, @params)}
                    class="min-w-[40px] h-10 flex items-center justify-center text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-purple-50 hover:border-purple-300 hover:text-purple-700 transition-all"
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
                class="px-4 py-2 text-sm font-medium text-white bg-gradient-to-r from-purple-600 to-purple-700 rounded-lg hover:from-purple-700 hover:to-purple-800 transition-all shadow-sm hover:shadow-md"
              >
                Siguiente
              </a>
            <% else %>
              <span class="px-4 py-2 text-sm font-medium text-gray-400 bg-gray-200 rounded-lg cursor-not-allowed">Siguiente</span>
            <% end %>
          </div>
      <% end %>
    </section>
    """
  end
end
