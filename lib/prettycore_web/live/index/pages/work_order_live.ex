defmodule PrettycoreWeb.WorkOrder do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.PlatformLayout
  alias Prettycore.Workorders
  alias Prettycore.WorkorderApi

  def mount(_params, _session, socket) do
    workorders = Workorders.list_enc()

    {:ok,
     socket
     |> assign(:current_page, "workorder")
     |> assign(:show_programacion_children, false)
     |> assign(:sidebar_open, true)
     |> assign(:workorders, workorders)
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})
     |> assign(:filter, "por_aceptar")}
  end

  ## Navegación
  def handle_event("change_page", %{"id" => "toggle_sidebar"}, socket),
    do: {:noreply, update(socket, :sidebar_open, fn open -> not open end)}

  def handle_event("change_page", %{"id" => "inicio"}, socket),
    do: {:noreply, push_navigate(socket, to: ~p"/admin/platform")}

  def handle_event("change_page", %{"id" => "programacion"}, socket),
    do: {:noreply, push_navigate(socket, to: ~p"/admin/programacion")}

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket),
    do: {:noreply, push_navigate(socket, to: ~p"/admin/programacion/sql")}

  def handle_event("change_page", _params, socket), do: {:noreply, socket}

  ## Cambiar estado
  def handle_event("cambiar_estado", %{"folio" => folio, "estado" => estado_str}, socket) do
    estado = String.to_integer(estado_str)

    case WorkorderApi.cambiar_estado(folio, estado) do
      {:ok, _body} ->
        workorders = Workorders.list_enc()
        {:noreply, assign(socket, :workorders, workorders)}

      {:error, reason} ->
        IO.inspect(reason, label: "error cambiar_estado")
        {:noreply, socket}
    end
  end

  ## Filtros
  def handle_event("set_filter", %{"filter" => filter}, socket),
    do: {:noreply, assign(socket, :filter, filter)}

  ## Abrir / cerrar detalle
  def handle_event("toggle_detalle", %{"sysudn" => sysudn, "serie" => serie, "folio" => folio}, socket) do
    key = "#{sysudn}|#{serie}|#{folio}"

    detalles_cache = socket.assigns.detalles
    detalles = Map.get(detalles_cache, key) || Workorders.list_det(sysudn, serie, folio)
    open_key = if socket.assigns.open_key == key, do: nil, else: key

    {:noreply,
     socket
     |> assign(:detalles, Map.put(detalles_cache, key, detalles))
     |> assign(:open_key, open_key)}
  end

  ## Helpers
  defp image_src(nil), do: nil
  defp image_src(url) when is_binary(url),
    do: (t = String.trim(url); if t == "", do: nil, else: t)

  defp filter_workorders(workorders, "todas"), do: workorders
  defp filter_workorders(workorders, "por_aceptar"),
    do: Enum.filter(workorders, &(&1.estado == 100))
  defp filter_workorders(workorders, _), do: workorders

  ## Render
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <.platform_shell
      current_page={@current_page}
      show_programacion_children={@show_programacion_children}
      sidebar_open={@sidebar_open}
    >
      <% filtered = filter_workorders(@workorders, @filter) %>

      <section class="wo-page">
        <header class="wo-header">
          <div class="wo-hero-main">
            <div class="wo-hero-icon">🛠️</div>
            <div>
              <h1 class="wo-title">Órdenes de trabajo</h1>
              <p class="wo-subtitle">Visualiza tus órdenes y las imágenes asociadas.</p>
            </div>
          </div>

          <div class="wo-header-right">
            <div class="wo-stats">
              <div class="wo-stat-card">
                <span class="wo-stat-label">Total de órdenes</span>
                <span class="wo-stat-value"><%= length(filtered) %></span>
              </div>
            </div>

            <div class="wo-filters">
              <button
                type="button"
                class={"wo-filter-btn" <> if @filter == "todas", do: " wo-filter-btn-active", else: ""}
                phx-click="set_filter"
                phx-value-filter="todas"
              >Todas</button>

              <button
                type="button"
                class={"wo-filter-btn" <> if @filter == "por_aceptar", do: " wo-filter-btn-active", else: ""}
                phx-click="set_filter"
                phx-value-filter="por_aceptar"
              >Pendientes</button>
            </div>
          </div>
        </header>

        <div class="wo-table-card">
          <%= if filtered == [] do %>
            <div class="wo-empty">
              <div class="wo-empty-icon">📭</div>
              <h2 class="wo-empty-title">Sin órdenes registradas</h2>
              <p class="wo-empty-text">No hay órdenes para el filtro seleccionado.</p>
            </div>
          <% else %>
            <div class="wo-table-wrapper">
              <table class="wo-table">
                <thead>
                  <tr>
                    <th>Identificador</th>
                    <th>Descripción</th>
                    <th>Tipo</th>
                    <th class="wo-th-center">Acciones</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for w <- filtered do %>
                    <% key = "#{w.sysudn}|#{w.serie}|#{w.folio}" %>

                    <tr
                      class={"wo-row" <> if @open_key == key, do: " wo-row-open", else: ""}
                      phx-click="toggle_detalle"
                      phx-value-sysudn={w.sysudn}
                      phx-value-serie={w.serie}
                      phx-value-folio={w.folio}
                    >
                      <td><%= "#{w.sysudn} #{w.serie} #{w.folio}" %></td>
                      <td><%= Map.get(w, :descripcion, "") %></td>
                      <td><span class="wo-row-meta-badge"><%= w.tipo %></span></td>

                      <td class="wo-td-center">
                        <%= if @filter != "todas" do %>
                          <button
                            type="button"
                            class="wo-btn wo-btn-accept"
                            phx-click="cambiar_estado"
                            phx-value-folio={w.folio}
                            phx-value-estado="1"
                            phx-bubble="false"
                          >Aceptar</button>

                          <button
                            type="button"
                            class="wo-btn wo-btn-reject"
                            phx-click="cambiar_estado"
                            phx-value-folio={w.folio}
                            phx-value-estado="0"
                            phx-bubble="false"
                          >Rechazar</button>
                        <% else %>
                          <span class="wo-disabled">—</span>
                        <% end %>
                      </td>
                    </tr>

                    <%= if @open_key == key do %>
                      <tr class="wo-row-detail">
                        <td colspan="4">
                          <div class="wo-detail-grid">
                            <% detalles = Map.get(@detalles, key, []) %>
                            <% visibles =
                              Enum.filter(detalles, fn d ->
                                src = image_src(Map.get(d, :image_url) || Map.get(d, :image_data))
                                not is_nil(src)
                              end) %>

                            <%= if visibles == [] do %>
                              <div class="wo-detail-img wo-detail-img-empty">Sin imágenes</div>
                            <% else %>
                              <%= for det <- visibles do %>
                                <% src =
                                  image_src(
                                    Map.get(det, :image_url) ||
                                      Map.get(det, :image_data)
                                  ) %>
                                <div class="wo-detail-card">
                                  <div class="wo-detail-meta">
                                    <span class="wo-detail-label">
                                      <%= Map.get(det, :descripcion) ||
                                          Map.get(det, :concepto) ||
                                          "Detalle" %>
                                    </span>
                                  </div>
                                  <img class="wo-detail-img" src={src} alt="Imagen" />
                                </div>
                              <% end %>
                            <% end %>
                          </div>
                        </td>
                      </tr>
                    <% end %>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </section>
    </.platform_shell>
    """
  end
end
