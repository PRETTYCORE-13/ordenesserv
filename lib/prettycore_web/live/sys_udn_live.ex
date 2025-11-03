defmodule PrettycoreWeb.SysUdnLive do
  use PrettycoreWeb, :live_view
  alias Prettycore.SysUdn

  @per_page 20

  def mount(_params, _session, socket) do
    rows = SysUdn.listar_todo()
    headers = if rows == [], do: [], else: rows |> hd() |> Map.keys() |> Enum.reject(&(&1 in [:__meta__, :__struct__]))

    {:ok,
     socket
     |> assign(rows: rows, headers: headers)
     |> assign(q: "", page: 1, per: @per_page, sort_by: nil, sort_dir: :asc)}
  end

  # buscar
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, q: q, page: 1)}
  end

  # ordenar
  def handle_event("sort", %{"col" => col}, %{assigns: a} = socket) do
    dir =
      case {a.sort_by, a.sort_dir} do
        {^col, :asc} -> :desc
        {^col, :desc} -> :asc
        _ -> :asc
      end

    {:noreply, assign(socket, sort_by: col, sort_dir: dir)}
  end

  # paginar
  def handle_event("page", %{"to" => to}, socket) do
    page = String.to_integer(to)
    {:noreply, assign(socket, page: max(1, page))}
  end

  # ============ helpers ============

  defp apply_filters(rows, q, sort_by, sort_dir) do
    rows
    |> maybe_filter(q)
    |> maybe_sort(sort_by, sort_dir)
  end

  defp maybe_filter(rows, ""), do: rows

  defp maybe_filter(rows, q) do
    ql = String.downcase(q)

    Enum.filter(rows, fn m ->
      Enum.any?(m, fn {_k, v} ->
        v && String.contains?(String.downcase(to_str(v)), ql)
      end)
    end)
  end

  defp maybe_sort(rows, nil, _), do: rows

  defp maybe_sort(rows, col, dir) do
    sorter = if dir == :asc, do: &<=/2, else: &>=/2

    Enum.sort_by(
      rows,
      fn m -> to_sort_val(Map.get(m, col)) end,
      sorter
    )
  end

  defp to_sort_val(%Date{} = d), do: d
  defp to_sort_val(%NaiveDateTime{} = d), do: d
  defp to_sort_val(v) when is_number(v), do: v
  defp to_sort_val(v), do: String.downcase(to_str(v))

  defp to_str(%Decimal{} = d), do: Decimal.to_string(d)
  defp to_str(%NaiveDateTime{} = d), do: NaiveDateTime.to_iso8601(d)
  defp to_str(%Date{} = d), do: Date.to_iso8601(d)
  defp to_str(v) when is_binary(v), do: v
  defp to_str(v) when is_nil(v), do: ""
  defp to_str(v) when is_integer(v), do: Integer.to_string(v)
  defp to_str(v) when is_float(v), do: Float.to_string(v)
  defp to_str(v) when is_atom(v), do: Atom.to_string(v)
  defp to_str(%_{} = _struct), do: "[struct]"
  defp to_str(v), do: inspect(v)

  # ============ render ============

  def render(assigns) do
    ~H"""
    <div class="pc-wrap">
      <div class="pc-toolbar">
        <input
          type="text"
          name="q"
          value={@q}
          phx-debounce="250"
          phx-change="search"
          class="pc-input"
          placeholder="Buscar en SYS_UDN"
        /> <.link navigate="/api/sys_udn" class="pc-btn">JSON</.link>
      </div>
      <% filtered = apply_filters(@rows, @q, @sort_by, @sort_dir) %> <% total_pages =
        max(1, div(length(filtered) + @per - 1, @per)) %> <% page = min(@page, total_pages) %> <% start =
        (page - 1) * @per %> <% page_rows = filtered |> Enum.drop(start) |> Enum.take(@per) %>
      <div class="pc-table-wrap">
        <table class="pc-table">
          <thead>
            <tr>
              <%= for h <- @headers do %>
                <th>
                  <button phx-click="sort" phx-value-col={h}>
                    <span>{h}</span>
                    <%= if @sort_by == h do %>
                      <span>{if @sort_dir == :asc, do: "▲", else: "▼"}</span>
                    <% end %>
                  </button>
                </th>
              <% end %>
            </tr>
          </thead>

          <tbody>
            <%= for row <- page_rows do %>
              <tr>
                <%= for h <- @headers do %>
                  <td>{to_str(Map.get(row, h))}</td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>

      <div class="pc-pager">
        <button class="pc-btn" phx-click="page" phx-value-to={page - 1} disabled={page <= 1}>
          «
        </button>
         <span>Página {page} / {total_pages}</span>
        <button class="pc-btn" phx-click="page" phx-value-to={page + 1} disabled={page >= total_pages}>
          »
        </button>
      </div>
    </div>
    """
  end
end
