defmodule PrettycoreWeb.WorkOrderLive do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout
  alias Prettycore.Workorders
  alias Prettycore.WorkorderApi
  alias Prettycore.Repo
  alias Prettycore.Auth.User
  import Ecto.Query, only: [from: 2]

  ## MOUNT
  @impl true
  def mount(_params, session, socket) do
    # Initialize with default filters (por_aceptar)
    filters = %{estado: "por_aceptar"}
    workorders = Workorders.list_enc_filtered(filters)

    # Get all workorders once for filter options
    all_workorders = Workorders.list_enc()

    sysudn_opts =
      all_workorders
      |> Enum.map(& &1.sysudn)
      |> Enum.reject(&is_nil/1)
      |> Enum.uniq()
      |> Enum.sort()

    usuario_opts =
      all_workorders
      |> Enum.map(&Map.get(&1, :usuario))
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.uniq()
      |> Enum.sort()

    {:ok,
     socket
     |> assign(:current_page, "workorder")
     |> assign(:show_programacion_children, false)
     |> assign(:sidebar_open, true)
     |> assign(:workorders, workorders)
     |> assign(:sysudn_opts, sysudn_opts)
     |> assign(:usuario_opts, usuario_opts)
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})
     |> assign(:filter, "por_aceptar")
     |> assign(:sysudn_filter, "")
     |> assign(:fecha_desde, "")
     |> assign(:fecha_hasta, "")
     |> assign(:usuario_filter, "")
     |> assign(:filters_open, false)
     |> assign(:page, 1)
     |> assign(:current_path, "/admin/workorder")}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # Extract filter values from URL params
    sysudn = Map.get(params, "sysudn", "")
    fecha_desde = Map.get(params, "fecha_desde", "")
    fecha_hasta = Map.get(params, "fecha_hasta", "")
    usuario = Map.get(params, "usuario", "")
    estado = Map.get(params, "estado", "por_aceptar")

    # Build filters map for the query
    filters = %{
      estado: estado,
      sysudn: sysudn,
      usuario: usuario,
      fecha_desde: fecha_desde,
      fecha_hasta: fecha_hasta
    }

    # Load workorders with filters applied at database level
    workorders = Workorders.list_enc_filtered(filters)

    {:noreply,
     socket
     |> assign(:workorders, workorders)
     |> assign(:sysudn_filter, sysudn)
     |> assign(:fecha_desde, fecha_desde)
     |> assign(:fecha_hasta, fecha_hasta)
     |> assign(:usuario_filter, usuario)
     |> assign(:filter, estado)
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})
     |> assign(:page, 1)}
  end


  # ------------------------------------------------------------------
  # 🎯 MODELO 2: NAV CENTRALIZADA
  # ------------------------------------------------------------------
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
        {:noreply, socket}  # ya estás aquí

      "config" ->
        {:noreply, push_navigate(socket, to: ~p"/admin/configuracion")}

      _ ->
        {:noreply, socket}
    end
  end

  # ------------------------------------------------------------------
  # PAGINACIÓN
  # ------------------------------------------------------------------
  def handle_event("goto_page", %{"dir" => "prev"}, socket) do
    {:noreply, update(socket, :page, fn p -> max(p - 1, 1) end)}
  end

  def handle_event("goto_page", %{"dir" => "next"}, socket) do
    {:noreply, update(socket, :page, fn p -> p + 1 end)}
  end

  # ------------------------------------------------------------------
# CAMBIAR ESTADO (ACEPTAR / RECHAZAR)
  # ------------------------------------------------------------------
  def handle_event("cambiar_estado", %{"ref" => ref, "estado" => estado_str}, socket) do
    estado = String.to_integer(estado_str)
    sysusr_codigo = socket.assigns.current_user_email

    password_query =
      from u in User,
        where: u.sysusr_codigo_k == ^sysusr_codigo,
        select: u.sysusr_password

    case Repo.one(password_query) do
      nil ->
        IO.puts("No se encontró SYSUSR_PASSWORD para #{sysusr_codigo}")
        {:noreply, socket}

      password ->
        case WorkorderApi.cambiar_estado(ref, estado, password) do
          {:ok, _body} ->
            # Reload workorders with current filters
            filters = %{
              estado: socket.assigns.filter,
              sysudn: socket.assigns.sysudn_filter,
              usuario: socket.assigns.usuario_filter,
              fecha_desde: socket.assigns.fecha_desde,
              fecha_hasta: socket.assigns.fecha_hasta
            }

            workorders = Workorders.list_enc_filtered(filters)

            {:noreply,
             socket
             |> assign(:workorders, workorders)}

          {:error, reason} ->
            IO.inspect(reason, label: "error cambiar_estado")
            {:noreply, socket}
        end
    end
  end

  # ------------------------------------------------------------------
  # FILTROS BÁSICOS (Todas / Pendientes)
  # ------------------------------------------------------------------


  # ------------------------------------------------------------------
  # Drawer de filtros
  # ------------------------------------------------------------------
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, update(socket, :filters_open, fn open -> not open end)}
  end

  # ------------------------------------------------------------------
  # FILTROS AVANZADOS
  # ------------------------------------------------------------------
  def handle_event("set_filter", params, socket) do
    # Encapsulamos los parámetros
  clean_params =
    params
    |> Enum.reject(fn {_k, v} -> v in [nil, ""] end)
    |> Enum.into(%{})

  query = Plug.Conn.Query.encode(clean_params)

  {:noreply,
   push_patch(socket, to: "/admin/workorder?#{query}")}
  end

  # ------------------------------------------------------------------
  # ABRIR / CERRAR DETALLES
  # ------------------------------------------------------------------
  def handle_event(
        "toggle_detalle",
        %{"sysudn" => sysudn, "systra" => systra, "serie" => serie, "folio" => folio},
        socket
      ) do
    key = "#{sysudn}|#{systra}|#{serie}|#{folio}"

    detalles_cache = socket.assigns.detalles
    detalles =
      Map.get(detalles_cache, key) ||
        Workorders.list_det(sysudn, systra, serie, folio)

    open_key = if socket.assigns.open_key == key, do: nil, else: key

    {:noreply,
     socket
     |> assign(:detalles, Map.put(detalles_cache, key, detalles))
     |> assign(:open_key, open_key)}
  end

  # ------------------------------------------------------------------
  # HELPERS
  # ------------------------------------------------------------------
  defp image_src(nil), do: nil
  defp image_src(url) when is_binary(url) do
    trimmed = String.trim(url)
    if trimmed == "", do: nil, else: trimmed
  end

  defp estado_label(100), do: "Pendiente"
  defp estado_label(500), do: "Atendida"
  defp estado_label(600), do: "Cancelado"
  defp estado_label(_),   do: "Desconocido"

  defp estado_class(100), do: "wo-state wo-state-pendiente"
  defp estado_class(500), do: "wo-state wo-state-atendida"
  defp estado_class(600), do: "wo-state wo-state-cancelado"
  defp estado_class(_),   do: "wo-state"
end
