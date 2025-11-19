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
    workorders=Prettycore.Workorders.list_enc()

    {:ok,
     socket
     |> assign(:current_page, "workorder")
     |> assign(:show_programacion_children, false)
     |> assign(:sidebar_open, true)
     |> assign(:workorders, workorders)
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

  def handle_params(params, uri, socket) do
IO.inspect(params: params)
{:noreply, socket}

    {:noreply,
     socket
     |> assign(:sysudn_filter, Map.get(params, "sysudn", ""))
     |> assign(:fecha_desde, Map.get(params, "fecha_desde", ""))
     |> assign(:fecha_hasta, Map.get(params, "fecha_hasta", ""))
     |> assign(:usuario_filter, Map.get(params, "usuario", ""))
     |> assign(:filter, Map.get(params, "estado"))
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})}


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
            {workorders, db_error} =
              case Workorders.list_enc() do
                {:ok, list} -> {list, false}
                {:error, _} -> {socket.assigns.workorders, true}
              end

            {:noreply,
             socket
             |> assign(:workorders, workorders)
             |> assign(:db_error, db_error)}

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

  defp filter_workorders(workorders, "todas"), do: workorders
  defp filter_workorders(workorders, "por_aceptar"), do: Enum.filter(workorders, &(&1.estado == 100))
  defp filter_workorders(workorders, _), do: workorders

  defp estado_label(100), do: "Pendiente"
  defp estado_label(500), do: "Atendida"
  defp estado_label(600), do: "Cancelado"
  defp estado_label(_),   do: "Desconocido"

  defp estado_class(100), do: "wo-state wo-state-pendiente"
  defp estado_class(500), do: "wo-state wo-state-atendida"
  defp estado_class(600), do: "wo-state wo-state-cancelado"
  defp estado_class(_),   do: "wo-state"
end
