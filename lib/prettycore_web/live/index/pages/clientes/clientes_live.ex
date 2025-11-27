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

end
