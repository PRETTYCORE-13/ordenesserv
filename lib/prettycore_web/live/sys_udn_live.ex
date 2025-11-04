defmodule PrettycoreWeb.SysUdnLive do
  use PrettycoreWeb, :live_view
  alias Prettycore.SysUdn

  @per_page 20

  def mount(_params, _session, socket) do
    rows = SysUdn.listar_todo()

    headers =
      if rows == [],
        do: [],
        else: rows |> hd() |> Map.keys() |> Enum.reject(&(&1 in [:__meta__, :__struct__]))

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

  #boton
    def handle_event("btn-acept", %{"value" => to}, socket) do
    {:noreply, socket}
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
end
