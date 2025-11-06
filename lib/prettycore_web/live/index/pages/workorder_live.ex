defmodule PrettycoreWeb.WorkorderLive do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.PlatformLayout
  alias Prettycore.Workorders

  def mount(_params, _session, socket) do
    workorders = Workorders.list_enc()

    {:ok,
     socket
     |> assign(:current_page, "workorder")
     |> assign(:show_programacion_children, false)
     |> assign(:workorders, workorders)
     |> assign(:open_key, nil)
     |> assign(:detalles, %{})}
  end

  # Navegación menú
  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/platform")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/programacion")}
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/programacion/sql")}
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
    {:noreply, socket}
  end

  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end

  # Abrir / cerrar detalle
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

  # arma src usable por <img> (por si luego la usas)
  defp image_src(nil), do: nil

  defp image_src(data) when is_binary(data) do
    trimmed = String.trim(data)

    cond do
      trimmed == "" ->
        nil

      String.starts_with?(trimmed, "data:image") ->
        trimmed

      true ->
        "data:image/png;base64," <> trimmed
    end
  end

def render(assigns) do
  ~H"""
  <.platform_shell
    current_page={@current_page}
    show_programacion_children={@show_programacion_children}
  >
    <section class="wo-page">
      <header class="wo-header">
        <div class="wo-hero-main">
          <div class="wo-hero-icon">🛠️</div>
          <div>
            <h1 class="wo-title">Órdenes de trabajo</h1>
            <p class="wo-subtitle">
              Visualiza tus órdenes y la imagen asociada almacenada en base64.
            </p>
          </div>
        </div>

        <div class="wo-stats">
          <div class="wo-stat-card">
            <span class="wo-stat-label">Total de órdenes</span>
            <span class="wo-stat-value"><%= length(@workorders) %></span>
          </div>
        </div>
      </header>

      <div class="wo-table-card">
        <%= if @workorders == [] do %>
          <div class="wo-empty">
            <div class="wo-empty-icon">📭</div>
            <h2 class="wo-empty-title">Sin órdenes registradas</h2>
            <p class="wo-empty-text">Cuando se generen nuevas órdenes aparecerán aquí.</p>
          </div>
        <% else %>
          <div class="wo-table-wrapper">
            <table class="wo-table">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Referencia</th>
                  <th>Tipo</th>
                  <th class="wo-th-center">UDN</th>
                  <th class="wo-th-center">Transacción</th>
                  <th class="wo-th-center">Serie</th>
                  <th class="wo-th-right">Folio</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <%= for {w, idx} <- Enum.with_index(@workorders, 1) do %>
                  <% key = "#{w.sysudn}|#{w.systra}|#{w.serie}|#{w.folio}" %>

                  <tr
                    class={
                      "wo-row " <>
                        if(@open_key == key, do: "wo-row--open", else: "")
                    }
                    phx-click="toggle_detalle"
                    phx-value-sysudn={w.sysudn}
                    phx-value-systra={w.systra}
                    phx-value-serie={w.serie}
                    phx-value-folio={w.folio}
                  >
                    <td class="wo-row-indicator">
                      <span><%= idx %></span>
                    </td>

                    <td>
                      <div class="wo-row-primary">
                        <span class="wo-row-ref"><%= w.referencia %></span>
                      </div>
                    </td>

                    <td>
                      <span class="wo-row-meta-badge"><%= w.tipo %></span>
                    </td>

                    <td class="wo-td-center"><%= w.sysudn %></td>
                    <td class="wo-td-center"><%= w.systra %></td>
                    <td class="wo-td-center"><%= w.serie %></td>
                    <td class="wo-td-right"><%= w.folio %></td>

                    <td class="wo-row-toggle-cell">
                      <div class={
                        "wo-row-toggle " <>
                          if(@open_key == key, do: "wo-row-toggle--open", else: "")
                      }>
                        <span class="wo-row-toggle-text">
                          <%= if @open_key == key, do: "Ocultar detalle", else: "Ver detalle" %>
                        </span>
                        <span class="wo-row-toggle-icon">▾</span>
                      </div>
                    </td>
                  </tr>

                  <%= if @open_key == key do %>
                    <tr class="wo-row-details">
                      <td colspan="8">
                        <div class="wo-details">
                          <h4 class="wo-details-title">Cadena Base64 del detalle</h4>

                          <%= for d <- Map.get(@detalles, key, []) do %>
                            <div class="wo-detail-row">
                              <pre class="wo-detail-code">
<%= d.image_data || "SIN DATOS BASE64" %>
                              </pre>
                            </div>
                          <% end %>

                          <%= if Map.get(@detalles, key, []) == [] do %>
                            <p class="wo-no-details">
                              No se encontró detalle para esta orden.
                            </p>
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
