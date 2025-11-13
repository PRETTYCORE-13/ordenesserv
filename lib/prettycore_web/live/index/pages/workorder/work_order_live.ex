defmodule PrettycoreWeb.WorkOrderLive do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout
  alias Prettycore.Workorders
  alias Prettycore.WorkorderApi

  # NUEVO: para el SELECT con Ecto
  alias Prettycore.Repo
  alias Prettycore.Auth.User
  import Ecto.Query, only: [from: 2]

  ## MOUNT

  def mount(%{"email" => email} = _params, _session, socket) do
    {workorders, db_error} =
      case Workorders.list_enc() do
        {:ok, list}    -> {list, false}
        {:error, _err} -> {[],  true}
      end

    {:ok,
     socket
     |> assign(:current_page, "workorder")
     |> assign(:show_programacion_children, false)
     |> assign(:sidebar_open, true)
     |> assign(:workorders, workorders)
     |> assign(:db_error, db_error)
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})
     |> assign(:filter, "por_aceptar")
     |> assign(:sysudn_filter, "")
     |> assign(:fecha_desde, "")
     |> assign(:fecha_hasta, "")
     |> assign(:usuario_filter, "")
     |> assign(:filters_open, false)
     |> assign(:page, 1)
     |> assign(:current_user_email, email)
     |> assign(:current_path, "/admin/workorder/#{email}")}
  end

  ## Navegación / toggle sidebar

  def handle_event("change_page", %{"id" => "toggle_sidebar"}, socket) do
    {:noreply, update(socket, :sidebar_open, fn open -> not open end)}
  end

  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/platform/#{email}")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion/#{email}")}
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql/#{email}")}
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
    # ya estás aquí; si quieres puedes quedarte en la misma página
    {:noreply, socket}
  end

  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end

  # Paginación: siguiente / anterior
  def handle_event("goto_page", %{"dir" => "prev"}, socket) do
    {:noreply, update(socket, :page, fn p -> max(p - 1, 1) end)}
  end

  def handle_event("goto_page", %{"dir" => "next"}, socket) do
    {:noreply, update(socket, :page, fn p -> p + 1 end)}
  end

  ## Cambiar estado (API Aceptar / Rechazar)
  ## AQUÍ ES DONDE SE HACE SIEMPRE EL SELECT EXTRA ANTES DE LLAMAR AL API

  def handle_event("cambiar_estado", %{"ref" => ref, "estado" => estado_str}, socket) do
    estado = String.to_integer(estado_str)

    # 1) Sacar el código del usuario actual (ajusta si tu clave no es el email)
    sysusr_codigo = socket.assigns.current_user_email

    # 2) Hacer el SELECT SYSUSR_PASSWORD FROM SYS_USUARIO WHERE SYSUSR_CODIGO_K = @SYSUSR_CODIGO_K
    password_query =
      from u in User,
        where: u.sysusr_codigo_k == ^sysusr_codigo,
        select: u.sysusr_password

    case Repo.one(password_query) do
      nil ->
        IO.puts("No se encontró SYSUSR_PASSWORD para #{sysusr_codigo}")
        {:noreply, socket}

      password ->
        # 3) Llamar al API con el password obtenido
        case WorkorderApi.cambiar_estado(ref, estado, password) do
          {:ok, _body} ->
            {workorders, db_error} =
              case Workorders.list_enc() do
                {:ok, list}    -> {list, false}
                {:error, _err} -> {socket.assigns.workorders, true}
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

  ## Filtro básico (Todas / Pendientes)

  def handle_event("set_filter", %{"filter" => filter}, socket) do
    {:noreply, assign(socket, :filter, filter)}
  end

  ## Toggle drawer de filtros

  def handle_event("toggle_filters", _params, socket) do
    {:noreply, update(socket, :filters_open, fn open -> not open end)}
  end

  ## Filtros avanzados (UDN, rango de fechas, usuario)

  def handle_event("set_filters", params, socket) do
    {:noreply,
     socket
     |> assign(:sysudn_filter, Map.get(params, "sysudn", ""))
     |> assign(:fecha_desde, Map.get(params, "fecha_desde", ""))
     |> assign(:fecha_hasta, Map.get(params, "fecha_hasta", ""))
     |> assign(:usuario_filter, Map.get(params, "usuario", ""))}
  end

  ## Abrir / cerrar detalle

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

    open_key =
      if socket.assigns.open_key == key do
        nil
      else
        key
      end

    {:noreply,
     socket
     |> assign(:detalles, Map.put(detalles_cache, key, detalles))
     |> assign(:open_key, open_key)}
  end

  ## Helpers

  defp image_src(nil), do: nil

  defp image_src(url) when is_binary(url) do
    trimmed = String.trim(url)
    if trimmed == "", do: nil, else: trimmed
  end

  defp filter_workorders(workorders, "todas"), do: workorders

  defp filter_workorders(workorders, "por_aceptar") do
    Enum.filter(workorders, &(&1.estado == 100))
  end

  defp filter_workorders(workorders, _), do: workorders

  ## Render

end
