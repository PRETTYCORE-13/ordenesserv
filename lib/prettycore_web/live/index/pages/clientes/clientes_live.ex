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
    <section class="flex flex-col gap-6 p-6 max-w-7xl mx-auto">
      <header class="flex justify-between items-start gap-4 flex-wrap">
        <div class="flex items-center gap-4">
          <div class="w-10 h-10 rounded-full inline-flex items-center justify-center bg-gradient-to-br from-purple-600 to-slate-900 shadow-sm shadow-indigo-400/40 text-2xl">
            👥
          </div>
          <div>
            <h1 class="text-xl font-semibold tracking-tight text-gray-900">
              Clientes
            </h1>
            <p class="text-sm text-gray-500 mt-1">
              Visualiza y gestiona tus clientes activos.
            </p>
          </div>
        </div>

        <div class="flex flex-col gap-3">
          <div class="flex gap-3">
            <div class="min-w-[140px] px-3.5 py-2.5 rounded-xl bg-gradient-to-br from-purple-600 to-purple-600 border border-slate-300/35 flex flex-col gap-0.5">
              <span class="text-[11px] uppercase tracking-wider text-white">
                Clientes activos
              </span>
              <span class="text-xl font-semibold text-white">
                <%= Map.get(@meta, :total_count, length(@clientes)) %>
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
            <span class="text-sm font-medium">
              Columnas
            </span>
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

      <!-- Tabla de clientes estilo dashboard -->
      <div class="bg-white rounded-2xl shadow-lg border border-gray-200/80 overflow-hidden backdrop-blur-sm">
        <div class="overflow-x-auto">
          <table class="w-full min-w-max">
            <thead>
              <tr class="bg-gradient-to-r from-slate-900 via-purple-900 to-slate-900">
                <%= if @visible_columns["udn"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">UDN</th>
                <% end %>
                <%= if @visible_columns["preventa"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Preventa</th>
                <% end %>
                <%= if @visible_columns["entrega"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Entrega</th>
                <% end %>
                <%= if @visible_columns["autoventa"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Autoventa</th>
                <% end %>
                <%= if @visible_columns["ctedir_codigo_k"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Cód. Dirección</th>
                <% end %>
                <%= if @visible_columns["rfc"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">RFC</th>
                <% end %>
                <%= if @visible_columns["codigo"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Código Cliente</th>
                <% end %>
                <%= if @visible_columns["razon_social"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Razón Social</th>
                <% end %>
                <%= if @visible_columns["diascredito"] do %>
                  <th class="px-6 py-4 text-center text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Días Crédito</th>
                <% end %>
                <%= if @visible_columns["limite_credito"] do %>
                  <th class="px-6 py-4 text-right text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Límite Crédito</th>
                <% end %>
                <%= if @visible_columns["paquete_codigo"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Lista Precios</th>
                <% end %>
                <%= if @visible_columns["frecuencia_codigo"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Frecuencia</th>
                <% end %>
                <%= if @visible_columns["email_receptor"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Email Receptor</th>
                <% end %>
                <%= if @visible_columns["forma_pago"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Forma Pago</th>
                <% end %>
                <%= if @visible_columns["metodo_pago"] do %>
                  <th class="px-6 py-4 text-left text-[11px] font-bold text-purple-200 uppercase tracking-wider border-r border-slate-700/50">Método Pago</th>
                <% end %>
                <%= if @visible_columns["estatus"] do %>
                  <th class="px-6 py-4 text-center text-[11px] font-bold text-purple-200 uppercase tracking-wider">Estatus</th>
                <% end %>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <%= if @loading do %>
                <tr>
                  <td colspan="16" class="text-center py-16 text-gray-500 text-sm">
                    <div class="flex flex-col items-center gap-3">
                      <div class="animate-spin rounded-full h-10 w-10 border-b-2 border-purple-600"></div>
                      <span class="font-medium">Cargando clientes...</span>
                    </div>
                  </td>
                </tr>
              <% else %>
                <%= if Enum.empty?(@clientes) do %>
                  <tr>
                    <td colspan="16" class="text-center py-16 text-gray-500 text-sm">
                      <div class="flex flex-col items-center gap-2">
                        <svg class="w-16 h-16 text-gray-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4"></path>
                        </svg>
                        <span class="font-medium text-gray-600">No se encontraron clientes</span>
                        <span class="text-xs text-gray-400">Intenta ajustar los filtros de búsqueda</span>
                      </div>
                    </td>
                  </tr>
                <% else %>
                  <%= for cliente <- @clientes do %>
                    <tr class="group hover:bg-gradient-to-r hover:from-purple-50/50 hover:to-transparent transition-all duration-200 cursor-pointer border-l-4 border-transparent hover:border-purple-500">
                      <%= if @visible_columns["udn"] do %>
                        <td class="px-6 py-4 text-sm font-medium text-gray-900 border-r border-gray-100/50">
                          <div class="flex items-center gap-2">
                            <span class="w-2 h-2 rounded-full bg-purple-500"></span>
                            <%= cliente.udn %>
                          </div>
                        </td>
                      <% end %>
                      <%= if @visible_columns["preventa"] do %>
                        <td class="px-6 py-4 text-sm text-gray-700 border-r border-gray-100/50">
                          <span class="px-2.5 py-1 bg-blue-50 text-blue-700 rounded-lg font-medium text-xs"><%= cliente.preventa %></span>
                        </td>
                      <% end %>
                      <%= if @visible_columns["entrega"] do %>
                        <td class="px-6 py-4 text-sm text-gray-700 border-r border-gray-100/50">
                          <span class="px-2.5 py-1 bg-emerald-50 text-emerald-700 rounded-lg font-medium text-xs"><%= cliente.entrega %></span>
                        </td>
                      <% end %>
                      <%= if @visible_columns["autoventa"] do %>
                        <td class="px-6 py-4 text-sm text-gray-700 border-r border-gray-100/50">
                          <span class="px-2.5 py-1 bg-orange-50 text-orange-700 rounded-lg font-medium text-xs"><%= cliente.autoventa %></span>
                        </td>
                      <% end %>
                      <%= if @visible_columns["ctedir_codigo_k"] do %>
                        <td class="px-6 py-4 text-sm font-mono text-gray-600 border-r border-gray-100/50"><%= cliente.ctedir_codigo_k %></td>
                      <% end %>
                      <%= if @visible_columns["rfc"] do %>
                        <td class="px-6 py-4 text-sm font-mono text-gray-900 border-r border-gray-100/50 uppercase"><%= cliente.rfc %></td>
                      <% end %>
                      <%= if @visible_columns["codigo"] do %>
                        <td class="px-6 py-4 text-sm font-semibold text-purple-900 border-r border-gray-100/50"><%= cliente.codigo %></td>
                      <% end %>
                      <%= if @visible_columns["razon_social"] do %>
                        <td class="px-6 py-4 text-sm text-gray-800 font-medium border-r border-gray-100/50 max-w-xs truncate" title={cliente.razon_social}><%= cliente.razon_social %></td>
                      <% end %>
                      <%= if @visible_columns["diascredito"] do %>
                        <td class="px-6 py-4 text-sm text-center border-r border-gray-100/50">
                          <span class="inline-flex items-center justify-center w-10 h-10 rounded-full bg-indigo-100 text-indigo-700 font-bold text-xs">
                            <%= cliente.diascredito %>
                          </span>
                        </td>
                      <% end %>
                      <%= if @visible_columns["limite_credito"] do %>
                        <td class="px-6 py-4 text-sm text-right font-semibold text-gray-900 border-r border-gray-100/50">
                          <span class="text-emerald-600">$<%= if cliente.limite_credito, do: :erlang.float_to_binary(Decimal.to_float(cliente.limite_credito), decimals: 2), else: "0.00" %></span>
                        </td>
                      <% end %>
                      <%= if @visible_columns["paquete_codigo"] do %>
                        <td class="px-6 py-4 text-sm text-gray-700 border-r border-gray-100/50">
                          <span class="px-2.5 py-1 bg-purple-50 text-purple-700 rounded-lg font-medium text-xs"><%= cliente.paquete_codigo %></span>
                        </td>
                      <% end %>
                      <%= if @visible_columns["frecuencia_codigo"] do %>
                        <td class="px-6 py-4 text-sm text-gray-700 border-r border-gray-100/50"><%= cliente.frecuencia_codigo %></td>
                      <% end %>
                      <%= if @visible_columns["email_receptor"] do %>
                        <td class="px-6 py-4 text-sm text-gray-600 border-r border-gray-100/50 max-w-xs truncate" title={cliente.email_receptor}>
                          <%= if cliente.email_receptor do %>
                            <a href={"mailto:#{cliente.email_receptor}"} class="text-blue-600 hover:text-blue-800 hover:underline"><%= cliente.email_receptor %></a>
                          <% else %>
                            <span class="text-gray-400 italic">Sin email</span>
                          <% end %>
                        </td>
                      <% end %>
                      <%= if @visible_columns["forma_pago"] do %>
                        <td class="px-6 py-4 text-sm text-gray-700 border-r border-gray-100/50"><%= cliente.forma_pago %></td>
                      <% end %>
                      <%= if @visible_columns["metodo_pago"] do %>
                        <td class="px-6 py-4 text-sm text-gray-700 border-r border-gray-100/50"><%= cliente.metodo_pago %></td>
                      <% end %>
                      <%= if @visible_columns["estatus"] do %>
                        <td class="px-6 py-4 text-sm text-center">
                          <span class={[
                            "inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold shadow-sm",
                            if(cliente.estatus == "ACTIVO", do: "bg-gradient-to-r from-emerald-500 to-emerald-600 text-white", else: "bg-gradient-to-r from-gray-400 to-gray-500 text-white")
                          ]}>
                            <span class="w-1.5 h-1.5 rounded-full bg-white"></span>
                            <%= cliente.estatus %>
                          </span>
                        </td>
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
