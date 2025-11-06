defmodule PrettycoreWeb.PlatformLayout do
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
  slot :inner_block, required: true

  def platform_shell(assigns) do
    assigns = assign(assigns, :menu_items, @menu)

    ~H"""
    <div class="pc-platform">
      <!-- Sidebar -->
      <aside class="pc-platform-sidebar">
        <!-- BLOQUE FIJO (logo + NAVEGACIÓN) -->
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

              <%= if item.id == "programacion" and @show_programacion_children do %>
                <div class="pc-submenu">
                  <button
                    type="button"
                    class={submenu_item_class("programacion_sql", @current_page)}
                    phx-click={@menu_event}
                    phx-value-id="programacion_sql"
                  >
                    Herramienta SQL
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
        </div>
      </aside>

      <!-- Contenido derecho -->
      <main class="pc-platform-main">
        <%= render_slot(@inner_block) %>
      </main>
    </div>
    """
  end

  ## ICONOS SVG SÓLIDOS, COLOR CONTROLADO POR CSS (currentColor)

  attr :name, :string, required: true
  def pc_icon(assigns) do
    ~H"""
    <%= case @name do %>
      <% "inicio" -> %>
        <!-- Casa sólida -->
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill="currentColor"
            d="M10 21v-5h4v5h4.5c.8 0 1.5-.7 1.5-1.5V11l-8-6-8 6v8.5c0 .8.7 1.5 1.5 1.5H10Z"
          />
        </svg>

      <% "programacion" -> %>
        <!-- Monitor sólido -->
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill="currentColor"
            d="M4 4c-1.1 0-2 .9-2 2v8c0 1.1.9 2 2 2h6v2H8c-.6 0-1 .4-1 1s.4 1 1 1h8c.6 0 1-.4 1-1s-.4-1-1-1h-2v-2h6c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2H4Zm0 2h16v8H4V6Z"
          />
        </svg>

      <% "workorder" -> %>
        <!-- Documento / lista sólido -->
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill="currentColor"
            d="M8 3c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8c1.1 0 2-.9 2-2V8.5L13.5 3H8Zm5 1.5L17.5 9H13V4.5ZM9 11h6c.6 0 1 .4 1 1s-.4 1-1 1H9c-.6 0-1-.4-1-1s.4-1 1-1Zm0 4h4c.6 0 1 .4 1 1s-.4 1-1 1H9c-.6 0-1-.4-1-1s.4-1 1-1Z"
          />
        </svg>

      <% "config" -> %>
        <!-- Engrane sólido -->
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path
            fill="currentColor"
            d="M10.7 2.3c.4-.6 1.2-.6 1.6 0l1 1.6c.2.3.5.5.9.6l1.8.5c.7.2 1.1.9.9 1.5l-.5 1.8c-.1.3 0 .7.3 1l1.4 1.4c.5.5.5 1.3 0 1.8l-1.4 1.4c-.3.3-.4.6-.3 1l.5 1.8c.2.7-.2 1.4-.9 1.5l-1.8.5c-.4.1-.7.3-.9.6l-1 1.6c-.4.6-1.2.6-1.6 0l-1-1.6c-.2-.3-.5-.5-.9-.6l-1.8-.5c-.7-.2-1.1-.9-.9-1.5l.5-1.8c.1-.3 0-.7-.3-1L4 13.5c-.5-.5-.5-1.3 0-1.8l1.4-1.4c.3-.3.4-.6.3-1L5.2 7.5c-.2-.7.2-1.4.9-1.5l1.8-.5c.4-.1.7-.3.9-.6l1-1.6Zm1.3 7.2a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7Z"
          />
        </svg>

      <% _ -> %>
        <!-- Fallback círculo sólido -->
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
