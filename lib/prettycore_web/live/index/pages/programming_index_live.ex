defmodule PrettycoreWeb.ProgrammingIndexLive do
  use PrettycoreWeb, :live_view

  import PrettycoreWeb.PlatformLayout
  alias Prettycore.TdsClient

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "programacion_sql")
     |> assign(:show_programacion_children, true)
     |> assign(:sql_query, "SELECT * FROM SYS_UDN;")
     |> assign(:columns, [])
     |> assign(:rows, [])
     |> assign(:error, nil)}
  end

  ## Navegación del menú
  def handle_event("change_page", %{"id" => "inicio"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/platform")}
  end

  def handle_event("change_page", %{"id" => "programacion"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/programacion")}
  end

  def handle_event("change_page", %{"id" => "programacion_sql"}, socket) do
    {:noreply, socket} # ya estás aquí
  end

    def handle_event("change_page", %{"id" => "workorder"}, socket) do
    {:noreply, push_navigate(socket, to: ~p"/ui/workorder")}
  end


  def handle_event("change_page", _params, socket) do
    {:noreply, socket}
  end


  ## Ejecutar SQL
  def handle_event("run_sql", %{"sql_query" => query}, socket) do
    sql =
      query
      |> String.trim()
      |> String.replace(~r/\"([^"]*)\"/, "'\\1'")

    cond do
      sql == "" ->
        {:noreply, assign(socket, :error, "Escribe una consulta.")}

      not allowed_sql?(sql) ->
        {:noreply, assign(socket, :error, "Solo se permiten consultas SELECT o UPDATE.")}

      true ->
        case TdsClient.query(sql, []) do
          {:ok, %Tds.Result{columns: cols, rows: rows} = res} ->
            if is_list(cols) and cols != [] do
              columns = Enum.map(cols, &to_string/1)

              rows_norm =
                Enum.map(rows || [], fn row ->
                  Enum.map(row, &norm/1)
                end)

              {:noreply,
               socket
               |> assign(:sql_query, query)
               |> assign(:error, nil)
               |> assign(:columns, columns)
               |> assign(:rows, rows_norm)}
            else
              {:noreply,
               socket
               |> assign(:sql_query, query)
               |> assign(:error, nil)
               |> assign(:columns, ["Resultado"])
               |> assign(:rows, [[
                 "Comando ejecutado con éxito (#{res.num_rows || 0} filas afectadas)"
               ]])}
            end

          {:error, reason} ->
            {:noreply,
             socket
             |> assign(:sql_query, query)
             |> assign(:error, "Error al ejecutar: #{inspect(reason)}")
             |> assign(:columns, [])
             |> assign(:rows, [])}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <.platform_shell
      current_page={@current_page}
      show_programacion_children={@show_programacion_children}
    >
      <section>
        <header class="pc-page-header">
          <h1>Programación · Herramienta SQL</h1>
          <p>
            Ejecuta consultas SELECT o UPDATE directamente contra tu base SQL Server.
          </p>
        </header>

        <div class="pc-page-card sql-console">
          <form phx-submit="run_sql">
            <label class="sql-console-label">
              Consulta SQL
            </label>
            <textarea
              name="sql_query"
              class="sql-editor"
              rows="6"
            ><%= @sql_query %></textarea>

            <div class="sql-console-actions">
              <button type="submit" class="sql-run-btn">
                Ejecutar consulta
              </button>
              <span class="sql-console-hint">
                Se permiten SELECT y UPDATE.
              </span>
            </div>
          </form>

          <%= if @error do %>
            <div class="sql-console-error">
              <%= @error %>
            </div>
          <% end %>
        </div>

        <%= if @columns != [] do %>
          <div class="pc-page-card sql-result-card">
            <div class="sql-result-header">
              <span>Resultados</span>
              <span class="sql-result-meta">
                <%= length(@rows) %> filas
              </span>
            </div>

            <div class="sql-result-wrapper">
              <table class="sql-result-table">
                <thead>
                  <tr>
                    <%= for col <- @columns do %>
                      <th><%= col %></th>
                    <% end %>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- @rows do %>
                    <tr>
                      <%= for cell <- row do %>
                        <td><%= cell %></td>
                      <% end %>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          </div>
        <% end %>
      </section>
    </.platform_shell>
    """
  end

  ## Helpers

  defp allowed_sql?(sql) do
    up = sql |> String.trim_leading() |> String.upcase()
    String.starts_with?(up, "SELECT") or String.starts_with?(up, "UPDATE")
  end

  defp norm(v) when is_binary(v), do: :unicode.characters_to_binary(v, :latin1, :utf8)

  defp norm({{y, m, d}, {hh, mm, ss, ms}}),
    do: NaiveDateTime.new!(y, m, d, hh, mm, ss, {ms, 3}) |> NaiveDateTime.to_iso8601()

  defp norm({{y, m, d}, {hh, mm, ss}}),
    do: NaiveDateTime.new!(y, m, d, hh, mm, ss, 0) |> NaiveDateTime.to_iso8601()

  defp norm({y, m, d}), do: Date.new!(y, m, d) |> Date.to_iso8601()
  defp norm(%Decimal{} = d), do: Decimal.to_string(d)
  defp norm(nil), do: ""
  defp norm(v), do: v
end
