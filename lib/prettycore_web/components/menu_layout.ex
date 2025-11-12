defmodule PrettycoreWeb.MenuLayout do
  use Phoenix.Component

  @menu [
    %{id: "inicio",       label: "Inicio"},
    %{id: "programacion", label: "Programación"},
    %{id: "workorder",    label: "Workorder"}
  ]

  # Props y slot
  attr :current_page, :string, required: true
  attr :menu_event, :string, default: "change_page"
  attr :show_programacion_children, :boolean, default: false
  attr :sidebar_open, :boolean, default: true
  slot :inner_block, required: true

  def sidebar(assigns) do
    assigns = assign(assigns, :menu_items, @menu)

    ~H"""
    <div class="pc-platform">
      <!-- Sidebar -->
      <aside class={"pc-platform-sidebar" <> if @sidebar_open, do: " pc-platform-sidebar-open", else: ""}>
        <!-- BLOQUE FIJO (logo + toggle) -->
        <div class="pc-platform-sidebar-top">
          <div class="pc-platform-logo-group">
            <img
              class="pc-platform-logo-img"
              src="https://prettycore.xyz/IMAGENES/Logo%20Prettycore%20(8).png"
              alt="PrettyCore logo"
            />
            <div class="pc-platform-logo-text">
              <span class="pc-platform-logo-title">PrettyCore</span>
              <span class="pc-platform-logo-subtitle">Negocios</span>
            </div>
          </div>

          <!-- Botón toggle de abrir/cerrar -->
          <button
            type="button"
            class="pc-menu-item pc-menu-toggle"
            phx-click={@menu_event}
            phx-value-id="toggle_sidebar"
          >
            <span class="pc-menu-item-indicator" />
            <span class="pc-menu-item-icon">
              <%= if @sidebar_open do %>
                <!-- icono cerrar -->
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path fill="currentColor" d="M15 4a1 1 0 0 1 .7 1.7L11.4 10l4.3 4.3A1 1 0 1 1 14.3 16L9.6 11.3a1 1 0 0 1 0-1.4L14.3 5A1 1 0 0 1 15 4Z"/>
                </svg>
              <% else %>
                <!-- icono abrir -->
                <svg viewBox="0 0 24 24" aria-hidden="true">
                  <path fill="currentColor" d="M9 4a1 1 0 0 0-.7 1.7L12.6 10l-4.3 4.3A1 1 0 0 0 9.7 16l4.7-4.7a1 1 0 0 0 0-1.4L9.7 5A1 1 0 0 0 9 4Z"/>
                </svg>
              <% end %>
            </span>
            <span class="pc-menu-item-label">Menú</span>
          </button>
        </div>

        <!-- BLOQUE MENÚ (iconos + config) -->
        <div class="pc-platform-sidebar-body">
          <nav class="pc-platform-menu">
            <%= for item <- @menu_items do %>
              <button
                type="button"
                class={menu_item_class(menu_active?(item.id, @current_page))}
                phx-click={@menu_event}
                phx-value-id={item.id}
              >
                <span class="pc-menu-item-indicator" />
                <span class="pc-menu-item-icon">
                  <.pc_icon name={item.id} />
                </span>
                <span class="pc-menu-item-label"><%= item.label %></span>
              </button>

              <!-- Submenú de Programación -->
              <%= if item.id == "programacion" and @show_programacion_children do %>
                <div class="pc-submenu">
                  <button
                    type="button"
                    class={submenu_item_class("programacion_sql", @current_page)}
                    phx-click={@menu_event}
                    phx-value-id="programacion_sql"
                  >
                    <span class="pc-submenu-item-icon">
                      <.pc_icon name="programacion_sql" />
                    </span>
                    <span class="pc-submenu-item-label">Herramienta SQL</span>
                  </button>
                </div>
              <% end %>
            <% end %>
          </nav>

          <!-- Botón de configuración abajo -->
          <button
            type="button"
            class={menu_item_class(menu_active?("config", @current_page)) <> " pc-menu-item-bottom"}
            phx-click={@menu_event}
            phx-value-id="config"
          >
            <span class="pc-menu-item-indicator" />
            <span class="pc-menu-item-icon">
              <.pc_icon name="config" />
            </span>
            <span class="pc-menu-item-label">Configuración</span>
          </button>

          <!-- Cerrar sesión -->
          <.link
            href={"/ui/logout"}
            class="pc-menu-item pc-menu-item-bottom"
            data-confirm="¿Cerrar sesión?"
          >
            <span class="pc-menu-item-indicator" />
            <span class="pc-menu-item-icon">
              <.pc_icon name="logout" />
            </span>
            <span class="pc-menu-item-label">Cerrar sesión</span>
          </.link>
        </div>
      </aside>

      <!-- Contenido derecho -->
      <main class="pc-platform-main">
        <%= render_slot(@inner_block) %>
      </main>
    </div>
    """
  end

  ## ICONOS SVG SÓLIDOS
  attr :name, :string, required: true
  def pc_icon(assigns) do
    ~H"""
    <%= case @name do %>
      <% "inicio" -> %>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="currentColor" d="M10 21v-5h4v5h4.5c.8 0 1.5-.7 1.5-1.5V11l-8-6-8 6v8.5c0 .8.7 1.5 1.5 1.5H10Z"/>
        </svg>

      <% "programacion" -> %>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="currentColor" d="M4 4c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h6v2H8c-.6 0-1 .4-1 1s.4 1 1 1h8c.6 0 1-.4 1-1s-.4-1-1-1h-2v-2h6c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2H4Zm0 2h16v8H4V6Z"/>
        </svg>

      <% "workorder" -> %>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="currentColor" d="M8 3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V8.5L13.5 3H8Zm5 1.5L17.5 9H13V4.5ZM9 11h6c.6 0 1 .4 1 1s-.4 1-1 1H9c-.6 0-1-.4-1-1s.4-1 1-1Zm0 4h4c.6 0 1 .4 1 1s-.4 1-1 1H9c-.6 0-1-.4-1-1Z"/>
        </svg>

      <% "config" -> %>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="currentColor" d="M10.7 2.3c.4-.6 1.2-.6 1.6 0l1 1.6c.2.3.5.5.9.6l1.8.5c.7.2 1.1.9.9 1.5l-.5 1.8c-.1.3 0 .7.3 1l1.4 1.4c.5.5.5 1.3 0 1.8l-1.4 1.4c-.3.3-.4.6-.3 1l.5 1.8c.2.7-.2 1.4-.9 1.5l-1.8.5c-.4.1-.7.3-.9.6l-1 1.6c-.4.6-1.2.6-1.6 0l-1-1.6c-.2-.3-.5-.5-.9-.6l-1.8-.5c-.7-.2-1.1-.9-.9-1.5l.5-1.8c.1-.3 0-.7-.3-1L4 13.5c-.5-.5-.5-1.3 0-1.8l1.4-1.4c.3-.3.4-.6.3-1L5.2 7.5c-.2-.7.2-1.4.9-1.5l1.8-.5c.4-.1.7-.3.9-.6l1-1.6Zm1.3 7.2a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Z"/>
        </svg>

      <% "programacion_sql" -> %>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="currentColor" d="M12 3C7.6 3 4 4.3 4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6c0-1.7-3.6-3-8-3Zm0 2c3.9 0 6 .9 6 1s-2.1 1-6 1-6-.9-6-1 2.1-1 6-1Zm0 5c3.9 0 6-.9 6-1.1V11c0 .1-2.1 1-6 1s-6-.9-6-1V8.9C6 9.1 8.1 10 12 10Zm0 6c3.9 0 6-.9 6-1.1V17c0 .1-2.1 1-6 1s-6-.9-6-1v-2.1c0 .2 2.1 1.1 6 1.1Z"/>
        </svg>

      <% "logout" -> %>
        <!-- Flecha salir -->
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="currentColor" d="M10 4a1 1 0 0 1 1 1v3h2V5a3 3 0 0 0-3-3H7a3 3 0 0 0-3 3v14a3 3 0 0 0 3 3h3a3 3 0 0 0 3-3v-3h-2v3a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h3Zm6.3 6.3a1 1 0 1 0-1.4 1.4l1.6 1.3H11a1 1 0 1 0 0 2h5.5l-1.6 1.3a1 1 0 1 0 1.2 1.6l3.5-3a1 1 0 0 0 0-1.5l-3.5-3Z"/>
        </svg>

      <% _ -> %>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <circle cx="12" cy="12" r="8" fill="currentColor" />
        </svg>
    <% end %>
    """
  end

  ## Helpers

  defp menu_active?("programacion", current)
       when current in ["programacion", "programacion_sql"],
       do: true

  defp menu_active?(id, current), do: id == current

  defp menu_item_class(true), do: "pc-menu-item pc-menu-item-active"
  defp menu_item_class(false), do: "pc-menu-item"

  defp submenu_item_class(id, current) do
    if id == current do
      "pc-submenu-item pc-submenu-item-active"
    else
      "pc-submenu-item"
    end
  end
end
