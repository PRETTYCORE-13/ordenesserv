defmodule PrettycoreWeb.HerramientaSql do
  use PrettycoreWeb, :live_view_admin

  import PrettycoreWeb.MenuLayout
  alias Prettycore.TdsClient
  alias Decimal

  # Ruta: /admin/programacion/sql/:email
  def mount(%{"email" => email} = _params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_page, "programacion_sql")
     |> assign(:show_programacion_children, true)
     |> assign(:sidebar_open, true)
     |> assign(:current_user_email, email)
     |> assign(:current_path, "/admin/programacion/sql/#{email}")
     |> assign(:sql_query, "SELECT * FROM SYS_UDN;")
     |> assign(:columns, [])
     |> assign(:rows, [])
     |> assign(:error, nil)}
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
    {:noreply, socket} # ya estás aquí
  end

  def handle_event("change_page", %{"id" => "workorder"}, socket) do
    email = socket.assigns.current_user_email
    {:noreply, push_navigate(socket, to: ~p"/admin/workorder/#{email}")}
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
        {:noreply,
         assign(
           socket,
           :error,
           "Solo se permiten SELECT, UPDATE, INSERT, DELETE, " <>
             "CREATE TABLE, CREATE VIEW, CREATE OR ALTER VIEW, ALTER TABLE o WITH (CTE)."
         )}

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

  ## Render

  def render(assigns) do
    ~H"""
      <section>
        <header class="pc-page-header">
          <h1>Programación · Herramienta SQL</h1>
          <p>
            Ejecuta consultas SELECT, UPDATE, INSERT, DELETE,
            CREATE TABLE, CREATE VIEW, CREATE OR ALTER VIEW, ALTER TABLE
            o WITH (CTE) directamente contra tu base SQL Server.
          </p>
          <p class="pc-small-muted">
            Correo actual: {@current_user_email} <br />
            URL actual: {@current_path}
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
                Se permiten SELECT, UPDATE, INSERT, DELETE,
                CREATE TABLE, CREATE VIEW, CREATE OR ALTER VIEW, ALTER TABLE y WITH (CTE).
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
    """
  end

  ## Helpers

  defp allowed_sql?(sql) do
    up =
      sql
      |> String.trim_leading()
      |> drop_leading_semicolons()
      |> String.upcase()

    cond do
      String.starts_with?(up, "SELECT") -> true
      String.starts_with?(up, "UPDATE") -> true
      String.starts_with?(up, "INSERT") -> true
      String.starts_with?(up, "DELETE") -> true
      String.starts_with?(up, "CREATE TABLE") -> true
      String.starts_with?(up, "CREATE OR ALTER VIEW") -> true
      String.starts_with?(up, "CREATE VIEW") -> true
      String.starts_with?(up, "ALTER TABLE") -> true
      String.starts_with?(up, "WITH") -> true
      true -> false
    end
  end

  defp drop_leading_semicolons(str), do: do_drop_semis(str)
  defp do_drop_semis(<<";", rest::binary>>), do: do_drop_semis(rest)
  defp do_drop_semis(str), do: str

  defp norm(v) when is_binary(v),
    do: :unicode.characters_to_binary(v, :latin1, :utf8)

  defp norm({{y, m, d}, {hh, mm, ss, ms}}),
    do:
      NaiveDateTime.new!(y, m, d, hh, mm, ss, {ms, 3})
      |> NaiveDateTime.to_iso8601()

  defp norm({{y, m, d}, {hh, mm, ss}}),
    do:
      NaiveDateTime.new!(y, m, d, hh, mm, ss, 0)
      |> NaiveDateTime.to_iso8601()

  defp norm({y, m, d}),
    do: Date.new!(y, m, d) |> Date.to_iso8601()

  defp norm(%Decimal{} = d),
    do: Decimal.to_string(d)

  defp norm(nil), do: ""
  defp norm(v), do: v
end
