defmodule Prettycore.SysUdn do
  @moduledoc false
  alias Prettycore.TdsClient

  @sql_all "SELECT * FROM [dbo].[XEN_WOKORDERENC]"

  # Convierte valores para JSON
  defp norm(v) when is_binary(v), do: :unicode.characters_to_binary(v, :latin1, :utf8)

  defp norm({{y, m, d}, {hh, mm, ss, ms}}),
    do: NaiveDateTime.new!(y, m, d, hh, mm, ss, {ms, 3}) |> NaiveDateTime.to_iso8601()

  defp norm({{y, m, d}, {hh, mm, ss}}),
    do: NaiveDateTime.new!(y, m, d, hh, mm, ss, 0) |> NaiveDateTime.to_iso8601()

  defp norm({y, m, d}), do: Date.new!(y, m, d) |> Date.to_iso8601()
  defp norm(%Decimal{} = d), do: Decimal.to_string(d)
  defp norm(v), do: v

  def listar_todo do
    Prettycore.Repo.all(Prettycore.WorkOrder)
  end

  def listar_todo2 do
    {:ok, %Tds.Result{columns: cols, rows: rows}} = TdsClient.query(@sql_all, [])

    Enum.map(rows, fn row ->
      cols |> Enum.zip(row) |> Map.new(fn {k, v} -> {k, norm(v)} end)
    end)
  end
end
